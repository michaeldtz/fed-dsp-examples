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

variable "project_id" {
    description = "Project ID"
    type        = string
}

variable "dataspace_id" {
    description = "Dataspace ID"
    type        = string
}

variable "service_account_prefix" {
    description = "Dataspace Service Account Prefix"
    type        = string
    default     = "dataspace-sa"
}

variable "use_custom_key" {
    default = false
}

variable "custom_key_id" {
    description = "Existing custom key id /projects/..."
    type        = string
    default     = null    
}



variable "location" {
    description = "Location of Dataspace"
    type        = string
}

variable "bucket_prefix" {
    description = "Prefix for Dataspace Buckets"
    type        = string
    default     = "dataspace"
}


variable "dataset_prefix" {
    description = "Prefix for Dataspace Dataset"
    type        = string
    default     = "dataspace"
}

variable "serving_suffix" {
    description = "Suffix for Serving"
    type        = string
    default     = "serving"
}

variable "landing_suffix" {
    description = "Suffix for Landing"
    type        = string
    default     = "landing"
}


variable "owner_role" {
    description = "Owner role"
    type        = string
}

variable "reader_role" {
    description = "Reader role"
    type        = string
}

variable "fed_access_sa" {
    description = "Federated Access Service Account"
    type        = string
}




