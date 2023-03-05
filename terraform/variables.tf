variable "aws_region" {
  type        = string
  description = "AWS Region name to deploy resources in. This must be set on a per environment level."
}

variable "tags" {
  type = object({
    application_name = string
    owner            = string
    environment      = string
    prefix           = string
    costCenter       = string
    tagVersion       = number
    project          = string
  })
  description = "Object defining tagging strategy to use through the entire codebase. You must set this on a per environment level."
}

variable "ssm_tunnel_instance_server" {
  type        = string
  description = "SSM user data configuration kubernetes cluster"
}

variable "ssm_tunnel_instance_client" {
  type        = string
  description = "SSM user data configuration client"
}

variable "ssm_tunnel_instance_server_kubeadm" {
  type        = string
  description = "SSM user data configuration kubernetes cluster prepared for kubeadm bootstrapping"
}

variable "ssh_public_key" {
  type        = string
  description = "Admin SSH public key"
}

variable "kubeadm_on" {
  type        = bool
  default     = false
  description = "Enable kubeadm mode"
}