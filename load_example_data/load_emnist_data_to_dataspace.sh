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

#! /bin/bash

export DATA_SPACE_ID=$1
export FILE_NUM=$2

export PROJECT_ID=$(gcloud config list --format 'value(core.project)')
export PROJECT_NUMBER=$(gcloud projects describe "${PROJECT_ID}" --format "value(projectNumber)")

export LOCATION=europe-west3

export BUCKET_PREFIX=dataspace
export DATASET_PREFIX=dataspace

export SERVING_SUFFIX=serving


gsutil cp fed_emnist_dataset_trn_$FILE_NUM.csv gs://${BUCKET_PREFIX}-${DATA_SPACE_ID}-${SERVING_SUFFIX}-${PROJECT_ID}/emnist_train.csv

bq --location=$LOCATION load \
--autodetect --replace --source_format=CSV \
${PROJECT_ID}:${DATASET_PREFIX}_${DATA_SPACE_ID}_${SERVING_SUFFIX}.emnist_train \
gs://${BUCKET_PREFIX}-${DATA_SPACE_ID}-${SERVING_SUFFIX}/emnist_train.csv

