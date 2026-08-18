terraform {
  required_providers {
    vault = {
      source = "hashicorp/vault"

      # Needed for https://github.com/hashicorp/terraform-provider-vault/pull/1479
      version = ">= 3.7.0"
    }

    tfe = {
      source = "hashicorp/tfe"

      # >= 0.40.0 for dynamic credentials support
      # >= 0.59.0 for tfe_workspace data source (replaces deprecated tfe_workspace_ids)
      version = ">= 0.59.0"
    }
  }
}

// TODO: to make this easier... split TFC Vars and Vault Roles into separate submodules
// (this should make the "if VAR, then CREATE" logic easier to manage)



# TODO: Use the create/find pattern we've established here:
# https://github.com/hashi-strawb/terraform-aws-tfc-dynamic-creds-provider/blob/main/main.tf

# TODO: optionally separate plan and apply roles

#
# Vault
#

resource "vault_jwt_auth_backend" "tfc" {
  count = var.vault.create_roles ? 1 : 0

  description        = var.vault.auth_description
  path               = var.vault.auth_path
  oidc_discovery_url = var.vault.auth_oidc_discovery_url
  bound_issuer       = var.vault.auth_bound_issuer
}

resource "vault_jwt_auth_backend_role" "tfc_workspaces" {
  for_each = var.vault.create_roles ? {
    for r in var.roles :
    "${var.terraform.org}_${r.workspace_name}" => r
  } : {}

  depends_on = [
    vault_jwt_auth_backend.tfc
  ]

  backend = var.vault.auth_path

  role_name      = each.key
  token_policies = each.value.token_policies

  bound_audiences   = each.value.bound_audiences
  bound_claims_type = each.value.bound_claims_type


  bound_claims = {
    "sub" = join(":", [
      "organization:${var.terraform.org}",
      "project:${each.value.project_name}",
      "workspace:${each.value.workspace_name}",
      "run_phase:*",
    ])
  }
  user_claim = each.value.user_claim
  role_type  = each.value.role_type
  token_ttl  = each.value.token_ttl
}



#
# TFC
#

data "tfe_workspace" "all" {
  for_each = toset(
    var.terraform.create_variables ? [for r in var.roles : r.workspace_name] : []
  )

  name         = each.key
  organization = var.terraform.org
}

resource "tfe_variable" "tfc_workspace_vault_provider_auth" {
  for_each = toset(
    var.terraform.create_variables ? ([for r in var.roles : r.workspace_name]) : []
  )

  key          = "TFC_VAULT_PROVIDER_AUTH${local.alias_suffix}"
  value        = true
  category     = "env"
  workspace_id = data.tfe_workspace.all[each.key].id

  description = "Use TFC Dynamic Credentials to authenticate with Vault${local.alias_description_suffix}"
}

resource "tfe_variable" "tfc_workspace_tfc_vault_addr" {
  for_each = toset(
    var.terraform.create_variables ? ([for r in var.roles : r.workspace_name]) : []
  )

  key          = "TFC_VAULT_ADDR${local.alias_suffix}"
  value        = var.vault.addr
  category     = "env"
  workspace_id = data.tfe_workspace.all[each.key].id

  description = "Vault Address for TFC to use when authenticating with Vault${local.alias_description_suffix}"
}
resource "tfe_variable" "tfc_workspace_tfc_vault_namespace" {
  for_each = toset(
    var.terraform.create_variables ? (
      var.vault.namespace != null ?
      [for r in var.roles : r.workspace_name] : []
    ) : []
  )

  key          = "TFC_VAULT_NAMESPACE${local.alias_suffix}"
  value        = var.vault.namespace
  category     = "env"
  workspace_id = data.tfe_workspace.all[each.key].id

  description = "Vault Namespace for TFC to use when authenticating with Vault${local.alias_description_suffix}"
}

resource "tfe_variable" "tfc_workspace_vault_run_role" {
  for_each = toset(
    var.terraform.create_variables ? [for r in var.roles : r.workspace_name] : []
  )

  key          = "TFC_VAULT_RUN_ROLE${local.alias_suffix}"
  value        = "${var.terraform.org}_${each.key}"
  category     = "env"
  workspace_id = data.tfe_workspace.all[each.key].id

  description = "Role to use in the Vault auth method${local.alias_description_suffix}"
}

resource "tfe_variable" "tfc_workspace_vault_auth_path" {
  for_each = toset(
    var.terraform.create_variables ? [for r in var.roles : r.workspace_name] : []
  )

  key          = "TFC_VAULT_AUTH_PATH${local.alias_suffix}"
  value        = var.vault.auth_path
  category     = "env"
  workspace_id = data.tfe_workspace.all[each.key].id

  description = "Path to use for the Vault auth method${local.alias_description_suffix}"
}

