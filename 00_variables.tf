variable "network_external_id" {
  type    = string
  default = "0f9c3806-bd21-490f-918d-4a6d1c648489"
}
variable "network_external_name" {
  type    = string
  default = "ext-floating1"
}

variable "network_internal_dev" {
  type    = string
  default = "internal_dev"
}

variable "network_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}
variable "ssh_public_key_default_user" {
  type    = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC60sTuT3KRvztArjPu8kLPkGJghw2/l+RydojjFwPDj8oaxisZLhVLqNCoQAdIk2C9gMG283wmuWQasbIwHYUUjAMZYaMabuTepBXGkg2ayZ6artL2UrbKApdwmItS76cKQquZ9AxEzmxl0Oc0RXDWvokQmEyoALMLhviMSVQ6KKj9fX+YhIk1toWYdIHrYl+vf4c3PTYfYbwmKFep1QZEmEFG4hZtGSbYpc6OIA7ZCDnKHvHykggLJGKs2CdzIy9m1Es70s7cP/AfW8k6OimGJtKAyDNguL2rpJAwmxucjjEtvm2k0VUL2a7UC9OwJ2w2jTT8INOd+y84brntXpVJ Generated-by-Nova"
}

variable "instance_image_id" {
  type    = string
  default = "cdf81c97-4873-473b-b0a3-f407ce837255"
}
variable "instance_flavor_name" {
  type    = string
  default = "a1-ram2-disk20-perf1"
}
variable "instance_security_groups" {
  type    = list(any)
  default = ["default"]
}
variable "metadatas" {
  type = map(string)
  default = {
    "environment" = "dev"
  }
}
