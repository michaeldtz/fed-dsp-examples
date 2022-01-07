# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

locals {
  key_prefix = "projects/${var.project_id}/locations/${var.location}/keyRings"
}

provider "google" {
  project = var.project_id
}

resource "google_project_iam_custom_role" "dataspace_admin_role" {
  role_id     = "dataspace_admin"
  title       = "Dataspace Admin"
  description = "role for an owner of a data space"
  permissions = ["bigquery.datasets.get","bigquery.datasets.delete","storage.buckets.list","storage.buckets.get","storage.buckets.delete"]
}

resource "google_project_iam_custom_role" "dataspace_owner_role" {
  role_id     = "dataspace_owner"
  title       = "Dataspace Owner"
  description = "role for an owner of a data space"
  permissions = ["storage.buckets.createTagBinding","storage.buckets.deleteTagBinding","storage.buckets.get","storage.buckets.getIamPolicy","storage.buckets.listTagBindings","storage.buckets.setIamPolicy","storage.buckets.update","storage.multipartUploads.abort","storage.multipartUploads.create","storage.multipartUploads.list","storage.multipartUploads.listParts","storage.objects.create","storage.objects.delete","storage.objects.list","bigquery.datasets.create","bigquery.datasets.delete","bigquery.datasets.get","bigquery.datasets.getIamPolicy","bigquery.datasets.setIamPolicy","bigquery.datasets.update","bigquery.datasets.updateTag","bigquery.models.create","bigquery.models.delete","bigquery.models.export","bigquery.models.getData","bigquery.models.getMetadata","bigquery.models.list","bigquery.models.updateData","bigquery.models.updateMetadata","bigquery.models.updateTag","bigquery.routines.create","bigquery.routines.delete","bigquery.routines.get","bigquery.routines.list","bigquery.routines.update","bigquery.routines.updateTag","bigquery.rowAccessPolicies.create","bigquery.rowAccessPolicies.delete","bigquery.rowAccessPolicies.getIamPolicy","bigquery.rowAccessPolicies.list","bigquery.rowAccessPolicies.setIamPolicy","bigquery.rowAccessPolicies.update","bigquery.tables.create","bigquery.tables.delete","bigquery.tables.export","bigquery.tables.get","bigquery.tables.getData","bigquery.tables.getIamPolicy","bigquery.tables.list","bigquery.tables.setCategory","bigquery.tables.setIamPolicy","bigquery.tables.update","bigquery.tables.updateData","bigquery.tables.updateTag"]
}

resource "google_project_iam_custom_role" "dataspace_federated_reader_role" {
  role_id     = "dataspace_federated_reader"
  title       = "Federated Reader"
  description = "role for a federated reader of dataspaces"
  permissions = ["bigquery.datasets.get","bigquery.routines.get","bigquery.routines.list","bigquery.tables.get","bigquery.tables.getData","bigquery.tables.list","storage.objects.list","storage.buckets.get","bigquery.readsessions.create"]
}

resource "google_project_iam_custom_role" "dataspace_federated_writer_role" {
  role_id     = "dataspace_federated_writer"
  title       = "Federated Writer"
  description = "role for a federated writer of dataspaces"
  permissions = ["bigquery.datasets.get","bigquery.models.create","bigquery.models.delete","bigquery.models.export","bigquery.models.getData","bigquery.models.getMetadata","bigquery.models.list","bigquery.models.updateData","bigquery.models.updateMetadata","bigquery.models.updateTag","bigquery.routines.create","bigquery.routines.delete","bigquery.routines.get","bigquery.routines.list","bigquery.routines.update","bigquery.routines.updateTag","bigquery.rowAccessPolicies.create","bigquery.rowAccessPolicies.delete","bigquery.rowAccessPolicies.getIamPolicy","bigquery.rowAccessPolicies.list","bigquery.rowAccessPolicies.setIamPolicy","bigquery.rowAccessPolicies.update","bigquery.tables.create","bigquery.tables.delete","bigquery.tables.export","bigquery.tables.get","bigquery.tables.getData","bigquery.tables.getIamPolicy","bigquery.tables.list","bigquery.tables.setCategory","bigquery.tables.setIamPolicy","bigquery.tables.update","bigquery.tables.updateData","bigquery.tables.updateTag","storage.multipartUploads.abort","storage.multipartUploads.create","storage.multipartUploads.list","storage.multipartUploads.listParts","storage.objects.create","storage.objects.delete","storage.objects.list"]
}



