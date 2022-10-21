# Portworx add-on for EKS Blueprints

## Introduction

[Portworx](https://portworx.com/) is a Kubernetes data services platform that provides persistent storage, data protection, disaster recovery, and other capabilities for containerized applications. This blueprint installs Portworx on Amazon Elastic Kubernetes Service (EKS) environment.

- [Helm chart](https://github.com/portworx/helm)

## Examples Blueprint

To get started look at these sample [blueprints](blueprint/).

## Requirements

For the add-on to work, Portworx needs additional permission to AWS resources which can be provided in the following two ways. The different flows are also covered in [sample blueprints](blueprint/): 

## Method 1: Custom IAM policy

1. Add the below code block in your terraform script to create a policy with the required permissions. Make a note of the resource name for the policy you created: 

```
resource "aws_iam_policy" "<policy-resource-name>" {
  name = "<policy-name>"

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
```

2. Run `terraform apply` command for the policy (replace it with your resource name):

```bash
terraform apply -target="aws_iam_policy.<policy-resource-name>"
```
3. Attach the newly created AWS policy ARN to the node groups in your cluster: 

```
 managed_node_groups = {
    node_group_1 = {
      node_group_name           = "my_node_group_1"
      instance_types            = ["t2.small"]
      min_size                  = 3
      max_size                  = 3
      subnet_ids                = module.vpc.private_subnets

      #Add this line to the code block or add the new policy ARN to the list if it already exists
      additional_iam_policies   = [aws_iam_policy.<policy-resource-name>.arn]

    }
  }
```
4. Run the command below to apply the changes. (This step can be performed even if the cluster is up and running. The policy attachment happens without having to restart the nodes)
```bash
terraform apply -target="module.eks_blueprints"
```

## Method 2: AWS Security Credentials

Create a User with the same policy and generate an AWS access key ID and AWS secret access key pair and share it with Portworx.
 
It is recommended to pass the above values to the terraform script from your environment variable and is demonstrated below:


1. Pass the key pair to Portworx by setting these two environment variables.

```
export TF_VAR_aws_access_key_id=<access-key-id-value>
export TF_VAR_aws_secret_access_key=<access-key-secret>
```

2. To use Portworx add-on with this method, along with ```enable_portworx``` variable, pass these credentials in the following manner:

```
  enable_portworx                     = true
  
  portworx_helm_config = {
    set_sensitive = [
      {
        name  = "aws.accessKeyId"
        value = var.aws_access_key_id
      },
      {
        name  = "aws.secretAccessKey"
        value = var.aws_secret_access_key
      }
    ]
  }

```

3. Define these two variables ```aws_access_key_id``` and ```aws_secret_access_key```. Terraform then automatically populates these variables from the environment variables.


```
variable "aws_access_key_id" {
  type = string
  default = ""
}

variable "aws_secret_access_key" {
  type = string
  default = ""
}
```

Alternatively, you can also provide the value of the secret key pair directly by hardcoding the values into the script.

## Usage

After completing the requirement step, installing Portworx is simple, set ```enable_portworx``` variable to true inside the Kubernetes add-on module.

```

module "eks_blueprints_kubernetes_addons" {
 source = "github.com/pragrawal10/terraform-aws-eks-blueprints//modules/kubernetes-addons"

  eks_cluster_id       = module.eks_blueprints.eks_cluster_id
  eks_cluster_endpoint = module.eks_blueprints.eks_cluster_endpoint
  eks_oidc_provider    = module.eks_blueprints.oidc_provider
  eks_cluster_version  = module.eks_blueprints.eks_cluster_version


  #Add this line to enable Portworx      
  enable_portworx  = true
}
```

To customize Portworx installation, pass the configuration parameter as an list of objects as shown below:

```
  enable_portworx  = true
  
  portworx_helm_config = {
    set = [
      {
        name  = "clusterName"
        value = "testCluster"
      },
      {
        name  = "imageVersion"
        value = "2.11.1"
      }
    ]
  }

}
```

<!--- BEGIN_TF_DOCS --->

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.72 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.10 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.72 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_helm_addon"></a> [helm\_addon](#module\_helm\_addon) | github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons/helm-addon | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.portworx_eksblueprint_metering](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [random_string.id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_addon_context"></a> [addon\_context](#input\_addon\_context) | Input configuration for the addon | `any` | n/a | yes |
| <a name="input_helm_config"></a> [helm\_config](#input\_helm\_config) | Helm chart config. Repository and version required. See https://registry.terraform.io/providers/hashicorp/helm/latest/docs | `any` | `{}` | no |
| <a name="input_irsa_config"></a> [irsa\_config](#input\_irsa\_config) | Input configuration for IRSA module | `any` | `{}` | no |

## Outputs

No outputs.

<!--- END_TF_DOCS --->