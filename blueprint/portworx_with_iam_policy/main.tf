provider "aws" {
  region = local.region
}

locals {
  name         = "pallav-1"
  cluster_name = coalesce(var.cluster_name, local.name)
  region       = "us-east-1"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Blueprint  = local.name
    expiresOn = 13-10-2023
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", local.region]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", local.region]
    }
  }
}

data "aws_availability_zones" "available" {}

#---------------------------------------------------------------
# Supporting Resources
#---------------------------------------------------------------

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}

#---------------------------------------------------------------
# Custom IAM roles for Node Groups
#---------------------------------------------------------------

resource "random_string" "id" {
  length  = 4
  special = false
  upper   = false
}

resource "aws_iam_policy" "portworx_eksblueprint_volume_access" {
  name = "portworx_eksblueprint_volumeAccess-${random_string.id.result}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:AttachVolume",
          "ec2:ModifyVolume",
          "ec2:DetachVolume",
          "ec2:CreateTags",
          "ec2:CreateVolume",
          "ec2:DeleteTags",
          "ec2:DeleteVolume",
          "ec2:DescribeTags",
          "ec2:DescribeVolumeAttribute",
          "ec2:DescribeVolumesModifications",
          "ec2:DescribeVolumeStatus",
          "ec2:DescribeVolumes",
          "ec2:DescribeInstances",
          "autoscaling:DescribeAutoScalingGroups"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}


#---------------------------------------------------------------
# EKS Blueprints
#---------------------------------------------------------------

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.13"

  cluster_name    = local.name
  cluster_version = "1.27"

  # EKS Addons
  cluster_addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni    = {}
  }
  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true
  eks_managed_node_groups = {
    initial = {
      instance_types = ["t2.medium"]
      min_size       = 3
      max_size       = 3
      desired_size   = 3

      iam_role_additional_policies = {
        additional = aws_iam_policy.portworx_eksblueprint_volume_access.arn
      }
    }
  }
  
  tags = local.tags
}

#---------------------------------------------------------------
# EKS Blueprints Kubernetes Addons
#---------------------------------------------------------------

module "eks_blueprints_kubernetes_addons" {
  source = "github.com/portworx/terraform-aws-eks-blueprints?ref=v4/modules/kubernetes-addons"

  eks_cluster_id       = module.eks.cluster_name
  eks_cluster_endpoint = module.eks.cluster_endpoint
  eks_oidc_provider    = module.eks.oidc_provider
  eks_cluster_version  = module.eks.cluster_version

  # Wait on the node group(s) before provisioning addons
  data_plane_wait_arn = join(",", [for group in module.eks.eks_managed_node_groups : group.node_group_arn])

  enable_portworx = true
  portworx_helm_config = {
    set = [
      {
        name  = "aws.marketplace"
        value = "true"
      },
      {
        name  = "namespace"
        value = "portworx"
      },
      {
        name = "createNamespace"
        value = true
      }
    ]
  }

  tags = local.tags
}
