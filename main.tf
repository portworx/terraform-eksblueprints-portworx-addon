module "helm_addon" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons/helm-addon?ref=v4.32.0"

  addon_context = var.addon_context
  helm_config   = local.helm_config
  irsa_config   = local.irsa_config
}
