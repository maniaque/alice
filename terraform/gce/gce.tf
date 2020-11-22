provider "google" {
  credentials = file("./keys/gce/key.json")
  project     = "devops-demo-295819"
  region      = "europe-north1"
}

resource "google_compute_address" "alice" {
  name = "alice"
}

resource "google_compute_instance" "alice" {
  name          = "alice"
  machine_type  = "g1-small"
  zone          = "europe-north1-a"
  
  boot_disk {
    initialize_params {
      image = "ubuntu-minimal-2004-lts"
      type  = "pd-ssd"
      size  = "20"
    }
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = google_compute_address.alice.address
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${file("./keys/ssh/id_rsa.pub")}"
  }
}

# resource "google_compute_firewall" "firewall-ssh" {
#   name    = "allow-ssh"
#   network = "default"

#   allow {
#     protocol = "tcp"
#     ports    = ["22"]
#   }
# }

data "template_file" "inventory" {
  template = file("./terraform/_templates/inventory.tpl")
  
  vars = {
    user = "ubuntu"
    host = join("", [google_compute_instance.alice.name, " ansible_host=", google_compute_instance.alice.network_interface.0.access_config.0.nat_ip])
  }
}

resource "local_file" "save_inventory" {
  content  = data.template_file.inventory.rendered
  filename = "./inventory"
}
