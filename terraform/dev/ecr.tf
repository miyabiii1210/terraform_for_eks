resource "aws_ecr_repository" "dev-frontend-ecr" {
  name                 = "${local.sig}-frontend"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
      scan_on_push = true
  }
  tags = local.default_tags
}

resource "aws_ecr_repository" "dev-backend-ecr" {
  name                 = "${local.sig}-backend"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
      scan_on_push = true
  }
  tags = local.default_tags
}