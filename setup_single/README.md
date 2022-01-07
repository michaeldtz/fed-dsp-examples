# Setup via Infrastructure as Code using Terraform 

    Copyright 2021 Google LLC

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

     https://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
    

This is a repo that contains everything for a Infra-as-Code approach to bring a federated dataspace example setup to GCP. It uses Terraform for the desired state management and cloud build to centrally execute the infra configuration changes. 

# Preparation
Execute the following steps to be ready to use this infra-as-code approach.

### Project ID
```
PROJECT_ID=$(gcloud config get-value project)
```

### Activate the necessary APIs
The following APIs are being used and can be enabled via the gcloud call below. 
- Cloud Resource Manager
- IAM, KMS 
- CloudBuild 
- BQ, GCS 

```
gcloud services enable cloudresourcemanager.googleapis.com iam.googleapis.com \
iamcredentials.googleapis.com cloudkms.googleapis.com cloudbuild.googleapis.com \
bigquery.googleapis.com, bigquerystorage.googleapis.com storage.googleapis.com
```

# GCS Bucket for TF State 
Create the bucket for storing the TF state using TF backend
```
gsutil mb gs://tfstate-${PROJECT_ID}
gsutil versioning set on gs://tfstate-${PROJECT_ID}
```

# Prepare the Cloud Build Service Account
Authenticate the CloudBuild Service Account. If there is an issue that the cloud build service account doesn't exist, please visit the UI of CloudBuild. 
```
CLOUDBUILD_SA="$(gcloud projects describe $PROJECT_ID --format 'value(projectNumber)')@cloudbuild.gserviceaccount.com"
gcloud projects add-iam-policy-binding $PROJECT_ID --member serviceAccount:$CLOUDBUILD_SA --role roles/iam.serviceAccountAdmin
gcloud projects add-iam-policy-binding $PROJECT_ID --member serviceAccount:$CLOUDBUILD_SA --role roles/iam.roleAdmin
gcloud projects add-iam-policy-binding $PROJECT_ID --member serviceAccount:$CLOUDBUILD_SA --role roles/cloudkms.admin
gcloud projects add-iam-policy-binding $PROJECT_ID --member serviceAccount:$CLOUDBUILD_SA --role roles/cloudbuild.builds.builder
gcloud projects add-iam-policy-binding $PROJECT_ID --member serviceAccount:$CLOUDBUILD_SA --role roles/bigquery.admin
gcloud projects add-iam-policy-binding $PROJECT_ID --member serviceAccount:$CLOUDBUILD_SA --role roles/storage.admin
gcloud projects add-iam-policy-binding $PROJECT_ID --member serviceAccount:$CLOUDBUILD_SA --role roles/resourcemanager.projectIamAdmin
```

## Key Creation (Optional)
This step is optional. For a proper example it is fully ok to not activate this setting. 
If you want to use custom keys per dataspace then these keys need to be created separately. There are also TF scripts for that but they have to be run upfront. 
You can find everything needed in the subfolder custom_key_setup. In there change all occurances of SET_PROJECT_ID with the project id you are working with.
```
cd custom_key_setup
sed -i s/SET_PROJECT_ID/$PROJECT_ID/g terraform.tfvars
sed -i s/SET_PROJECT_ID/$PROJECT_ID/g backend.tf
terraform init
terraform apply
```

## Deploy the Dataspace Setup 
There are two options for deploying this TF setup. Either you run it locally or you leverage CloudBuild for it.
The easier option is via CloudBuild as everything is prepared for that. Go and check in the code into a CSR or connect the github repository and use the cloudbuild.yaml as configuration. 

Alternatively, you can also deploy from your local machine by running these commands (make sure you are not in the custom key folder anymore): 
```
sed -i s/SET_PROJECT_ID/$PROJECT_ID/g terraform.tfvars
sed -i s/SET_PROJECT_ID/$PROJECT_ID/g backend.tf
terraform init
terraform apply
```

