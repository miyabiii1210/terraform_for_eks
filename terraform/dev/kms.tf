# KMS
resource "aws_kms_alias" "dev" {
  name          = "alias/${local.sig}-key"
  target_key_id = aws_kms_key.dev.key_id
}

resource "aws_kms_key" "dev" {
  customer_master_key_spec = "ECC_SECG_P256K1"
  is_enabled               = true
  enable_key_rotation      = false
  key_usage                = "SIGN_VERIFY"
  multi_region             = false
  policy = jsonencode(
    {
        Id        = "key-consolepolicy-3"
        Statement = [
            {
                Action    = "kms:*"
                Effect    = "Allow"
                Principal = {
                    AWS = "arn:aws:iam::XXXXXXXXXXX:root"
                }
                Resource  = "*"
                Sid       = "Enable IAM User Permissions"
            },
            {
                Action    = [
                    "kms:Create*",
                    "kms:Describe*",
                    "kms:Enable*",
                    "kms:List*",
                    "kms:Put*",
                    "kms:Update*",
                    "kms:Revoke*",
                    "kms:Disable*",
                    "kms:Get*",
                    "kms:Delete*",
                    "kms:TagResource",
                    "kms:UntagResource",
                    "kms:ScheduleKeyDeletion",
                    "kms:CancelKeyDeletion",
                ]
                Effect    = "Allow"
                Principal = {
                    AWS = "arn:aws:iam::XXXXXXXXXXX:user/iam-user"
                }
                Resource  = "*"
                Sid       = "Allow access for Key Administrators"
            },
            {
                Action    = [
                    "kms:DescribeKey",
                    "kms:GetPublicKey",
                    "kms:Sign",
                    "kms:Verify",
                ]
                Effect    = "Allow"
                Principal = {
                    AWS = "arn:aws:iam::XXXXXXXXXXX:user/iam-user"
                }
                Resource  = "*"
                Sid       = "Allow use of the key"
            },
            {
                Action    = [
                    "kms:CreateGrant",
                    "kms:ListGrants",
                    "kms:RevokeGrant",
                ]
                Condition = {
                    Bool = {
                        "kms:GrantIsForAWSResource" = "true"
                    }
                }
                Effect    = "Allow"
                Principal = {
                    AWS = "arn:aws:iam::XXXXXXXXXXX:user/iam-user"
                }
                Resource  = "*"
                Sid       = "Allow attachment of persistent resources"
            },
        ]
        Version   = "2012-10-17"
    }
  )
  tags = local.default_tags
}
