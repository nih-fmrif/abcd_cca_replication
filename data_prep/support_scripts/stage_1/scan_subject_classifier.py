#!/usr/bin/python3

# motion_scan_subject_classifier.py
# Created: 6/19/20 (pipeline_version_1.1)
# Last edited:
# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020

# Inputs
#   1.  absolute path to subject pre-censor scan lengths
#   2.  absolute path to subject post-censor scan lengths
#   3.  absolute path to output file
#   4.  minimum TPS number

# To use this script for different FD threshold levels, you simply pass it the input path to the post-censor 0.3mm length file, and specify its output file as /classifiers/0.3mm/sub-NDARINVxxxxxxxx.txt (and similar for 0.2mm threshold) 

import sys
import os
import numpy as np
import pandas as pd
import datetime

pre_censor_lengths_fp   =   sys.argv[1]
post_censor_lengths_fp  =   sys.argv[2]
output_fp               =   sys.argv[3]
min_tps                 =   int(sys.argv[4])

# load pre- and post-censor scan lengths
pre_censor_lengths = [line.rstrip('\n') for line in open(pre_censor_lengths_fp)]
pre_censor_lengths = [int(i) for i in pre_censor_lengths]
post_censor_lengths = [line.rstrip('\n') for line in open(post_censor_lengths_fp)]
post_censor_lengths = [int(i) for i in post_censor_lengths]

classifier=[]
total_post_censor_len=0
for pre_len,post_len in zip(pre_censor_lengths,post_censor_lengths):
    if pre_len >= min_tps:
        total_post_censor_len+=post_len
        classifier.append(1)
    else:
        classifier.append(0)

# Write the classifier data to file
with open(output_fp, "w") as output:
    for item in classifier:
        output.write('%s\n' % item)

# Return code to parent shell script for decision making
if total_post_censor_len >= 750:
    # subject can proceed in pipeline
    sys.exit(1)
elif total_post_censor_len < 750:
    # drop subject
    sys.exit(2)
else:
    # something went wrong, throw an error and store this subject id
    sys.exit(0)