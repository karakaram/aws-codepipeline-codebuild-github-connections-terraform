provider "aws" {
  region = local.region
}

locals {
  region = "us-west-2"
}

module "codepipeline" {
  source = "../../"

  prefix                  = "my"
  artifact_store_location = "codepipeline-${local.region}-123456789012" # change this to yours
  repository_id           = "<GITHUB_OWNER>/<GITHUB_REPO>" # change this to yours
  branch_name             = "main"
}
