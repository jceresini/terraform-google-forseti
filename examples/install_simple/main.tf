/**
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

provider "google" {
  version = "~> 3.7"
  project = var.project_id
}

provider "local" {
  version = "~> 1.4"
}

provider "null" {
  version = "~> 2.1"
}

provider "template" {
  version = "~> 2.1"
}

provider "random" {
  version = "~> 2.2"
}

data "google_compute_network" "forseti_network" {
  name = var.network
}

module "cloud-nat" {
  source                             = "terraform-google-modules/cloud-nat/google"
  name                               = "cloud-nat-${var.project_id}"
  create_router                      = true
  network                            = var.network
  project_id                         = var.project_id
  region                             = var.region
  router                             = "router-${var.project_id}"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetworks = [
    {
      name                     = var.subnetwork
      source_ip_ranges_to_nat  = ["ALL_IP_RANGES"]
      secondary_ip_range_names = []
    }
  ]
}

module "forseti-install-simple" {
  source = "../../"

  project_id = var.project_id
  org_id     = var.org_id
  domain     = var.domain

  server_region   = module.cloud-nat.region
  client_region   = module.cloud-nat.region
  cloudsql_region = var.region
  network         = var.network
  subnetwork      = var.subnetwork

  storage_bucket_location = var.region
  bucket_cai_location     = var.region

  gsuite_admin_email      = var.gsuite_admin_email
  sendgrid_api_key        = var.sendgrid_api_key
  forseti_email_sender    = var.forseti_email_sender
  forseti_email_recipient = var.forseti_email_recipient
  forseti_version         = var.forseti_version

  client_instance_metadata = var.instance_metadata
  server_instance_metadata = var.instance_metadata

  client_tags = var.instance_tags
  server_tags = var.instance_tags

  client_private   = var.private
  server_private   = var.private
  cloudsql_private = var.private
}
