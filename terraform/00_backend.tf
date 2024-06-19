terraform {
  backend "http" {
    address        = "https://gitlab.com/api/v4/projects/56331491/terraform/state/state_vpn"
    lock_address   = "https://gitlab.com/api/v4/projects/56331491/terraform/state/state_vpn/lock"
    unlock_address = "https://gitlab.com/api/v4/projects/56331491/terraform/state/state_vpn/lock"
    lock_method    = "POST"
    unlock_method  = "DELETE"
    retry_wait_min = 5
  }
}
