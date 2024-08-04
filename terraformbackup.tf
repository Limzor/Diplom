resource "yandex_vpc_address" "addr" {
  name = "vm-address"

  external_ipv4_address {
    zone_id = "ru-central1-a"
  }
}

# VPC Network
resource "yandex_vpc_network" "my_vpc" {
  name = "my-vpc"
}

# Public Subnet for Bastion and Zabbix, Kibana
resource "yandex_vpc_subnet" "public" {
  name           = "public-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.my_vpc.id
  v4_cidr_blocks = ["10.0.0.0/24"]
}

# Private Subnet for Web Servers and Elasticsearch
resource "yandex_vpc_subnet" "private" {
  name           = "private-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.my_vpc.id
  v4_cidr_blocks = ["10.0.1.0/24"]
}

resource "yandex_vpc_subnet" "private_zone_b" {
  name           = "private-subnet-zone-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.my_vpc.id
  v4_cidr_blocks = ["10.0.2.0/24"]
}

# Bastion Host Configuration
resource "yandex_compute_instance" "bastion_host" {
  name        = "bastion-host"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8k354i289n7v3j8lt6" # OS
      size     = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public.id
    nat       = true
    security_group_ids = [yandex_vpc_security_group.secure_bastion_sg.id]
  }


  metadata = {
    serial-port-enable = 1
    ssh-keys = "ubuntu:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMvuW0/zSNKh8zJMncYAAz2jLZgAQprmwH9KCsa8Z+Fx limzor@debian"
  }
  

  scheduling_policy {
    preemptible = true
  }


}

# Web Server 1
resource "yandex_compute_instance" "web_vm_1" {
  name        = "web-vm-1"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8k354i289n7v3j8lt6" # OS
      size     = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.private.id
    nat       = false
    security_group_ids = [yandex_vpc_security_group.secure_inner_sg.id]
  }

  metadata = {
    serial-port-enable = 1
    ssh-keys = "ubuntu:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMvuW0/zSNKh8zJMncYAAz2jLZgAQprmwH9KCsa8Z+Fx limzor@debian"
  }

  scheduling_policy {
    preemptible = true
  }

}

# Web Server 2
resource "yandex_compute_instance" "web_vm_2" {
  name        = "web-vm-2"
  platform_id = "standard-v3"
  zone        = "ru-central1-b"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8k354i289n7v3j8lt6" # OS
      size     = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.private_zone_b.id
    nat       = false
    security_group_ids = [yandex_vpc_security_group.secure_inner_sg.id]
  }

  metadata = {
    serial-port-enable = 1
    ssh-keys = "ubuntu:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMvuW0/zSNKh8zJMncYAAz2jLZgAQprmwH9KCsa8Z+Fx limzor@debian"
  }

  scheduling_policy {
    preemptible = true
  }
}

# Zabbix VM
resource "yandex_compute_instance" "zabbix_vm" {
  name        = "zabbix-vm"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8k354i289n7v3j8lt6" # OS
      size     = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public.id
    nat       = true
    security_group_ids = [yandex_vpc_security_group.internal_bastion_sg.id]
  }

  metadata = {
    serial-port-enable = 1
    ssh-keys = "ubuntu:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMvuW0/zSNKh8zJMncYAAz2jLZgAQprmwH9KCsa8Z+Fx limzor@debian"
  }

  scheduling_policy {
    preemptible = true
  }
}

# Elasticsearch VM
resource "yandex_compute_instance" "elasticsearch_vm" {
  name        = "elasticsearch-vm"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8k354i289n7v3j8lt6" # OS
      size     = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.private.id
    nat       = false
    security_group_ids = [yandex_vpc_security_group.secure_inner_sg.id]
  }

  metadata = {
    serial-port-enable = 1
    ssh-keys = "ubuntu:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMvuW0/zSNKh8zJMncYAAz2jLZgAQprmwH9KCsa8Z+Fx limzor@debian"
  }

  scheduling_policy {
    preemptible = true
  }
}

