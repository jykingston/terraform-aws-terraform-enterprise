# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "private_tcp_active_active" {
  value = module.private_tcp_active_active

  description = "The outputs of the private_tcp_active_active module."
  # This output is marked as sensitive to work around a bug in Terraform 0.14
  sensitive = true
}

output "tfe_url" {
  value = module.private_tcp_active_active.tfe_url

  description = "The URL to the TFE application."
}

output "health_check_url" {
  value = "${module.private_tcp_active_active.tfe_url}/_health_check"

  description = "The URL with path to access the TFE instance health check."
}

output "iact_url" {
  value = "${module.private_tcp_active_active.tfe_url}/admin/retrieve-iact"

  description = "The URL with path to access the TFE instance Retrieve IACT."
}

output "initial_admin_user_url" {
  value = "${module.private_tcp_active_active.tfe_url}/admin/initial-admin-user"

  description = "The URL with path to access the TFE instance Initial Admin User."
}

output "tfe_autoscaling_group_name" {
  value = module.private_tcp_active_active.tfe_autoscaling_group.name

  description = "The name of the autoscaling group which hosts the TFE EC2 instance(s)."
  # This output is marked as sensitive to work around a bug in Terraform 0.14
  sensitive = true
}

output "proxy_instance_id" {
  value = module.test_proxy.proxy_instance_id

  description = "The ID of the proxy EC2 instance."
}
