export LOCATION=europe-west3

export PROJECT_ID=$(gcloud config list --format 'value(core.project)')
export PROJECT_NUMBER=$(gcloud projects describe "${PROJECT_ID}" --format "value(projectNumber)")

export FEDERATED_ACCESS_SA_NAME=dataspace-federated-access-sa
export FEDERATED_COMPUTE_SA_NAME=dataspace-federated-compute-sa
export DATASPACE_ADMIN_SA_NAME=dataspace-admin-sa

export FEDERATION_BUCKET=dataspace-federation--${PROJECT_ID}
export WORKENV_BUCKET=dataspace-workenv--${PROJECT_ID}
export FEDERATION_DATASET=dataspace_federation
export WORKENV_DATASET=dataspace_workenv

gcloud iam roles create dataspace_admin            --project=${PROJECT_ID} --file="roles/dataspace-admin-role.yaml"
gcloud iam roles create dataspace_owner            --project=${PROJECT_ID} --file="roles/dataspace-owner-role.yaml"
gcloud iam roles create dataspace_federated_reader --project=${PROJECT_ID} --file="roles/dataspace-federated-reader-role.yaml"
gcloud iam roles create dataspace_federated_writer --project=${PROJECT_ID} --file="roles/dataspace-federated-writer-role.yaml"

gcloud iam service-accounts create ${FEDERATED_ACCESS_SA_NAME}
gcloud iam service-accounts create ${FEDERATED_COMPUTE_SA_NAME}
gcloud iam service-accounts create ${DATASPACE_ADMIN_SA_NAME}

# Give federated access service account right accross project
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
     --member="serviceAccount:${FEDERATED_ACCESS_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
     --role="projects/${PROJECT_ID}/roles/dataspace_federated_reader"

# Give admin service account right accross project
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
     --member="serviceAccount:${DATASPACE_ADMIN_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
     --role="projects/${PROJECT_ID}/roles/dataspace_admin"

# Federation Bucket
gsutil mb -p $PROJECT_ID -l $LOCATION gs://${FEDERATION_BUCKET}
# writer for fed-access
gsutil iam ch serviceAccount:${FEDERATED_ACCESS_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com:projects/${PROJECT_ID}/roles/dataspace_federated_writer gs://${FEDERATION_BUCKET}
# reader for fed-compute
gsutil iam ch serviceAccount:${FEDERATED_COMPUTE_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com:projects/${PROJECT_ID}/roles/dataspace_federated_reader gs://${FEDERATION_BUCKET}

# WorkEnv Bucket
gsutil mb -p $PROJECT_ID -l $LOCATION gs://${WORKENV_BUCKET}
# writer for fed-compute
gsutil iam ch serviceAccount:${FEDERATED_COMPUTE_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com:projects/${PROJECT_ID}/roles/dataspace_federated_writer gs://${WORKENV_BUCKET}

bq --location=$LOCATION mk ${PROJECT_ID}:${FEDERATION_DATASET}
bq --location=$LOCATION query --use_legacy_sql=false  \
'GRANT `projects/'${PROJECT_ID}'/roles/dataspace_federated_writer` ON SCHEMA `'${PROJECT_ID}.${FEDERATION_DATASET}'` TO "serviceAccount:'${FEDERATED_ACCESS_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com'"'
bq --location=$LOCATION query --use_legacy_sql=false  \
'GRANT `projects/'${PROJECT_ID}'/roles/dataspace_federated_reader` ON SCHEMA `'${PROJECT_ID}.${FEDERATION_DATASET}'` TO "serviceAccount:'${FEDERATED_COMPUTE_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com'"'

bq --location=$LOCATION mk ${PROJECT_ID}:${WORKENV_DATASET}
bq --location=$LOCATION query --use_legacy_sql=false  \
'GRANT `projects/'${PROJECT_ID}'/roles/dataspace_federated_writer` ON SCHEMA `'${PROJECT_ID}.${WORKENV_DATASET}'` TO "serviceAccount:'${FEDERATED_COMPUTE_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com'"'
