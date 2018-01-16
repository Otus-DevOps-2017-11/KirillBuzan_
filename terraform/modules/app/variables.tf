variable zone {
  description = "Zone"
  default     = "europe-west1-b"
}

variable app_disk_image {
  description = "Disk image for reddit app"
  default     = "reddit-app-base"
}

variable public_key_path {
  description = "Path to the public key used for ssh access"
}

variable private_key_path {
  description = "Path to the private key used for ssh access"
}

variable machine_type {
  description = "Machine type"
  default     = "g1-small"
}

variable firewall_puma_port {
  description = "Port for access web-app"
  default     = ["9292"]
}

variable source_ranges {
  description = "Allowed IP addresses"
  default     = ["0.0.0.0/0"]
}

variable target_tags {
  description = "Tags"
  default     = ["reddit-app"]
}

variable database_url {
  description = "Database URL. IP-address:port"
  default = "127.0.0.1:27017"
}