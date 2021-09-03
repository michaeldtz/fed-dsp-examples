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

import tensorflow_federated as tff
import h5py
import numpy as np

SPLITS = [5,25,25,25,10,10]
SPLIT_NAME = ["dev","trn_1","trn_2","trn_3","tst","val"]

def open_new_file(idx):
    outfile = open("fed_emnist_dataset_" + SPLIT_NAME[idx] + ".csv","w")
    outfile.write("label" )
    for i in range(784):
        outfile.write("," + str(i))
    outfile.write("\n")
    return outfile

def get_split_and_save_fedemnist_data():

    output_fmt = ["%i"]
    output_fmt.extend(["%f" for i in range(784)])

    tff.simulation.datasets.emnist.load_data(cache_dir="./")
    trainFile = h5py.File('datasets/fed_emnist_digitsonly_train.h5', 'r')
    dataset = trainFile["examples"]
 
    datalen = len(dataset)
    splitsum = sum(SPLITS)
    split_idx = 0
    split_end = SPLITS[split_idx]
    outfile = open_new_file(split_idx)
    
    for i,key in enumerate(dataset):

        if i > (datalen / splitsum) * split_end:
            split_idx += 1
            split_end += SPLITS[split_idx]
            outfile.close()
            outfile = open_new_file(split_idx)

        group = dataset[key]        
        reshapedLabels = np.reshape(group["label"], (-1,1))
        reshapedPixels = np.reshape(group["pixels"], (-1,784))
        output_data = np.concatenate((reshapedLabels,reshapedPixels),axis=1)
        
        np.savetxt(outfile, X=output_data, fmt=output_fmt, delimiter=",")        

    outfile.close()

if __name__ == "__main__":
    get_split_and_save_fedemnist_data()