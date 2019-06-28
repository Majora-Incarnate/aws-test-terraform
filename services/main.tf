terraform {
  required_version = ">= 0.12.0"
}

provider "aws" {
  version = "~> 2.7.0"
  region  = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

provider "local" {}

# Use this to standardize any sort of metadata across modules/resources
locals {
  tags = {
    Owner = "Trevin Teacutter"
    Terraform = "true"
    Environment = var.environment
    Tenant = var.tenant
  }
}

data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
    bucket     = var.aws_s3_bucket
    key        = "eks/terraform.tfstate"
    region     = var.aws_region
    encrypt    = true
  }
}

data "terraform_remote_state" "elasticsearch" {
  backend = "s3"

  config = {
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
    bucket     = var.aws_s3_bucket
    key        = "elasticsearch/terraform.tfstate"
    region     = var.aws_region
    encrypt    = true
  }
}

data "terraform_remote_state" "infra" {
  backend = "s3"

  config = {
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
    bucket     = var.aws_s3_bucket
    key        = "infra/terraform.tfstate"
    region     = var.aws_region
    encrypt    = true
  }
}

provider "kubernetes" {
  version = "~> 1.7.0"
  load_config_file = true
  config_path      = "./kubeconfig.yaml"
  config_context   = "eks_${data.terraform_remote_state.eks.outputs.cluster_id}"
}

provider "helm" {
  version = "~> 0.9.0"
  kubernetes {
    load_config_file = true
    config_path      = "./kubeconfig.yaml"
    config_context   = "eks_${data.terraform_remote_state.eks.outputs.cluster_id}"
  }

  namespace = "tiller"
  service_account = "tiller"
  install_tiller = "true"
}

data "helm_repository" "incubator" {
    name = "incubator"
    url  = "https://kubernetes-charts-incubator.storage.googleapis.com"
}

resource "null_resource" "write_kube_config" {
provisioner "local-exec" {
command = "echo '${data.terraform_remote_state.eks.outputs.kubeconfig}' > ./kubeconfig.yaml"
}
}

resource "kubernetes_namespace" "tiller" {
  metadata {
    name = "tiller"
    labels = {
      name = "tiller"
    }
  }
}

resource "kubernetes_service_account" "tiller_service_account" {
  metadata {
    name = "tiller"
    namespace = "tiller"
  }

  depends_on = [kubernetes_namespace.tiller]
}

resource "kubernetes_cluster_role_binding" "tiller_cluster_role_binding" {
  metadata {
    name = "tiller-cluster-admin"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "ClusterRole"
    name = "cluster-admin"
  }
  subject {
    kind = "ServiceAccount"
    name = "tiller"
    namespace = "tiller"
  }
  
  depends_on = [kubernetes_service_account.tiller_service_account]
}

