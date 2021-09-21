# TF Federated Remote Executor

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


### Introduction

The remote executor is the generic worker that receives Federated Tasks from the TFF server. Once started, the TFF remote executor listens on a GRPC port and waits for receiving instructions for a TFF server. 

This repo contains the pieces to build a container with the TFF Executor and run it on Google Cloud Run. All these steps are executed within a Cloud Build pipeline. 


### Activate APIs
```
gcloud services enable cloudbuild.googleapis.com run.googleapis.com
```

### Run CloudBuild 
```
gcloud builds submit --config=cloudbuild.yaml 
```