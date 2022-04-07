provider "aws" {
  alias  = "replica"
  region = var.replica_region
}

resource "aws_kms_key" "primary" {
  multi_region             = true
  description              = var.description
  customer_master_key_spec = var.key_spec
  is_enabled               = var.is_enabled
  enable_key_rotation      = var.rotation_enabled
  policy                   = var.primary_key_policy
  deletion_window_in_days  = var.deletion_window_in_days

  tags = merge(
    var.tags,
    {
      "Multi-Region" = "true",
      "Primary"      = "true"
    }
  )
}

# Add an alias to the primary key
resource "aws_kms_alias" "primary" {
  name          = "alias/${var.alias}"
  target_key_id = aws_kms_key.primary.key_id
}

# Create the replica key using the primary's arn.
resource "aws_kms_replica_key" "replica" {
  provider = aws.replica

  description             = var.description
  deletion_window_in_days = var.deletion_window_in_days
  primary_key_arn         = aws_kms_key.primary.arn
  policy                  = var.replica_key_policy

  tags = merge(
    var.tags,
    {
      "Multi-Region" = "true",
      "Primary"      = "false"
    }
  )
}

# Add an alias to the replica key
resource "aws_kms_alias" "replica" {
  provider = aws.replica

  name          = "alias/${var.alias}"
  target_key_id = aws_kms_replica_key.replica.key_id
}
#######################################################


# FINAL CODE THAT WORKED BELOW

locals {
  admin_username = var.username
  account_id     = data.aws_caller_identity.current.account_id
}
provider "aws" {
  region  = var.aws_region
}
provider "aws" {
  alias  = "replica"
  region = var.replica_region
}
provider "aws" {
  alias  = "replica2"
  region = var.replica_region2
}
resource "aws_kms_key" "kms-primary" {
  multi_region        = true
  description         = var.description
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.kms-test.json
  tags = merge(
    var.tags,
    {
      "Multi-Region" = "true",
      "Primary"      = "true"
    }
  )
}
resource "aws_kms_alias" "alias" {
  name          = "alias/${var.aws_region}-kms-key"
  target_key_id = aws_kms_key.kms-primary.key_id
}
resource "aws_kms_replica_key" "replica1" {
  provider = aws.replica
  description             = "kms key description"
  primary_key_arn         = aws_kms_key.kms-primary.arn
  policy                  = data.aws_iam_policy_document.kms-test.json
  tags = merge(
    var.tags,
    {
      "Multi-Region" = "true",
      "Primary"      = "false"
    }
  )
}
# Add an alias to the replica key
resource "aws_kms_alias" "replica1" {
  provider = aws.replica
  name          = "alias/${var.replica_region}-kms-key"
  target_key_id = aws_kms_replica_key.replica1.key_id
}
resource "aws_kms_replica_key" "replica2" {
  provider = aws.replica2
  description             = "kms key description"
  primary_key_arn         = aws_kms_key.kms-primary.arn
  policy                  = data.aws_iam_policy_document.kms-test.json
  tags = merge(
    var.tags,
    {
      "Multi-Region" = "true",
      "Primary"      = "false"
    }
  )
}
# Add an alias to the replica key
resource "aws_kms_alias" "replica2" {
  provider = aws.replica2
  name          = "alias/${var.replica_region2}-kms-key"
  target_key_id = aws_kms_replica_key.replica2.key_id
}
data "aws_caller_identity" "current" {}
data "aws_iam_policy_document" "kms-test" {
  statement {
    sid       = "Enable IAM User Permissions"
    effect    = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }
    actions    = ["kms:*"]
    resources = ["*"]
  }
  statement {
    sid    = "Allow use of the key"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }
  }
}
