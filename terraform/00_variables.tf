variable "network_external_id" {
  description = "ID of the external network"
  type        = string
}

variable "network_external_name" {
  description = "Name of the external network"
  type        = string
}

variable "network_internal_dev" {
  description = "Name of the internal network for development"
  type        = string
}

variable "network_subnet_cidr" {
  description = "CIDR block for the internal network subnet"
  type        = string
}

variable "ssh_public_key_default_user" {
  description = "Default SSH public key for the user"
  type        = string
}

variable "instance_image_id" {
  description = "ID of the image to use for the instance"
  type        = string
}

variable "instance_flavor_name" {
  description = "Flavor of the instance"
  type        = string
}

variable "instance_security_groups" {
  description = "List of security groups for the instance"
  type        = list(any)
}

variable "metadatas" {
  description = "Metadata for the instance"
  type        = map(string)
}

