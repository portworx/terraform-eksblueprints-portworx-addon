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
  
  portworx_chart_values ={ 
    awsAccessKeyId = var.aws_access_key_id
    awsSecretAccessKey = var.aws_secret_access_key
    
    # other custom values for Portworx configuration
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
  enable_portworx                     = true
}
```

To customize Portworx installation, pass the configuration parameter as an object as shown below:

```
  enable_portworx         = true
  portworx_chart_values   ={ 
    clusterName="testCluster"
    imageVersion="2.11.1"
  } 
}
```

<!--- BEGIN_TF_DOCS --->


## Terraform providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.26.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.12.1 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.6.0 |

## Terraform modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_helm_addon"></a> [helm\_addon](#module\_helm\_addon) | github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons/helm-addon | v4.7.0 |

## Resources
| Name | Type | Required |
|------|------|----------|
| [aws_iam_policy.portworx_eksblueprint_volumeAccess](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy)| resource | yes  if not using AWS credentials |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_addon_context"></a> [addon\_context](#input\_addon\_context) | Input configuration for the addon | <pre>object({<br>    aws_caller_identity_account_id = string<br>    aws_caller_identity_arn        = string<br>    aws_eks_cluster_endpoint       = string<br>    aws_partition_id               = string<br>    aws_region_name                = string<br>    eks_cluster_id                 = string<br>    eks_oidc_issuer_url            = string<br>    eks_oidc_provider_arn          = string<br>    tags                           = map(string)<br>  })</pre> | n/a | yes |
| <a name="input_chart_values"></a> [chart\_values](#input\_chart\_values) | Custom values for the Portworx Helm chart | `any` | `{}` | no |
| <a name="input_helm_config"></a> [helm\_config](#input\_helm\_config) | Helm provider config for the Portworx | `any` | `{}` | no |
| <a name="input_set_values"></a> [set\_values](#input\_set\_values) | Forced set values for Portworx Helm chart | `any` | `[]` | no |
| <a name="input_set_sensitive_values"></a> [set\_sensitive\_values](#input\_set\_sensitive\_values) | Forced set sensitive values for Portworx Helm chart | `any` | `[]` | no |
| <a name="input_irsa_permissions_boundary"></a> [irsa\_permissions\_boundary](#input\_irsa\_permissions\_boundary) | IAM Policy ARN for IRSA IAM role permissions boundary | `string` | `""` | no |
| <a name="input_irsa_policies"></a> [irsa\_policies](#input\_irsa\_policies) | IAM policy ARNs for Portworx IRSA | `list(string)` | `[]` | no |
| <a name="input_manage_via_gitops"></a> [manage\_via\_gitops](#input\_manage\_via\_gitops) | Determines if the add-on should be managed via GitOps. | `bool` | `false` | no |

<!-- ## Outputs

| Name | Description |
|------|-------------|
| <a name="output_argocd_gitops_config"></a> [argocd\_gitops\_config](#output\_argocd\_gitops\_config) | Configuration used for managing the add-on with ArgoCD | -->

<!--- END_TF_DOCS --->