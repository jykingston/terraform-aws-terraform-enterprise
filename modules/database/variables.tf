# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "network_id" {
  description = <<-EOD
  The identity of the VPC in which the security group attached to the PostgreSQL RDS instance will be deployed.
  EOD
  type        = string
}

variable "db_size" {
  type        = string
  default     = "db.m4.xlarge"
  description = "PostgreSQL instance size."
}

variable "db_backup_retention" {
  type        = number
  description = "The days to retain backups for. Must be between 0 and 35"
  default     = 0
}

variable "db_backup_window" {
  type        = string
  description = "The daily time range (in UTC) during which automated backups are created if they are enabled"
  default     = null
}

variable "engine_version" {
  type        = string
  description = "PostgreSQL version."
}

variable "network_subnets_private" {
  description = <<-EOD
  A list of the identities of the private subnetworks in which the PostgreSQL RDS instance will be deployed.
  EOD
  type        = list(string)
}

variable "tfe_instance_sg" {
  description = <<-EOD
  The identity of the security group attached to the TFE EC2 instance(s), which will be authorized for communication with the PostgreSQL RDS instance.
  EOD
  type        = string
}

variable "friendly_name_prefix" {
  type        = string
  description = "(Required) Friendly name prefix used for tagging and naming AWS resources."
}

variable "network_private_subnet_cidrs" {
  type        = list(string)
  description = "(Optional) List of private subnet CIDR ranges to create in VPC."
  default     = ["10.0.32.0/20", "10.0.48.0/20"]
}

variable "kms_key_arn" {
  description = <<-EOD
  The Amazon Resource Name of the KMS key which will be used by the Redis Elasticache replication group to encrypt data 
  at rest.
  EOD
  type        = string
}