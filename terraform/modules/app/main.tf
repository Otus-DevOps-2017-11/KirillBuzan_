data "template_file" "puma-service" {
  template = "${file("${path.module}/files/puma.service.tpl")}"

  vars {
    database_address = "${var.database_url}"
  }
}


resource "google_compute_instance" "app" {
  name         = "reddit-app"
  machine_type = "${var.machine_type}"
  zone         = "${var.zone}"
  tags         = "${var.target_tags}"

  boot_disk {
    initialize_params {
      image = "${var.app_disk_image}"
    }
  }

  network_interface {
    network = "default"

    access_config = {
      nat_ip = "${google_compute_address.app_ip.address}"
    }
  }

  metadata {
    sshKeys = "appuser:${file(var.public_key_path)}"
  }
  
  connection {
    type        = "ssh"
    user        = "appuser"
    agent       = false
    private_key = "${file(var.private_key_path)}"
  }
  
  provisioner "file" {
    content      = "${data.template_file.puma-service.rendered}"
    destination = "/tmp/puma.service"
  }
  
  provisioner "remote-exec" {
    script = "${path.module}/files/deploy.sh"
  }
}

resource "google_compute_address" "app_ip" {
  name = "reddit-app-ip"
}

resource "google_compute_firewall" "firewall_puma" {
  name    = "allow-puma-default"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = "${var.firewall_puma_port}"
  }

  source_ranges = "${var.source_ranges}"
  target_tags   = "${var.target_tags}"
}

resource "google_compute_firewall" "firewall_puma_http" {
  name    = "allow-puma-http-default"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = "${var.firewall_puma_http_port}"
  }

  source_ranges = "${var.source_ranges}"
  target_tags   = "${var.target_tags}"
}
