# Load Federated EMNIST Example Data

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


This little tool helps to download the federated EMNIST dataset via the TFF API and then splits the dataset into 5 parts (configurable in the python script)
In a second script the data is loaded into a dataspace by copying it to GCS and then load a table in BigQuery. 

### Step 1: Get Datasets and Split
```
pip -r requirements.txt
python get_and_split_fed_emnist_data.py
```

### Step 2: Load Datasets into the three dataspaces d1,d2,d3
```
./load_emnist_data_to_dataspace.sh d1 1
./load_emnist_data_to_dataspace.sh d2 2
./load_emnist_data_to_dataspace.sh d3 3
```