# Group By Example for TF and TFF

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


## About

This folder contains example coding that shows how a group by aggregation with a count can be realized in pure TF and then TFF leveraging TF functions and TFF computations. These special annotations lead to a serializability of the tensorflow code to make it independent and portable.

## Preparation

Install the necessary python dependencies with pip
```
pip install -r requirements.txt
```

## Run the TF (without TFF) Example

```
python group_by_key_tf.py
```

## Run the TFF (TF Federated) Example

```
python group_by_key_tff.py
```