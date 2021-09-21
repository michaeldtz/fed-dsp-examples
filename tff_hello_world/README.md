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

This python program is a little "hello world" alike example for TFF. It performs a federated computation of sums. Therefore it creates locally, at the federated nodes computes, a range of integers, sums it up and then creates a federated sum across all participants.  

It is build to run with a tff executor that is deployed on Cloud Run. For that it automatically gathers the URL and gets a token for Authentication. 


### Preparation
This example was tested (and runs most stable) with the following versions:
- Python 3.7.7.
- TensorFlow 2.5.1
- TensorFlow Federated 0.19.0

In order to prepare your python environment you can leverage the requirements.txt to install these dependencies. 

### Run
If you have a different name for your Cloud Run service or something else is different you might need to adapt the python code. If not, then just run:

```
python tff_sum_of_sums.py
```


