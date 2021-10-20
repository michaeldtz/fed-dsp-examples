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
from collections import OrderedDict


@tf.function
def convert_to_dict_func(*x):
    dic = OrderedDict(zip(["TRANS_ID", "SEND_BIC", "REC_BIC", "AMOUNT"],x))
    return dic

@tf.function
def compute_key_func(x):
  new_x = x.copy()
  new_x["KEY"] =  tf.math.add( tf.math.multiply(x["SEND_BIC"], 1000000000), x["REC_BIC"])
  return new_x

@tf.function
def cnt_func(x_group):
  new_x_group = x_group.copy()
  new_x_group["COUNT"] = tf.math.count_nonzero(x_group["TRANS_ID"])
  return new_x_group

@tf.function
def calc_fraction_func(x_group, divider):
  new_x_group = x_group.copy()
  new_x_group["FRACTION"] = x_group["COUNT"] / divider
  return new_x_group

@tf.function
def cleanup_func(x_group):
  new_x_group             = x_group.copy()
  new_x_group["KEY"]      = x_group["KEY"][0]
  new_x_group["SEND_BIC"] = x_group["SEND_BIC"][0]
  new_x_group["REC_BIC"]  = x_group["REC_BIC"][0]

  del new_x_group["TRANS_ID"]
  del new_x_group["AMOUNT"]
  del new_x_group["COUNT"]  

  return new_x_group

@tf.function
def count_total_func(ds):
  return ds.reduce(tf.constant(0,dtype=tf.int64), lambda s,x: s + 1)

@tf.function
def key_list_func(ds):
  return ds.map(lambda x: x["KEY"]).apply(tf.data.experimental.unique())

@tf.function
def key_count_func(ds):
  return ds.map(lambda x: x["KEY"]).apply(tf.data.experimental.unique()).reduce(tf.constant(0,dtype=tf.int64), lambda s,x: s + 1)


@tf.function
def gather_data():
    filename = tf.constant("test_data.csv")
    ds       = tf.data.experimental.CsvDataset("test_data.csv", record_defaults=[tf.string,tf.int64,tf.int64,tf.float32], header=True)

    return ds.map(convert_to_dict_func).map(compute_key_func)

