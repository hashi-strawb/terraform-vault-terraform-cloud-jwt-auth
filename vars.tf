
variable "tfc_org" {
  type    = string
  default = "lmhd"
}

variable "tfc_roles" {
  type = list(object({
    workspace_name = string
    project_name   = optional(string, "*") # Default to whatever project
    token_policies = list(string)

    role_name = optional(string) # TODO: if not set, calculate from workspace and projec tname

    bound_audiences   = optional(list(string), ["vault.workload.identity"])
    bound_claims_type = optional(string, "glob")
    user_claim        = optional(string, "terraform_full_workspace")
    role_type         = optional(string, "jwt")

    token_ttl = optional(number, 5 * 60)
  }))

  default = []
}
