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


output "service_account_email" {
  value = google_service_account.ds_service_account.email
}

output "serving_bucket_name" {
  value = google_storage_bucket.ds_bucket_serving.name
}

output "landing_bucket_name" {
  value = google_storage_bucket.ds_bucket_landing.name
}

output "serving_dataset_name" {
  value = google_bigquery_dataset.ds_dataset_serving.id
}

output "landing_dataset_name" {
  value = google_bigquery_dataset.ds_dataset_landing.id
}
