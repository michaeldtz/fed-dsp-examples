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
    description = "Id of the workarea and setup project"
}

variable "fedarea_project_id" {
    description = "Id of the federation area project"
}

variable "dataspace_project_id_prefix" {
    description = "Prefix for the dataspace projects"
}

variable "location" {
    description = "Location of Dataspace"
    type        = string
}

variable "federation_name" {
    description = "Temporary Data Federation Bucket"
    type        = string
    default     = "federation-dataarea"
}

variable "workenv_name" {
    description = "Work Data Federation Bucket"
    type        = string
    default     = "federation-workarea"
}

variable "used_keyring_prefix" {
    description = "Keyring Name Prefix"
    type        = string
    default     = "dataspace-keyring"
}

variable "used_key_prefix" {
    description = "Key Name Prefix"
    type        = string
    default     = "dataspace-key"
}