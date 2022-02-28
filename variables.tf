## Required Variables

variable "aws_region" {
  description = "The AWS region in which to deploy."
  type        = string
}

variable "public_key_file" {
  description = "Full path to the SSH public key file."
  type        = string
}

variable "name" {
  description = "Prefix used for some resources."
  type        = string
}

variable "vpc_cidr_block" {
  description = "VPC address space."
  type        = string
}

variable "public_subnet_prefix" {
  description = "Public subnet prefix in VPC (in CIDR format)."
  type        = string
}

variable "private_subnet_prefix" {
  description = "Private subnet prefix in VPC (in CIDR format)."
  type        = string
}

variable "username" {
  description = "Username to connect to EC2 instances."
  default     = "ec2-user"
  type        = string
}

variable "server_instance_type" {
  description = "Type of server instance used to host K8S."
  type        = string
}

variable "nodes_instance_type" {
  description = "Type of node instances used to host K8S."
  type        = string
}

variable "node_instances_count" {
  description = "Number of K8S nodes."
  type        = number
}

variable "rancher_version" {
  description = "Rancher server version (format v0.0.0)"
  type        = string
}
