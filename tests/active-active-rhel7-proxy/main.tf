# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "aws" {
  assume_role {
    role_arn = var.aws_role_arn
  }

  default_tags {
    tags = local.common_tags
  }
}

resource "random_string" "friendly_name" {
  length  = 4
  upper   = false # Some AWS resources do not accept uppercase characters.
  number  = false
  special = false
}

# Store TFE License as secret
# ---------------------------
module "secrets" {
  count  = local.utility_module_test ? 0 : 1
  source = "../../fixtures/secrets"

  tfe_license = {
    name = "${local.friendly_name_prefix}-tfe-license"
    path = var.license_file
  }
}

data "aws_iam_user" "ci_s3" {
  user_name = var.object_storage_iam_user_name
}

module "kms" {
  source        = "../../fixtures/kms"
  key_alias     = "${local.friendly_name_prefix}-key"
  iam_principal = local.iam_principal
}

resource "tls_private_key" "main" {
  count     = local.utility_module_test ? 0 : 1
  algorithm = "RSA"
}

resource "local_file" "private_key_pem" {
  count    = local.utility_module_test ? 0 : 1
  filename = "${path.module}/work/private-key.pem"

  content         = tls_private_key.main[0].private_key_pem
  file_permission = "0600"
}

resource "aws_key_pair" "main" {
  count      = local.utility_module_test ? 0 : 1
  public_key = tls_private_key.main[0].public_key_openssh
  key_name   = "${local.friendly_name_prefix}-ssh"
}

module "test_proxy" {
  source                          = "../../fixtures/test_proxy"
  subnet_id                       = module.tfe.private_subnet_ids[0]
  key_name                        = local.utility_module_test ? var.key_name : aws_key_pair.main[0].key_name
  name                            = local.friendly_name_prefix
  http_proxy_port                 = local.http_proxy_port
  vpc_id                          = module.tfe.network_id
  mitmproxy_ca_certificate_secret = data.aws_secretsmanager_secret.ca_certificate.arn
  mitmproxy_ca_private_key_secret = data.aws_secretsmanager_secret.ca_private_key.arn

}

module "tfe" {
  source = "../../"

  acm_certificate_arn   = var.acm_certificate_arn
  domain_name           = var.domain_name
  friendly_name_prefix  = local.friendly_name_prefix
  tfe_license_secret_id = try(module.secrets[0].tfe_license_secret_id, var.tfe_license_secret_id)

  ami_id                   = data.aws_ami.rhel.id
  aws_access_key_id        = var.aws_access_key_id
  aws_secret_access_key    = var.aws_secret_access_key
  ca_certificate_secret_id = data.aws_secretsmanager_secret.ca_certificate.arn
  consolidated_services    = var.consolidated_services
  distribution             = "rhel"
  iact_subnet_list         = ["0.0.0.0/0"]
  iam_role_policy_arns     = [local.ssm_policy_arn, "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"]
  instance_type            = "m5.xlarge"
  key_name                 = local.utility_module_test ? var.key_name : aws_key_pair.main[0].key_name
  kms_key_arn              = module.kms.key
  load_balancing_scheme    = local.load_balancing_scheme
  object_storage_iam_user  = data.aws_iam_user.object_storage
  node_count               = 2
  proxy_ip                 = module.test_proxy.proxy_ip
  proxy_port               = local.http_proxy_port
  tfe_subdomain            = local.test_name

  asg_tags = local.common_tags
}

resource "null_resource" "wait_for_instances" {
  triggers = {
    arn = module.tfe.tfe_autoscaling_group.arn
  }

  provisioner "local-exec" {
    command = "sleep 30"
  }
}

resource "local_file" "ssh_config" {
  count    = local.utility_module_test ? 0 : 1
  filename = "${path.module}/work/ssh-config"

  content = templatefile(
    "${path.module}/templates/ssh-config.tpl",
    {
      instance      = data.null_data_source.instance.outputs
      identity_file = local_file.private_key_pem[0].filename
      user          = local.ssh_user
    }
  )
}
