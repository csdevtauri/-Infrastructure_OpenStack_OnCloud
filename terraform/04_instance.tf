# This Terraform file configures an OpenVPN instance on OpenStack with the necessary network resources.
# 1. Retrieves the IDs of the external subnets.
# 2. Creates a floating IP address in the specified pool.
# 3. Configures an OpenVPN compute instance with the specified image, flavor, metadata, and security groups.
# 4. Creates a network port for the OpenVPN instance with associated security groups.
# 5. Associates the floating IP address with the network port of the OpenVPN instance.

data "openstack_networking_subnet_ids_v2" "ext_subnets" {
  network_id = var.network_external_id
}
resource "openstack_networking_floatingip_v2" "floatip_1" {
  pool       = var.network_external_name
  subnet_ids = data.openstack_networking_subnet_ids_v2.ext_subnets.ids
}
resource "openstack_compute_instance_v2" "openvpn" {
  name            = "openvpn"
  image_id        = var.instance_image_id
  flavor_name     = var.instance_flavor_name
  metadata        = var.metadatas
  security_groups = [openstack_networking_secgroup_v2.openvpn.name, openstack_networking_secgroup_v2.ssh.name, "default"]
  key_pair        = openstack_compute_keypair_v2.ssh_public_key.name
  network {
    name = var.network_internal_dev
    port = openstack_networking_port_v2.openvpn_port.id
  }

  depends_on = [
    openstack_networking_subnet_v2.network_subnet,
    openstack_networking_secgroup_rule_v2.secgroup_openvpn_rule_tcp_v4,
    openstack_networking_secgroup_rule_v2.secgroup_openvpn_rule_udp_v4
  ]
}

resource "openstack_networking_port_v2" "openvpn_port" {
  name           = "openvpn_port"
  network_id     = openstack_networking_network_v2.network_internal.id
  admin_state_up = true
  security_group_ids = [
    openstack_networking_secgroup_v2.openvpn.id,
    openstack_networking_secgroup_v2.ssh.id,
  ]
  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.network_subnet.id
    // Optionally, you can specify a specific IP address
    // ip_address = “<address-ip-fixed-desired>”
  }
}
resource "openstack_networking_floatingip_associate_v2" "fip_assoc" {
  floating_ip = openstack_networking_floatingip_v2.floatip_1.address
  port_id     = openstack_networking_port_v2.openvpn_port.id
}




