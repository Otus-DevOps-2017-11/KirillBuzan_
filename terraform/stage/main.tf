provider "google" {
  version = "1.4.0"
  project = "${var.project}"
  region  = "${var.region}"
}

# travis
#terraform {
#  backend "gcs" {
#    bucket  = "terraform-hm9"
#    prefix  = "terraform/state"
#  }
#}

locals {
  access_db_tags = ["reddit-app"]
}

module "app" {
  source = "../modules/app"
  public_key_path = "${var.public_key_path}"
  private_key_path = "${var.private_key_path}"
  zone = "${var.zone}"
  app_disk_image = "${var.app_disk_image}"
  machine_type = "g1-small"
  firewall_puma_port = ["9292"]
  source_ranges = ["0.0.0.0/0"]
  target_tags = "${local.access_db_tags}"
}

module "db" {
  source = "../modules/db"
  public_key_path = "${var.public_key_path}"
  zone = "${var.zone}"
  db_disk_image = "${var.db_disk_image}"
  machine_type = "g1-small"
  firewall_mongo_port = ["27017"]
  source_tags = "${local.access_db_tags}"
  target_tags = ["reddit-db"]
}

module "vpc" {
  source        = "../modules/vpc"
  source_ranges = ["0.0.0.0/0"]
}
