terraform {
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
  }
  required_version = ">= 0.13"
}

resource "openstack_compute_keypair_v2" "alice" {
  name = "alice"  
  public_key = file("./keys/ssh/id_rsa.pub")
}

resource "openstack_compute_secgroup_v2" "alice" {
  name = "alice_security_group"

  description = "security group for alice"
  
  rule {
    from_port = 22
    to_port = 22
    ip_protocol = "tcp"
    cidr = "0.0.0.0/0"
  }
    
  rule {
    from_port = -1
    to_port = -1
    ip_protocol = "icmp"
    cidr = "0.0.0.0/0"
  }
}

resource "openstack_blockstorage_volume_v2" "volume" {
  name = "storage"
  
  volume_type = "dp1"
  
  size = "10"

  # uuid индикатор образа, в примере используется Ubuntu-18.04-201910
  image_id = "cd733849-4922-4104-a280-9ea2c3145417"
}

resource "openstack_compute_instance_v2" "instance" {
  name = "alice"

  image_name = "Ubuntu-18.04-201910"
  image_id = "cd733849-4922-4104-a280-9ea2c3145417"
  
  flavor_name = "Basic-1-1-10"

  key_pair = openstack_compute_keypair_v2.alice.name

  config_drive = true

  security_groups = [ openstack_compute_secgroup_v2.alice.name ]

  network {
    name = "ext-net"
  }

  block_device {
    uuid = openstack_blockstorage_volume_v2.volume.id
    boot_index = 0
    source_type = "volume"
    destination_type = "volume"
  }
}

data "template_file" "inventory" {
  template = file("./terraform/_templates/inventory.tpl")
  
  vars = {
    user = "ubuntu"
    host = join("", [openstack_compute_instance_v2.instance.name, " ansible_host=", openstack_compute_instance_v2.instance.access_ip_v4])
  }
}

resource "local_file" "save_inventory" {
  content  = data.template_file.inventory.rendered
  filename = "./inventory"
}
