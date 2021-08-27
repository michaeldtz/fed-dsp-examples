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



echo "Creating data space with id $1"

# Create service account
gcloud iam service-accounts create ${SA_NAME_PREFIX}-${DATA_SPACE_ID}

# Create key and key ring
gcloud kms keyrings create ${KEYRING_PREFIX}-${DATA_SPACE_ID} --location=$LOCATION
gcloud kms keys create ${KEY_PREFIX}-${DATA_SPACE_ID} --keyring=${KEYRING_PREFIX}-${DATA_SPACE_ID} --location=$LOCATION --purpose=encryption
#gcloud kms keys set-rotation-schedule ${KEY_PREFIX}-${DATA_SPACE_ID} --keyring=${KEYRING_PREFIX}-${DATA_SPACE_ID} --location=$LOCATION --rotation-period=30d
#gcloud kms keys versions create --key ${KEY_PREFIX}-${DATA_SPACE_ID} --keyring=${KEYRING_PREFIX}-${DATA_SPACE_ID} --location=$LOCATION --primary

# Give Key acces rights to service users
gcloud kms keys add-iam-policy-binding \
 --project=$PROJECT_ID \
 --member "serviceAccount:bq-${PROJECT_NUMBER}@bigquery-encryption.iam.gserviceaccount.com" \
 --role roles/cloudkms.cryptoKeyEncrypterDecrypter \
 --location=$LOCATION \
 --keyring="projects/${PROJECT_ID}/locations/${LOCATION}/keyRings/${KEYRING_PREFIX}-${DATA_SPACE_ID}" \
 projects/${PROJECT_ID}/locations/${LOCATION}/keyRings/${KEYRING_PREFIX}-${DATA_SPACE_ID}/cryptoKeys/${KEY_PREFIX}-${DATA_SPACE_ID}

gcloud kms keys add-iam-policy-binding \
 --project=$PROJECT_ID \
 --member "serviceAccount:service-${PROJECT_NUMBER}@gs-project-accounts.iam.gserviceaccount.com" \
 --role roles/cloudkms.cryptoKeyEncrypterDecrypter \
 --location=$LOCATION \
 --keyring="projects/${PROJECT_ID}/locations/${LOCATION}/keyRings/${KEYRING_PREFIX}-${DATA_SPACE_ID}" \
 projects/${PROJECT_ID}/locations/${LOCATION}/keyRings/${KEYRING_PREFIX}-${DATA_SPACE_ID}/cryptoKeys/${KEY_PREFIX}-${DATA_SPACE_ID}

# Create bucket and assign cmek
gsutil mb -p $PROJECT_ID -l $LOCATION gs://${BUCKET_PREFIX}-${DATA_SPACE_ID}-${BUCKET_SILO_SUFFIX}
gsutil kms encryption -k projects/${PROJECT_ID}/locations/${LOCATION}/keyRings/${KEYRING_PREFIX}-${DATA_SPACE_ID}/cryptoKeys/${KEY_PREFIX}-${DATA_SPACE_ID} gs://${BUCKET_PREFIX}-${DATA_SPACE_ID}-${BUCKET_SILO_SUFFIX}
gsutil mb -p $PROJECT_ID -l $LOCATION gs://${BUCKET_PREFIX}-${DATA_SPACE_ID}-${BUCKET_LAND_SUFFIX}
gsutil kms encryption -k projects/${PROJECT_ID}/locations/${LOCATION}/keyRings/${KEYRING_PREFIX}-${DATA_SPACE_ID}/cryptoKeys/${KEY_PREFIX}-${DATA_SPACE_ID} gs://${BUCKET_PREFIX}-${DATA_SPACE_ID}-${BUCKET_LAND_SUFFIX}

# Assign service account user
gsutil iam ch serviceAccount:${SA_NAME_PREFIX}-${DATA_SPACE_ID}@${PROJECT_ID}.iam.gserviceaccount.com:projects/${PROJECT_ID}/roles/dataspace_owner gs://${BUCKET_PREFIX}-${DATA_SPACE_ID}-${BUCKET_LAND_SUFFIX}
gsutil iam ch serviceAccount:${SA_NAME_PREFIX}-${DATA_SPACE_ID}@${PROJECT_ID}.iam.gserviceaccount.com:projects/${PROJECT_ID}/roles/dataspace_owner gs://${BUCKET_PREFIX}-${DATA_SPACE_ID}-${BUCKET_SILO_SUFFIX}

# Create BQ Dataset
bq --location=$LOCATION mk --default_kms_key projects/${PROJECT_ID}/locations/${LOCATION}/keyRings/${KEYRING_PREFIX}-${DATA_SPACE_ID}/cryptoKeys/${KEY_PREFIX}-${DATA_SPACE_ID} ${PROJECT_ID}:${DATASET_PREFIX}_${DATA_SPACE_ID}
bq --location=$LOCATION query --use_legacy_sql=false  \
'GRANT `projects/'${PROJECT_ID}'/roles/dataspace_owner` ON SCHEMA `'${PROJECT_ID}.${DATASET_PREFIX}_${DATA_SPACE_ID}'` TO "serviceAccount:'${SA_NAME_PREFIX}-${DATA_SPACE_ID}@${PROJECT_ID}.iam.gserviceaccount.com'"'
