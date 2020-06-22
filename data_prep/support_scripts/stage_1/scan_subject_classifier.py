#!/usr/bin/python3

# motion_scan_subject_classifier.py
# Created: 6/19/20 (pipeline_version_1.1)
# Last edited:
# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020

# Inputs
#   1.  subject id (format sub-NDARINVxxxxxxxx)
#   2.  absolute path to subject pre-censor scan lengths
#   3.  absolute path to subject post-censor scan lengths
#   4.  absolute path to file containing paths to a subjects motion.tsv files
#   5.  absolute patht to where to save subject classifier for the given scan_fd_thresh
#   6.  absolute path where to save the subject mean fd across scans for the given scan_fd_thresh
#   7.  minimium tps needed for scan to pass pre-censor length requirement
#   8.  the fd threshold for scan-level classification/exclusion

# To use this script for different FD threshold levels, you simply pass it the input path to the post-censor 0.3mm length file, and specify its output file as /classifiers/0.3mm/sub-NDARINVxxxxxxxx.txt (and similar for 0.2mm threshold) 

import sys
import os
import numpy as np
import pandas as pd
import datetime

def Average(lst):
    return (sum(lst)/len(lst))

def calc_fd(motion_tsv):
    mot = pd.read_csv(motion_tsv, sep='\t+', engine='python')
    derv_col = ['XDt', 'YDt', 'ZDt', 'RotXDt', 'RotYDt', 'RotZDt']
    derv = mot[derv_col].abs()
    motion_val = derv.sum(axis=1).mean()
    return motion_val

sub                     =   sys.argv[1]
pre_censor_lengths_fp   =   sys.argv[2]
post_censor_lengths_fp  =   sys.argv[3]
tsv_files_fp            =   sys.argv[4]
classifier_output_fp    =   sys.argv[5]
subject_mean_fd_outp_fp =   sys.argv[6]
min_tps                 =   int(sys.argv[7])
scan_fd_thresh          =   float(sys.argv[8])

# load pre- and post-censor scan lengths
pre_censor_lengths = [line.rstrip('\n') for line in open(pre_censor_lengths_fp)]
pre_censor_lengths = [int(i) for i in pre_censor_lengths]
post_censor_lengths = [line.rstrip('\n') for line in open(post_censor_lengths_fp)]
post_censor_lengths = [int(i) for i in post_censor_lengths]
tsv_files   =   [line.rstrip('\n') for line in open(tsv_files_fp)]

classifier=[]
motion_vals=[]
total_post_censor_len=0
for pre_len,post_len,tsv in zip(pre_censor_lengths,post_censor_lengths,tsv_files):
    if pre_len >= min_tps:
        scan_fd = calc_fd(tsv)

        if scan_fd <= scan_fd_thresh:
            # scan motion passes
            motion_vals.append(scan_fd)
            classifier.append(1)
            total_post_censor_len+=post_len
        else:
            # scan has too much motion, drop the scan
            classifier.append(0)

    else:
        # scan does not meet minimum pre-censor length, drop the scan
        classifier.append(0)
        continue

# Write the classifier data to file
with open(classifier_output_fp, "w") as output:
    for item in classifier:
        output.write('%s\n' % item)

# Write the average fd to file (for the given scan_fd_thresh) (if any scans passed)
try:
    avg_fd = Average(motion_vals)
    with open(subject_mean_fd_outp_fp, "a") as output:
        output.write('{},{}\n'.format(sub, avg_fd))
except ZeroDivisionError as err:
    print("Subject had no valid scans for scan fd threshold of {}".format(scan_fd_thresh))
    sys.exit(202)

# Return code to parent shell script for decision making (based on total good scan length)
if total_post_censor_len >= 750:
    # subject can proceed in pipeline
    sys.exit(101)
elif total_post_censor_len < 750:
    # drop subject
    sys.exit(202)
else:
    # something went wrong, throw an error and store this subject id
    sys.exit(303)