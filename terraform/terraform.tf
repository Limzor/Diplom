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

# Data Source for VPC Network
data "yandex_vpc_network" "net" {
  folder_id = "b1g8d3vvcamfhk1v106q"
  name      = yandex_vpc_network.my_vpc.name
}

# Public Subnet for Bastion and Zabbix, Kibana
resource "yandex_vpc_subnet" "public" {
  name           = "public-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.my_vpc.id
  v4_cidr_blocks = ["10.0.0.0/24"]
}



# NAT Gateway
resource "yandex_vpc_gateway" "nat_gateway" {
  folder_id = "b1g8d3vvcamfhk1v106q"
  name      = "nat-gateway"
  shared_egress_gateway {}
}

# Route Table for NAT Gateway
resource "yandex_vpc_route_table" "nat_route_table" {
  folder_id  = "b1g8d3vvcamfhk1v106q"
  name       = "nat-route-table"
  network_id = yandex_vpc_network.my_vpc.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

# Private Subnet for Web1 and Elasticsearch
resource "yandex_vpc_subnet" "private" {
  name           = "private-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.my_vpc.id
  v4_cidr_blocks = ["10.0.1.0/24"]
  route_table_id = yandex_vpc_route_table.nat_route_table.id
}
# Private Subnet for Web2
resource "yandex_vpc_subnet" "private_zone_b" {
  name           = "private-subnet-zone-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.my_vpc.id
  v4_cidr_blocks = ["10.0.2.0/24"]
  route_table_id = yandex_vpc_route_table.nat_route_table.id
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
      image_id = "fd8ljvsrm3l1q2tgqji9" # OS
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
      image_id = "fd8ljvsrm3l1q2tgqji9" # OS
      size     = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.private.id
    nat       = false
    security_group_ids = [yandex_vpc_security_group.secure_web_inner_sg.id]
  }

  metadata = {
    serial-port-enable = 1
    ssh-keys = "ubuntu:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMvuW0/zSNKh8zJMncYAAz2jLZgAQprmwH9KCsa8Z+Fx limzor@debian"
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
      image_id = "fd8ljvsrm3l1q2tgqji9" # OS
      size     = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.private_zone_b.id
    nat       = false
    security_group_ids = [yandex_vpc_security_group.secure_web_inner_sg.id]
  }

  metadata = {
    serial-port-enable = 1
    ssh-keys = "ubuntu:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMvuW0/zSNKh8zJMncYAAz2jLZgAQprmwH9KCsa8Z+Fx limzor@debian"
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
      image_id = "fd8ljvsrm3l1q2tgqji9" # OS
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
      image_id = "fd8ljvsrm3l1q2tgqji9" # OS
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
      image_id = "fd8ljvsrm3l1q2tgqji9" # OS
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
    port             = 80
    target_group_ids = [yandex_alb_target_group.web_target_group.id]
    load_balancing_config {
      panic_threshold      = 90
    }    
    healthcheck {
      timeout              = "10s"
      interval             = "2s"
      healthy_threshold    = 10
      unhealthy_threshold  = 15
      http_healthcheck {
        path               = "/"
      }
    }
  }
}

resource "yandex_alb_http_router" "web_router" {
  name      = "my-http-router"
  labels = {
    tf-label    = "tf-label-value"
    empty-label = ""
  }
}

resource "yandex_alb_virtual_host" "my_web_virtual_host" {
  name           = "my-web-virtual-host"
  http_router_id = yandex_alb_http_router.web_router.id
  route {
    name = "router"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.web_backend_group.id
        timeout          = "60s"
      }
    }
  }
}

resource "yandex_alb_load_balancer" "web_lb" {
  name = "my-load-balancer"
  network_id = yandex_vpc_network.my_vpc.id
  security_group_ids = [yandex_vpc_security_group.secure_web_inner_sg.id]

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.public.id
    }
  }

  listener {
    name = "web-listener"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [80]
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
    v4_cidr_blocks = ["62.84.112.146/32","10.0.0.4/32"]
  }
  ingress {
    protocol       = "TCP"
    description    = "Allow HTTP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "kibana-Server"
    port           = 10051
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "kibana-agent"
    port           = 10050
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "elasticsearch"
    port           = 9200
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "elasticsearch"
    port           = 9300
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "kibana"
    port           = 5601
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

    ingress {
    protocol       = "TCP"
    description    = "kibana-Server"
    port           = 10051
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "kibana-agent"
    port           = 10050
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

  ingress {
    protocol       = "TCP"
    description    = "kibana-Server"
    port           = 10051
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "kibana-agent"
    port           = 10050
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "TCP"
    description    = "Allow all outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "secure_web_inner_sg" {
  name      = "secure-web-inner-sg"
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
