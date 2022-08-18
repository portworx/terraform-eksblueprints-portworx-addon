# Portworx add-on for EKS Blueprints

## Introduction

[Portworx](https://portworx.com/) is a Kubernetes data-services platform designed to provide persistent storage, data protection, disaster recovery, and other capabilities for containerized applications. This blueprint installs Portworx on Amazon Elastic Kubernetes Service environment  (AWS EKS).

- [Helm chart](https://github.com/portworx/helm)

## Examples Blueprint

To get started look at these samples [blueprints](blueprints/).

## Requirements

For the add-on to work, Portworx need additional permission to AWS resources which can be provided through the following two ways (Also covered in Sample Blueprints) :- 

### Method1: Custom IAM policy

1. Add this code block in your terraform script to create the policy with the required permissions. Keep a note of the resource name for policy you created

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
3. Attach the newly created AWS policy ARN to the node groups in your cluster 

```
 managed_node_groups = {
    node_group_1 = {
      node_group_name           = "my_node_group_1"
      instance_types            = ["t2.small"]
      min_size                  = 1
      max_size                  = 2
      subnet_ids                = module.vpc.private_subnets

      #Add this line to the code block or add the new policy ARN to the list if it already exist
      additional_iam_policies   = [aws_iam_policy.<policy-resource-name>.arn]

    }
  }
```
4 .Run the command below to apply the changes. (This step can be performed even if the cluster is up and running. The policy attachment can happens without restarting the nodes)
```bash
terraform apply -target="module.eks_blueprints"
```

### Method 2: AWS Security Credentials

Create a User with the same policy and provide the security credentials AWS access key ID and secret access key to Portworx.
 

Pass the key pair to Portworx by setting these two Environment variable.

```
export TF_VAR_aws_access_key_id=<access-key-id-value>
export TF_VAR_aws_secret_access_key=<access-key-secret>
```

To use Portworx addon with this method, along with ```enable_portworx``` variable, have these two additional variables in ```eks_blueprints_kuberenetes_addons``` module block

```
  enable_portworx                     = true
  portworx_aws_access_key_id          = var.aws_access_key_id
  portworx_aws_secret_access_key      = var.aws_secret_access_key

```

Terraform will automatically populate the variable ```aws_access_key_id``` and ```aws_secret_access_key``` from the environment variables.

Alternatively one can also provide the value of key pair directly to these variables.

## Usage

After completing the requirement step, installing Portworx is as simple as setting ```enable_portworx``` variable to true inside Kubernetes Addon module

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

To customise Portworx installation pass the configurations as object like below

```
  enable_portworx         = true
  portworx_chart_values   ={ 
    clusterName="testCluster"
    imageVersion="2.11.1"
  } 
}
```

<!--- BEGIN_TF_DOCS --->


## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.26.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.12.1 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.6.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_helm_addon"></a> [helm\_addon](#module\_helm\_addon) | github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons/helm-addon | v4.7.0 |

## Resources
| Name | Type | Required |
|------|------|----------|
| [aws_iam_policy.portworx_eksblueprint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy)| resource | no|

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_addon_context"></a> [addon\_context](#input\_addon\_context) | Input configuration for the addon | <pre>object({<br>    aws_caller_identity_account_id = string<br>    aws_caller_identity_arn        = string<br>    aws_eks_cluster_endpoint       = string<br>    aws_partition_id               = string<br>    aws_region_name                = string<br>    eks_cluster_id                 = string<br>    eks_oidc_issuer_url            = string<br>    eks_oidc_provider_arn          = string<br>    tags                           = map(string)<br>  })</pre> | n/a | yes |
| <a name="input_chart_values"></a> [chart\_values](#input\_chart\_values) | Custom values for the Portworx Helm chart | `any` | `{}` | no |
| <a name="input_aws_access_key_id"></a> [aws\_access\_key\_id](#input\_aws\_access\_key\_id) | AWS access key id value (Not required if using IAM policy to give access. Required otherwise. )| `string` | `` | no |
| <a name="input_aws_secret_access_key"></a> [aws\_secret\_access\_key](#input\_aws\_secret\_access\_key) | AWS secret access key value (Not required if using IAM policy to give access)| `string` | `` | no |
| <a name="input_helm_config"></a> [helm\_config](#input\_helm\_config) | Helm provider config for the Portworx | `any` | `{}` | no |
| <a name="input_set_values"></a> [set\_values](#input\_set\_values) | Forced set values for Portworx Helm chart | `any` | `[]` | no |
| <a name="input_set_sensitive_values"></a> [set\_sensitive\_values](#input\_set\_sensitive\_values) | Forced set sensitive values for Portworx Helm chart | `any` | `[]` | no |
| <a name="input_irsa_permissions_boundary"></a> [irsa\_permissions\_boundary](#input\_irsa\_permissions\_boundary) | IAM Policy ARN for IRSA IAM role permissions boundary | `string` | `""` | no |
| <a name="input_irsa_policies"></a> [irsa\_policies](#input\_irsa\_policies) | IAM policy ARNs for Portworx IRSA | `list(string)` | `[]` | no |
| <a name="input_manage_via_gitops"></a> [manage\_via\_gitops](#input\_manage\_via\_gitops) | Determines if the add-on should be managed via GitOps. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_argocd_gitops_config"></a> [argocd\_gitops\_config](#output\_argocd\_gitops\_config) | Configuration used for managing the add-on with ArgoCD |
<!--- END_TF_DOCS --->