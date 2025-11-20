# 1. Create the Registry
resource "aws_ecr_repository" "app_repo" {
  name                 = "sentry-app-repo"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

output "ecr_repo_url" {
  value = aws_ecr_repository.app_repo.repository_url
}

# 2. Trust GitHub Actions (OIDC)
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d9c60c1c11060974993c2000b5251666B"]
}

# 3. Create the Role for GitHub
resource "aws_iam_role" "github_actions" {
  name = "github-actions-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Condition = {
        StringLike = {
          "token.actions.githubusercontent.com:sub": "repo:pchp485/aws_multi_region_practice:*"
        }
      }
    }]
  })
}

# 4. Give the Role permission to push images
resource "aws_iam_role_policy" "github_ecr_policy" {
  name = "github-ecr-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = ["ecr:GetAuthorizationToken", "ecr:BatchCheckLayerAvailability", "ecr:CompleteLayerUpload", "ecr:UploadLayerPart", "ecr:InitiateLayerUpload", "ecr:PutImage"]
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}

output "github_role_arn" {
  value = aws_iam_role.github_actions.arn
}