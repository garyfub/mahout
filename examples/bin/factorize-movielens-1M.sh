#!/bin/bash
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Instructions:
#
# Before using this script, you have to download and extract the Movielens 1M dataset
# from http://www.grouplens.org/node/73
#
# To run:  change into the mahout directory and type:
#  examples/bin/factorize-movielens-1M.sh /path/to/ratings.dat

if [ $# -ne 1 ]
then
  echo -e "\nYou have to download the Movielens 1M dataset from http://www.grouplens.org/node/73 before"
  echo -e "you can run this example. After that extract it and supply the path to the ratings.dat file.\n"
  echo -e "Syntax: $0 /path/to/ratings.dat\n"
  exit -1
fi

WORK_DIR=/tmp/mahout-work-${USER}
echo "creating work directory at ${WORK_DIR}"
mkdir -p ${WORK_DIR}/movielens

echo "Converting ratings..."
cat $1 |sed -e s/::/,/g| cut -d, -f1,2,3 > ${WORK_DIR}/movielens/ratings.csv

#create a 90% percent training set and a 10% probe set
bin/mahout splitDataset --input ${WORK_DIR}/movielens/ratings.csv --output ${WORK_DIR}/dataset \
    --trainingPercentage 0.9 --probePercentage 0.1 --tempDir ${WORK_DIR}/dataset/tmp

#run distributed ALS-WR to factorize the rating matrix based on the training set
bin/mahout parallelALS --input ${WORK_DIR}/dataset/trainingSet/ --output ${WORK_DIR}/als/out \
    --tempDir ${WORK_DIR}/als/tmp --numFeatures 20 --numIterations 10 --lambda 0.065

# compute predictions against the probe set, measure the error
bin/mahout evaluateFactorizationParallel --output ${WORK_DIR}/als/rmse --pairs ${WORK_DIR}/dataset/probeSet/ \
    --userFeatures ${WORK_DIR}/als/out/U/ --itemFeatures ${WORK_DIR}/als/out/M/

# print the error
echo -e "\nRMSE is:\n"
cat ${WORK_DIR}/als/rmse/rmse.txt
echo -e "\n\n"

echo "removing work directory"
rm -rf ${WORK_DIR}