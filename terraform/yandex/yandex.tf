terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  service_account_key_file = "./keys/yandex/key.json"
  cloud_id  = "b1gfrb3if7vehqdb1d95"
  folder_id = "b1gq20gb00i9p51p44mi"
  zone      = "ru-central1-a"
}

resource "yandex_compute_instance" "alice" {
  name = "alice"

  resources {
    cores           = 2
    memory          = 2
    core_fraction   = 20
  }

  boot_disk {
    initialize_params {
      # ubuntu 20-04
      image_id  = "fd8vmcue7aajpmeo39kk"
      size      = 60
    }
  }

  network_interface {
    subnet_id = "e9bi4uu5a2dji6t562h8"
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("./keys/ssh/id_rsa.pub")}"
  }
}

data "template_file" "inventory" {
  template = file("./terraform/_templates/inventory.tpl")
  
  vars = {
    user = "ubuntu"
    host = join("", [yandex_compute_instance.alice.name, " ansible_host=", yandex_compute_instance.alice.network_interface.0.nat_ip_address])
  }
}

resource "local_file" "save_inventory" {
  content  = data.template_file.inventory.rendered
  filename = "./inventory"
}
