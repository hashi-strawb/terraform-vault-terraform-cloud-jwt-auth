# TODO: When we convert this into a module, use the create/find pattern we've established here:
# https://github.com/hashi-strawb/terraform-aws-tfc-dynamic-creds-provider/blob/main/main.tf


# TODO: optionally separate plan and apply roles

resource "vault_jwt_auth_backend" "tfc" {
  # TODO: VAR
  description = "JWT Auth for Terraform Cloud"
  # TODO: VAR
  path = "tfc"
  # TODO: VAR
  oidc_discovery_url = "https://app.terraform.io"
  # TODO: VAR
  bound_issuer = "https://app.terraform.io"
}

resource "vault_jwt_auth_backend_role" "tfc_workspaces" {
  for_each = { for r in var.tfc_roles : "${var.tfc_org}_${r.workspace_name}" => r }

  backend = vault_jwt_auth_backend.tfc.path

  role_name      = each.key
  token_policies = each.value.token_policies

  bound_audiences   = each.value.bound_audiences
  bound_claims_type = each.value.bound_claims_type


  bound_claims = {
    "sub" = "organization:${var.tfc_org}:project:${each.value.project_name}:workspace:${each.value.workspace_name}:run_phase:*"
  }
  user_claim = each.value.user_claim
  role_type  = each.value.role_type
  token_ttl  = each.value.token_ttl
}

data "tfe_workspace_ids" "all" {
  names        = ["*"]
  organization = var.tfc_org
}

resource "tfe_variable" "tfc_workspace_vault_provider_auth" {
  for_each     = toset([for r in var.tfc_roles : r.workspace_name])
  key          = "TFC_VAULT_PROVIDER_AUTH"
  value        = true
  category     = "env"
  workspace_id = data.tfe_workspace_ids.all.ids[each.key]
}

resource "tfe_variable" "tfc_workspace_tfc_vault_addr" {
  for_each = toset([for r in var.tfc_roles : r.workspace_name])
  key      = "TFC_VAULT_ADDR"
  # TODO: VAR
  value        = "https://vault.lmhd.me/"
  category     = "env"
  workspace_id = data.tfe_workspace_ids.all.ids[each.key]
}

resource "tfe_variable" "tfc_workspace_vault_run_role" {
  for_each     = toset([for r in var.tfc_roles : r.workspace_name])
  key          = "TFC_VAULT_RUN_ROLE"
  value        = "${var.tfc_org}_${each.key}"
  category     = "env"
  workspace_id = data.tfe_workspace_ids.all.ids[each.key]
}

resource "tfe_variable" "tfc_workspace_vault_auth_path" {
  for_each     = toset([for r in var.tfc_roles : r.workspace_name])
  key          = "TFC_VAULT_AUTH_PATH"
  value        = vault_jwt_auth_backend.tfc.path
  category     = "env"
  workspace_id = data.tfe_workspace_ids.all.ids[each.key]
}

resource "tfe_variable" "tfc_workspace_vault_addr" {
  for_each = toset([for r in var.tfc_roles : r.workspace_name])
  key      = "VAULT_ADDR"
  # TODO: VAR
  value        = "https://vault.lmhd.me/"
  category     = "env"
  workspace_id = data.tfe_workspace_ids.all.ids[each.key]
}

