resource "random_string" "id" {
  length = 4
  special = false
  upper   = false
}
locals {
  name                 = "portworx-${random_string.id.result}"
  namespace            = "kube-system"
  service_account_name = "${local.name}-sa-${random_string.id.result}"

  set_values = var.set_values
  set_sensitive_values = var.set_sensitive_values

  default_helm_config = {
    name                       = local.name
    description                = "A Helm chart for portworx"
    chart                      = "portworx"
    repository                 = "https://raw.githubusercontent.com/portworx/eks-blueprint-helm/main/repo/stable"
    version                    = "2.11.0"
    namespace                  = local.namespace
    values                     = local.default_helm_values
    set_values                 = []
    set_sensitive_values       = null
  }

  helm_config = merge(
    local.default_helm_config,
    var.helm_config
  )

 irsa_iam_policies_list= try(var.chart_values.useAWSMarketplace, false) ? concat([aws_iam_policy.portworx_eksblueprint_metering[0].arn], var.irsa_policies) : var.irsa_policies

  irsa_config = {
    create_kubernetes_namespace = false
    kubernetes_namespace        = local.namespace
    create_kubernetes_service_account = true  
    kubernetes_service_account        = "${local.service_account_name}"
    irsa_iam_policies = local.irsa_iam_policies_list
  }

  argocd_gitops_config = {
    enable             = false
    serviceAccountName = local.service_account_name
  }

  default_helm_values = [templatefile("${path.module}/values.yaml", merge({
        imageVersion                = "2.11.0"
        clusterName                 = local.name     
        drives                      = "type=gp2,size=200"  
        useInternalKVDB             = true
        kvdbDevice                  = "type=gp2,size=150"
        envVars                     = ""
        maxStorageNodesPerZone      = 3 
        useOpenshiftInstall         = false
        etcdEndPoint                = ""
        dataInterface               = ""
        managementInterface         = ""
        useStork                    = true
        storkVersion                = "2.11.0"
        customRegistryURL           = ""
        registrySecret              = ""
        licenseSecret               = ""
        monitoring                  = false
        enableCSI                   = false
        enableAutopilot             = false
        KVDBauthSecretName          = ""
        eksServiceAccount           = "${local.service_account_name}"
        useAWSMarketplace           = false
        awsAccessKeyId              = ""
        awsSecretAccessKey          = ""
        deleteType                  = "UninstallAndWipe"
    },var.chart_values)
  )]
}

resource "aws_iam_policy" "portworx_eksblueprint_metering" {
  count = try(var.chart_values.useAWSMarketplace, false)? 1 : 0
  name = "portworx_eksblueprint_metering-${random_string.id.result}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
          Action = [
            "aws-marketplace:MeterUsage",
            "aws-marketplace:RegisterUsage"
          ],
          Effect = "Allow",
          Resource = "*"
      },
    ]
  })
}