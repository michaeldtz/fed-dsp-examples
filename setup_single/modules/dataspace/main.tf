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

data "google_project" "project" {
  project_id = var.project_id
}

locals {
  service_account      = "${var.service_account_prefix}-${var.dataspace_id}"

  bucket_name_serving  = "${var.bucket_prefix}-${var.dataspace_id}-${var.serving_suffix}-${var.project_id}"
  bucket_name_landing  = "${var.bucket_prefix}-${var.dataspace_id}-${var.landing_suffix}-${var.project_id}"
  dataset_name_serving = "${var.dataset_prefix}_${var.dataspace_id}_${var.serving_suffix}"
  dataset_name_landing = "${var.dataset_prefix}_${var.dataspace_id}_${var.landing_suffix}"

  bq_serviceaccount    = "serviceAccount:bq-${data.google_project.project.number}@bigquery-encryption.iam.gserviceaccount.com"
  gcs_serviceaccount   = "serviceAccount:service-${data.google_project.project.number}@gs-project-accounts.iam.gserviceaccount.com"
}

resource "google_service_account" "ds_service_account" {
  account_id   = local.service_account
  display_name = "ServiceAccount for Dataspace ${var.dataspace_id}"
}


   
resource "google_kms_crypto_key_iam_binding" "crypto_key_access" {
    count           = var.use_custom_key ? 1 : 0
    crypto_key_id   = var.custom_key_id
    role            = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

    members = [
      local.bq_serviceaccount,
      local.gcs_serviceaccount,
    ]
}


# The Landing Bucket

resource "google_storage_bucket" "ds_bucket_landing" {
  name          = local.bucket_name_landing
  location      = var.location
  force_destroy = true  
  
  dynamic "encryption" {
    for_each = google_kms_crypto_key_iam_binding.crypto_key_access
    content {
        default_kms_key_name = encryption.value.crypto_key_id
    }
  }
  uniform_bucket_level_access = false
}

resource "google_storage_bucket_iam_binding" "owner_at_landing" {
  bucket = google_storage_bucket.ds_bucket_landing.name
  role = var.owner_role
  members = [
    "serviceAccount:${google_service_account.ds_service_account.email}",
  ]
}


# The Serving Bucket

resource "google_storage_bucket" "ds_bucket_serving" {
  name          = local.bucket_name_serving
  location      = var.location
  force_destroy = true

  dynamic "encryption" {
    for_each =  google_kms_crypto_key_iam_binding.crypto_key_access
    content {
      default_kms_key_name = encryption.value.crypto_key_id
    }
  }

  uniform_bucket_level_access = false
}

resource "google_storage_bucket_iam_binding" "owner_at_serving" {
  bucket = google_storage_bucket.ds_bucket_serving.name
  role = var.owner_role
  members = [
    "serviceAccount:${google_service_account.ds_service_account.email}",
  ]
}

resource "google_storage_bucket_iam_binding" "fed_access_at_serving" {
  bucket = google_storage_bucket.ds_bucket_serving.name
  role = var.reader_role
  members = [
    "serviceAccount:${var.fed_access_sa}",
  ]
}



# The BigQuery Landing Dataset

resource "google_bigquery_dataset" "ds_dataset_landing" {
  dataset_id                  = local.dataset_name_landing
  friendly_name               = "Landing Dataset for Dataspace ${var.dataspace_id}"
  location                    = var.location

  dynamic "default_encryption_configuration" {
    for_each =  google_kms_crypto_key_iam_binding.crypto_key_access
    content {
      kms_key_name = default_encryption_configuration.value.crypto_key_id
    }
  }

  labels = {
    type = "dataspace_landing"
  }


  access {
    role          = "OWNER"
    user_by_email = google_service_account.ds_service_account.email
  }

}



# The BigQuery Dataset Serving

resource "google_bigquery_dataset" "ds_dataset_serving" {
  dataset_id                  = local.dataset_name_serving
  friendly_name               = "Serving Dataset for Dataspace ${var.dataspace_id}"
  location                    = var.location

  dynamic "default_encryption_configuration" {
    for_each =  google_kms_crypto_key_iam_binding.crypto_key_access
    content {
      kms_key_name = default_encryption_configuration.value.crypto_key_id
    }
  }

  labels = {
    type = "dataspace_serving"
  }


  access {
    role          = "OWNER"
    user_by_email = google_service_account.ds_service_account.email
  }

  access {
    role          = var.reader_role
    user_by_email = var.fed_access_sa
  }

}





