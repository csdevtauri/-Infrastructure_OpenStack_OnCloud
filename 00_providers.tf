terraform {
  required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~>2.0.0"
    }
  }

  backend "http" {
    address        = "https://gitlab.com/api/v4/projects/56331491/terraform/state/state_vpn"
    lock_address   = "https://gitlab.com/api/v4/projects/56331491/terraform/state/state_vpn/lock"
    unlock_address = "https://gitlab.com/api/v4/projects/56331491/terraform/state/state_vpn/lock"
    lock_method    = "POST"
    unlock_method  = "DELETE"
    retry_wait_min = 5
  }

}