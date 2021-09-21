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
# 
# This is a simplest TFF program that performs a federated computation of sums. 
# It defines a program that locally at the federated nodes computes a range, sums it 
# and then created a federated sum across all participants.  
#
#

import grpc
import subprocess

import tensorflow as tf
import tensorflow_federated as tff
import numpy as np

import nest_asyncio
nest_asyncio.apply()

#tf.get_logger().setLevel('ERROR')

# This is the TFF style code that will run on the clients

@tff.tf_computation(tf.int64)
def make_data(n):
  return tf.data.Dataset.range(n)

@tff.tf_computation(tff.SequenceType(tf.int64))
def sum_data(dataset):
  return dataset.reduce(np.int64(0), lambda x, y: x + y)

@tff.federated_computation(tff.FederatedType(tf.int64, tff.CLIENTS))
def compute_local_sum(federated_n):
 dataset   = tff.federated_map(make_data, federated_n)
 local_sum = tff.federated_map(sum_data, dataset)
 return local_sum

@tff.federated_computation(tff.FederatedType(tf.int64, tff.CLIENTS))
def compute_federated_sum(federated_n):
 return tff.federated_sum(compute_local_sum(federated_n))

# END OF: TFF style code that will run on the clients

def set_local_execution():
  tff.backends.native.set_local_execution_context()

def set_remote_execution(service_url, token):

  scc = grpc.ssl_channel_credentials()
  tok = grpc.access_token_call_credentials(token)
  ccc = grpc.composite_channel_credentials(scc, tok)

  channels = [grpc.secure_channel(service_url + ":443",credentials=ccc)]

  tff.backends.native.set_remote_execution_context(channels, default_num_clients=1)


def run_federated():
  # Get the url
  service_url = subprocess.getoutput("gcloud run services describe tff-executor-federation --platform managed --region=europe-west3 --format 'value(status.url)'")
  service_url = service_url.replace("https://","")
  print("i: Execution federation against TFF Executor on CloudRun: " + service_url)

  # Get a token for authentication against cloudrun
  token = subprocess.getoutput("gcloud auth print-identity-token")

  # Set remote execution context
  set_remote_execution(service_url, token)
  
  # Run federated function. This is starting the real federation
  result = compute_federated_sum([7])

  # Print result
  print(result)

# MAIN
if __name__ == '__main__':
  run_federated()   
