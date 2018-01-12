provider "google" {
  version = "1.4.0"
  project = "${var.project}"
  region  = "${var.region}"
}

# Trying to use templates for array of users
data "template_file" "users_sshkey" {
  template = "$${users_key}"

  vars {
    count     = "${length(split(",", var.users))}"
    users_key = "$${users_key}\n${element(split(",", var.users), count.index)}:${file(var.public_key_path)}"
  }
}

# -------- Metadata block --------------
resource "google_compute_project_metadata" "users" {
  #count = "${length(split(",", var.users))}"
  metadata {
    #ssh-keys = "${element(split(",", var.users), count.index)}:${file(var.public_key_path)} ${element(split(",", var.users), count.index)}"
    #ssh-keys = "${element(split(",", var.users), count.index)}:${file(var.public_key_path)}"
    ssh-keys = "appuser2:${file(var.public_key_path)}\nappuser1:${file(var.public_key_path)}\nappuser:${file(var.public_key_path)}"

    #ssh-keys = "${data.template_file.users_sshkey.rendered}"
  }
}

# ---------- Create Intances block ------------
resource "google_compute_instance" "app" {
  # Count created instances. Default value = 1
  count = "${var.count_devices}"

  #name         = "reddit-app"
  #Added index for name instance. Use to be google_compute_instance.app.self_link
  # Now: google_compute_instance.app.0.self_link, google_compute_instance.app.1.self_link ... 
  name = "reddit-app-${count.index}"

  machine_type = "g1-small"
  zone         = "${var.zone}"
  tags         = ["reddit-app"]

  # Comment beacuse use resource "google_compute_project_metadata"
  #metadata {
  #  sshKeys = "appuser:${file(var.public_key_path)}"
  #}

  # initialize boot disk's params
  boot_disk {
    initialize_params {
      image = "${var.disk_image}"
    }
  }
  # initialize network intarface
  network_interface {
    # network
    network = "default"

    # Enthernal IP
    access_config {}
  }
  connection {
    type        = "ssh"
    user        = "appuser"
    agent       = false
    private_key = "${file(var.private_key_path)}"
  }
  provisioner "file" {
    source      = "files/puma.service"
    destination = "/tmp/puma.service"
  }
  provisioner "remote-exec" {
    script = "files/deploy.sh"
  }
}

# ----------- Create frewall rules block ---------------
resource "google_compute_firewall" "firewall_puma" {
  name    = "allow-puma-deafult"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["9292"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["reddit-app"]
}

# ------------- Balancer block --------------
# ---------- Create common group for app instances
resource "google_compute_instance_group" "all-reddit-app-group" {
  name        = "all-reddit-app-group"
  description = "Group for all instances reddit-app"
  instances   = ["${google_compute_instance.app.*.self_link}"]

  named_port {
    name = "http"
    port = "9292"
  }

  zone = "${var.zone}"
}

# -------- Rule for checking instances ---------
resource "google_compute_http_health_check" "all-reddit-app-health-check" {
  name               = "all-reddit-app-health-check"
  request_path       = "/"
  check_interval_sec = 3
  timeout_sec        = 3
  port               = "9292"
}

# -------------- Backend-service ---------------
resource "google_compute_backend_service" "all-reddit-app-backend-service" {
  name        = "all-reddit-app-backend-service"
  description = "Service defines a group of vm that will serve traffic for load balancing"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  backend {
    group = "${google_compute_instance_group.all-reddit-app-group.self_link}"
  }

  health_checks = ["${google_compute_http_health_check.all-reddit-app-health-check.self_link}"]
}

# -------------- Manages a URL map resource ------------
resource "google_compute_url_map" "all-reddit-app-url-map" {
  name            = "all-reddit-app-url-map"
  description     = "Manages a URL map resource"
  default_service = "${google_compute_backend_service.all-reddit-app-backend-service.self_link}"
}

# --------------- Creates a target HTTP proxy resource ----------
resource "google_compute_target_http_proxy" "all-reddit-app-http-proxy" {
  name        = "all-reddit-app-http-proxy"
  description = "Creates a target HTTP proxy resource"
  url_map     = "${google_compute_url_map.all-reddit-app-url-map.self_link}"
}

# -------------- Manages a Global Forwarding Rule ---------------
resource "google_compute_global_forwarding_rule" "all-reddit-app-forwarding-rule" {
  name        = "all-reddit-app-forwarding-rule"
  description = "This binds an ip and port to a target http proxy"
  target      = "${google_compute_target_http_proxy.all-reddit-app-http-proxy.self_link}"
  port_range  = "80"
}
