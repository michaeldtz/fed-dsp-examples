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

import tensorflow as tf
import tensorflow_federated as tff
import numpy as np
import nest_asyncio
nest_asyncio.apply()

from collections import OrderedDict

from group_by_key_lib import gather_data, key_list_func

def run():

  dataset       = gather_data("1")
  key_list      = key_list_func(dataset)
  key_list_t    = [t.numpy() for t in key_list]

  @tf.function
  def count_by_key(ds):
    
    key_size = len(key_list_t)
    idx_list = tf.range(key_size, dtype=tf.int64)
    key_lookup = tf.lookup.StaticHashTable(
        tf.lookup.KeyValueTensorInitializer(key_list_t, idx_list),
        default_value=-1)

    
    @tf.function
    def _count_keys(acummulator, values):    
      indices = key_lookup.lookup(values["KEY"])
      onehot = tf.one_hot(indices, depth=tf.cast(key_size, tf.int32), dtype=tf.int32)
      return acummulator + onehot

    return ds.reduce(
        initial_state=tf.zeros([key_size], tf.int32),
        reduce_func=_count_keys)
 
  @tff.federated_computation(tff.FederatedType(tf.string, tff.CLIENTS))
  def federated_group_agg(id):

    # wrap the used function into tff computations
    tff_gather_data_func = tff.tf_computation(gather_data, tf.string)
    
    # Derive the dataset type from the gather function
    tff_dataset_type = tff_gather_data_func.type_signature.result # tff.SequenceType(OrderedDict([('TRANS_ID', tf.string), ('SEND_BIC', tf.int64), ('REC_BIC', tf.int64), ('KEY', tf.int64)]))

    # continue to wrap functions
    tff_count_by_key     = tff.tf_computation(count_by_key, tff_dataset_type)
    tff_key_list_func    = tff.tf_computation(key_list_func, tff_dataset_type)
    
    # print out type signature (for dev purposes)
    print(tff_gather_data_func.type_signature)  
    print(tff_count_by_key.type_signature)    
    print(tff_key_list_func.type_signature)   

    # Get dataset on client side 
    tff_client_dataset = tff.federated_map(tff_gather_data_func, id)
  
    # Calculate the aggregates per client
    client_aggregates = tff.federated_map(tff_count_by_key, tff_client_dataset)

    # Start to build the aggregation function

    @tff.tf_computation()
    def build_zeros():
      key_size = len(key_list_t)
      return tf.zeros([key_size], tf.int32)
    
    @tff.tf_computation(build_zeros.type_signature.result,build_zeros.type_signature.result)
    def accumulate(accum, delta):
      return accum + delta

    @tff.tf_computation(accumulate.type_signature.result)
    def report(accum):
      return tf.convert_to_tensor(key_list_t), accum
    
    aggregate = tff.federated_aggregate(
        value=client_aggregates,
        zero=build_zeros(),
        accumulate=accumulate,
        merge=accumulate,
        report=report,
    )

    # Second one to print out type signatures (for dev purposes)
    print(build_zeros.type_signature)  # ( -> int32[key_size])
    print(accumulate.type_signature)  # (<int32[key_size],int32[key_size]> -> int32[key_size])
    print(report.type_signature)  # (int32[key_size] -> <string[K],int32[]>)
    print(aggregate.type_signature) 

    return aggregate


  ## Now execute the federated
  result = federated_group_agg(["1","2"])
  print(result)



if __name__ == "__main__":
    print("Running this in federated mode" )
    run()
