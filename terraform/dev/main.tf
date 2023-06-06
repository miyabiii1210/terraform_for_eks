locals {
  project = "hoge"
  env     = "dev"
  sig     = "${local.project}-${local.env}"

  default_tags = {
    project    = "${local.project}"
    env        = "${local.env}"
    managed-by = "terraform"
  }
}