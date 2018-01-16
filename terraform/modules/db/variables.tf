variable zone {
  description = "Zone"
  default     = "europe-west1-b"
}

variable db_disk_image {
  description = "Disk image for reddit db"
  default     = "reddit-db-base"
}

variable public_key_path {
  description = "Path to the public key used for ssh access"
}

variable machine_type {
  description = "Machine type"
  default     = "g1-small"
}

variable firewall_mongo_port {
  description = "Port for access mingodb"
  default     = ["27017"]
}

variable source_tags {
  description = "Source Tags"
  default     = ["reddit-app"]
}

variable target_tags {
  description = "Target Tags"
  default     = ["reddit-db"]
}