# Kubernetes provider doesn't handle ZDD but ideally I wouldn't be managing things deployed onto Kube with terraform anyway
resource "kubernetes_deployment" "webserver" {
  metadata {
    name = "webserver"
    namespace  = "default"
    labels = {
      app = "webserver"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "webserver"
      }
    }

    template {
      metadata {
        labels = {
          app = "webserver"
        }
      }

      spec {
        container {
          image = "nginx:1.17"
          name  = "webserver"

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "webserver" {
  metadata {
    name = "webserver"
    namespace  = "default"
  }
  spec {
    selector = {
      app = "webserver"
    }
    port {
      port = 8080
      target_port = 80
    }

    type = "NodePort"
  }
}

resource "kubernetes_ingress" "webserver" {
  metadata {
    name = "webserver"
    namespace  = "default"
    annotations = {
      "kubernetes.io/ingress.class" = "alb"
      "alb.ingress.kubernetes.io/subnets" = join(",", data.terraform_remote_state.infra.outputs.public_subnet_ids)
      "alb.ingress.kubernetes.io/scheme" = "internet-facing"
      "alb.ingress.kubernetes.io/tags" = "Environment=${var.environment},Tenant=${var.tenant}"
    }
  }

  spec {
    rule {
      host = "webserver.example.com"
      http {
        path {
          backend {
            service_name = "webserver"
            service_port = 8080
          }

          path = "/"
        }
      }
    }
  }
}

data "local_file" "fluentd_output_conf" {
    filename = "${path.module}/files/fluentd-values.yaml"
}


resource "helm_release" "fluentd_elasticsearch" {
  name = "fluentd-elasticsearch"
  chart      = "https://github.com/kiwigrid/kiwigrid.github.io/raw/master/fluentd-elasticsearch-4.2.0.tgz"
  namespace  = "default"
  values     = ["${data.local_file.fluentd_output_conf.content}"]

  set {
    name  = "elasticsearch.host"
    value = data.terraform_remote_state.elasticsearch.outputs.elasticsearch_endpoint
  }
  
  set {
    name = "elasticsearch.scheme"
    value = "https"
  }
  
  set {
    name = "elasticsearch.port"
    value = "443"
  }

  set {
    name = "awsSigningSidecar.enabled"
    value = "true"
  }

  set {
    name = "configMaps.useDefaults.outputConf"
    value = "false"
  }
}

resource "helm_release" "aws_alb_ingress_controller" {
  name       = "aws-alb-ingress-controller"
  repository = "incubator"
  chart      = "incubator/aws-alb-ingress-controller"
  version    = "0.1.9"
  namespace  = "kube-system"

  set {
    name  = "autoDiscoverAwsRegion"
    value = "true"
  }

  set {
    name  = "autoDiscoverAwsVpcID"
    value = "true"
  }

  set {
    name  = "clusterName"
    value = data.terraform_remote_state.eks.outputs.cluster_id
  }
  
  depends_on = [kubernetes_service_account.tiller_service_account]
}

data "aws_iam_policy_document" "aws_alb_ingress_controller" {
  statement {
    sid    = "awsAlbIngressAllowReadCertificates"
    effect = "Allow"
    actions = [
      "acm:DescribeCertificate",
      "acm:ListCertificates",
      "acm:GetCertificate",
    ]
    resources = [
      "*",
    ]
  }

  statement {
    sid    = "awsAlbIngressAllowEC2"
    effect = "Allow"
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateSecurityGroup",
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "ec2:DeleteSecurityGroup",
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVpcs",
      "ec2:ModifyInstanceAttribute",
      "ec2:ModifyNetworkInterfaceAttribute",
      "ec2:RevokeSecurityGroupIngress",
    ]
    resources = [
      "*",
    ]
  }

  statement {
    sid    = "awsAlbIngressAllowELB"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:AddListenerCertificates",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateRule",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeleteRule",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:DescribeListenerCertificates",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeSSLPolicies",
      "elasticloadbalancing:DescribeTags",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:ModifyRule",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:RemoveListenerCertificates",
      "elasticloadbalancing:RemoveTags",
      "elasticloadbalancing:SetIpAddressType",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets",
      "elasticloadbalancing:SetWebACL",
    ]
    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:CreateServiceLinkedRole",
      "iam:GetServerCertificate",
      "iam:ListServerCertificates",
    ]
    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "waf-regional:GetWebACLForResource",
      "waf-regional:GetWebACL",
      "waf-regional:AssociateWebACL",
      "waf-regional:DisassociateWebACL",
    ]
    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "tag:GetResources",
      "tag:TagResources",
    ]
    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "waf:GetWebACL",
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "aws_alb_ingress_controller" {
  name_prefix = "eks-worker-aws-alb-ingress-controller-${data.terraform_remote_state.eks.outputs.cluster_id}"
  description = "EKS worker node aws-alb-ingress-controller policy for cluster ${data.terraform_remote_state.eks.outputs.cluster_id}"
  policy      = data.aws_iam_policy_document.aws_alb_ingress_controller.json
}

resource "aws_iam_role_policy_attachment" "aws_alb_ingress_controller" {
  policy_arn = aws_iam_policy.aws_alb_ingress_controller.arn
  role       = data.terraform_remote_state.eks.outputs.worker_iam_role_name
}