# Kibana VM
resource "yandex_compute_instance" "kibana_vm" {
  name        = "kibana-vm"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8k354i289n7v3j8lt6" # OS
      size     = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public.id
    nat       = true
    security_group_ids = [yandex_vpc_security_group.internal_bastion_sg.id]
  }

  metadata = {
    serial-port-enable = 1
    ssh-keys = "ubuntu:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMvuW0/zSNKh8zJMncYAAz2jLZgAQprmwH9KCsa8Z+Fx limzor@debian"
  }


  scheduling_policy {
    preemptible = true
  }
}

# Load Balancer Configuration

resource "yandex_alb_target_group" "web_target_group" {
  name = "web-target-group"

  target {
    ip_address = yandex_compute_instance.web_vm_1.network_interface.0.ip_address
    subnet_id  = yandex_vpc_subnet.private.id
  }

  target {
    ip_address = yandex_compute_instance.web_vm_2.network_interface.0.ip_address
    subnet_id  = yandex_vpc_subnet.private_zone_b.id
  }
}

resource "yandex_alb_backend_group" "web_backend_group" {
  name = "web-backend-group"

  http_backend {
    name             = "web-backend"
    weight           = 1
    target_group_ids = [yandex_alb_target_group.web_target_group.id]

    healthcheck {
      timeout = "1s"
      interval = "2s"
      http_healthcheck {
        path  = "/"
    }
  }
}
}

resource "yandex_alb_http_router" "web_router" {
  name      = "my-http-router"
  labels = {
    tf-label    = "tf-label-value"
    empty-label = "s"
  }
}

resource "yandex_alb_load_balancer" "web_lb" {
  name = "my-load-balancer"

  network_id = yandex_vpc_network.my_vpc.id

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.public.id
    }
  }

  listener {
    name = "http-listener"

    endpoint {
      ports     = [80] # Corrected to a list containing one item
      address {
        external_ipv4_address {}
      }
    }

    http {
      handler {
        http_router_id = yandex_alb_http_router.web_router.id
      }
    }
  }
}





# Security Group

resource "yandex_vpc_security_group" "internal_bastion_sg" {
  name      = "internal-bastion-sg"
  network_id = yandex_vpc_network.my_vpc.id

  ingress {
    protocol       = "TCP"
    description    = "Allow SSH from specific IP"
    port           = 22
    v4_cidr_blocks = ["89.169.143.4/32","10.0.0.25/32"]
  }
  ingress {
    protocol       = "TCP"
    description    = "Allow HTTP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "Allow HTTPS"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "TCP"
    description    = "Allow all outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "secure_bastion_sg" {
  name      = "secure-bastion-sg"
  network_id = yandex_vpc_network.my_vpc.id

  ingress {
    protocol       = "TCP"
    description    = "Allow SSH from anywhere"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "TCP"
    description    = "Allow all outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "secure_inner_sg" {
  name      = "secure-inner-sg"
  network_id = yandex_vpc_network.my_vpc.id

  ingress {
    protocol       = "TCP"
    description    = "Allow all inbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "TCP"
    description    = "Allow all outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Snapshot Schedule
resource "yandex_compute_snapshot_schedule" "snapshot_schedule" {
  name = "snapshot-schedule"

  schedule_policy {
    expression = "0 3 * * *" # Daily at 3 AM
  }

  snapshot_spec {
    description = "Daily snapshot"
    labels = {
      snapshot = "daily"
    }
  }

  disk_ids = [
    yandex_compute_instance.web_vm_1.boot_disk.0.disk_id,
    yandex_compute_instance.web_vm_2.boot_disk.0.disk_id,
    yandex_compute_instance.zabbix_vm.boot_disk.0.disk_id,
    yandex_compute_instance.elasticsearch_vm.boot_disk.0.disk_id,
    yandex_compute_instance.kibana_vm.boot_disk.0.disk_id,
    yandex_compute_instance.bastion_host.boot_disk.0.disk_id
  ]
  
}
  output "bastion_public_ip" {
  value = yandex_compute_instance.bastion_host.network_interface[0].nat_ip_address
}
output "bastion_local_ip" {
  value = yandex_compute_instance.bastion_host.network_interface[0].ip_address
}

