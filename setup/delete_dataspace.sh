#! /bin/bash
export DATA_SPACE_ID=$1

export PROJECT_ID=$(gcloud config list --format 'value(core.project)')
export PROJECT_NUMBER=$(gcloud projects describe "${PROJECT_ID}" --format "value(projectNumber)")

export LOCATION=europe-west3
export SA_NAME_PREFIX=dataspace-sa
export KEYRING_PREFIX=dataspace-keyring
export KEY_PREFIX=dataspace-key
export BUCKET_PREFIX=dataspace

export BUCKET_SILO_SUFFIX=silo--${PROJECT_ID}
export BUCKET_LAND_SUFFIX=land--${PROJECT_ID}

export DATASET_PREFIX=dataspace_dataset

echo "Deleting data space with id $1"

# Delete BQ Dataset
bq --location=$LOCATION rm -r -f ${PROJECT_ID}.${DATASET_PREFIX}_${DATA_SPACE_ID}

# Delete bucket
gsutil rm -r gs://${BUCKET_PREFIX}-${DATA_SPACE_ID}-${BUCKET_LAND_SUFFIX}
gsutil rm -r gs://${BUCKET_PREFIX}-${DATA_SPACE_ID}-${BUCKET_SILO_SUFFIX}

# Delete key and key ring
#gcloud kms keys versions destroy 1 --key ${KEY_PREFIX}-${DATA_SPACE_ID} --keyring=${KEYRING_PREFIX}-${DATA_SPACE_ID} --location=$LOCATION
echo "You need to manually destroy the keys. Keep them if you need them in the future"

# Delete service account
gcloud iam service-accounts delete ${SA_NAME_PREFIX}-${DATA_SPACE_ID}@${PROJECT_ID}.iam.gserviceaccount.com -q




