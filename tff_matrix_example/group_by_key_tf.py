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
import numpy as np
from collections import OrderedDict

from group_by_key_lib import gather_data, count_total_func, key_list_func, cnt_func, calc_fraction_func, cleanup_func

tf.get_logger().setLevel('ERROR')

def run():
    
    dataset       = gather_data()
    total_count   = count_total_func(dataset)

    key_list      = key_list_func(dataset)
    key_list_t    = [t.numpy() for t in key_list]
    key_count     = len(key_list_t)

    print(key_count)
    print(key_list_t)

    group_by_func = tf.data.experimental.group_by_window(
                key_func=lambda x: x["KEY"],
                reduce_func=lambda key, _ds: _ds.batch(1000000),
                window_size=100000000000 )


    dataset_aggr  = dataset.apply(group_by_func).map(cnt_func).map(lambda x: calc_fraction_func(x,total_count)).map(cleanup_func)

    for group in dataset_aggr.as_numpy_iterator():
        print("{} | {} -> {} = {}".format(group["KEY"],group["SEND_BIC"],group["REC_BIC"],group["FRACTION"]))


if __name__ == "__main__":
    print("Running aggregation with pure local TF" )
    run()
