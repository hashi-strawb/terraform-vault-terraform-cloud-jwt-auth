# TFC JWT Auth for Vault

More docs TODO

For now, example usage...

```

module "tfc-auth" {
  source = "github.com/hashi-strawb/terraform-vault-terraform-cloud-jwt-auth"

  terraform = {
    org = "fancycorp"
  }

  vault = {
    addr             = "https://vault.fancycorp.io/"
    auth_path        = "tfc/fancycorp"
    auth_description = "JWT Auth for Terraform Cloud in fancycorp org"
  }

  roles = [
    {
      workspace_name = "tfc-jwt-test"
      token_policies = ["default"]
    }
  ]
}

```
