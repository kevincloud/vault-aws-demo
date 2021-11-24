terraform {
  required_providers {
    tfe = {
      source = "hashicorp/tfe"
      version = "0.26.1"
    }
  }
}

provider "tfe" {
}

data "tfe_organization" "org" {
  name = "YOUR_TFE/TFC_ORG"
}

data "tfe_workspace" "ws" {
  name         = "YOUR_TFE/TFC_WORKSPACE"
  organization = "YOUR_TFE/TFC_ORG"
}

resource "tfe_variable" "aws_region" {
  key          = "aws_region"
  value        = "VALUE"
  category     = "terraform"
  workspace_id = data.tfe_workspace.ws.id
}

resource "tfe_variable" "key_pair" {
  key          = "key_pair"
  value        = "VALUE"
  category     = "terraform"
  workspace_id = data.tfe_workspace.ws.id
}

resource "tfe_variable" "kms_key_id" {
  key          = "kms_key_id"
  value        = "VALUE"
  category     = "terraform"
  workspace_id = data.tfe_workspace.ws.id
}

resource "tfe_variable" "vault_license" {
  key          = "vault_license"
  value        = "VALUE"
  category     = "terraform"
  sensitive    = true
  workspace_id = data.tfe_workspace.ws.id
}

resource "tfe_variable" "owner" {
  key          = "owner"
  value        = "VALUE"
  category     = "terraform"
  workspace_id = data.tfe_workspace.ws.id
}

resource "tfe_variable" "se_region" {
  key          = "se_region"
  value        = "VALUE"
  category     = "terraform"
  workspace_id = data.tfe_workspace.ws.id
}

resource "tfe_variable" "prefix" {
  key          = "prefix"
  value        = "VALUE"
  category     = "terraform"
  workspace_id = data.tfe_workspace.ws.id
}

resource "tfe_variable" "ttl" {
  key          = "ttl"
  value        = "VALUE"
  category     = "terraform"
  workspace_id = data.tfe_workspace.ws.id
}

resource "tfe_variable" "db_pass" {
  key          = "db_pass"
  value        = "VALUE"
  category     = "terraform"
  sensitive    = true
  workspace_id = data.tfe_workspace.ws.id
}