resource "google_service_account" "ds_federated_access" {
  account_id   = "federated-access-sa"
  display_name = "ServiceAccount for Federated Access"
}

resource "google_service_account" "ds_federated_compute" {
  account_id   = "federated-compute-sa"
  display_name = "ServiceAccount for Federated Compute"
}

resource "google_service_account" "ds_admin_sa" {
  account_id   = "dataspace-admin-sa"
  display_name = "ServiceAccount for Admin Access"
}

# Give the fed access and compute SA the job role (it's a role on project level)
resource "google_project_iam_binding" "project" {
  role    = "roles/bigquery.jobUser"
  members = [
    "serviceAccount:${google_service_account.ds_federated_access.email}",
    "serviceAccount:${google_service_account.ds_federated_compute.email}",
  ]
}



# Federation Bucket

resource "google_storage_bucket" "ds_federation_bucket" {
  name                        = "${var.federation_name}-${var.project_id}" 
  location                    = var.location
  force_destroy               = true
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_binding" "writer_for_access" {
  bucket = google_storage_bucket.ds_federation_bucket.name
  role   = google_project_iam_custom_role.dataspace_federated_writer_role.id
  members = [
    "serviceAccount:${google_service_account.ds_federated_access.email}",
  ]
}

resource "google_storage_bucket_iam_binding" "reader_for_compute" {
  bucket = google_storage_bucket.ds_federation_bucket.name
  role   = google_project_iam_custom_role.dataspace_federated_reader_role.id
  members = [
    "serviceAccount:${google_service_account.ds_federated_compute.email}",
  ]
}



# Federation BigQuery Dataset

resource "google_bigquery_dataset" "ds_federation_dataset" {
  dataset_id                  = replace(var.federation_name,"-","_")
  friendly_name               = "Dataset for Dataspace Federation"
  location                    = var.location
  default_table_expiration_ms = 3600000

  access {
    role          = "OWNER"
    user_by_email = google_service_account.ds_admin_sa.email
  }

  labels = {
    type = "federation"
  }

  access {
    role          = google_project_iam_custom_role.dataspace_federated_reader_role.id
    user_by_email = google_service_account.ds_federated_compute.email
  }

  access {
    role          = google_project_iam_custom_role.dataspace_federated_writer_role.id
    user_by_email = google_service_account.ds_federated_access.email
  }

}

# WorkEnv Bucket

resource "google_storage_bucket" "ds_workenv_bucket" {
  name                        = "${var.workenv_name}-${var.project_id}" 
  location                    = var.location
  force_destroy               = true
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_binding" "writer_for_compute" {
  bucket = google_storage_bucket.ds_federation_bucket.name
  role   = google_project_iam_custom_role.dataspace_federated_writer_role.id
  members = [
    "serviceAccount:${google_service_account.ds_federated_compute.email}",
    "serviceAccount:${google_service_account.ds_federated_access.email}",
  ]
}

# WorkEnv BigQuery Dataset

resource "google_bigquery_dataset" "ds_workenv_dataset" {
  dataset_id                  = replace(var.workenv_name,"-","_")
  friendly_name               = "Dataset for Dataspace Workenv"
  location                    = var.location

  labels = {
    type = "workenv"
  }

  access {
    role          = google_project_iam_custom_role.dataspace_federated_writer_role.id
    user_by_email = google_service_account.ds_federated_compute.email
  }

  access {
    role          = google_project_iam_custom_role.dataspace_federated_writer_role.id
    user_by_email = google_service_account.ds_federated_access.email
  }

  access {
    role          = "OWNER"
    user_by_email = google_service_account.ds_admin_sa.email
  }

}

# Create 3 Dataspaces

module "dataspace" {
  for_each  = {
                d1 = { "id" = "d1" },
                d2 = { "id" = "d2" },
                d3 = { "id" = "d3" },
              }

  source           = "./modules/dataspace"

  project_id       = var.project_id
  dataspace_id     = each.value.id
  location         = var.location

  use_custom_key   = false
  custom_key_id    = "${local.key_prefix}/${var.used_keyring_prefix}-${each.value.id}/cryptoKeys/${var.used_key_prefix}-${each.value.id}"  
  
  owner_role       = google_project_iam_custom_role.dataspace_owner_role.id

  reader_role      = google_project_iam_custom_role.dataspace_federated_reader_role.id
  fed_access_sa    = google_service_account.ds_federated_access.email
}

