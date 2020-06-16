#!/usr/bin/python3

# classify_scans_get_lens_clean_censors.py
# Created: 6/16/20
# Last edited:
# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020

# Argument 1: subjectid in format (NDARINVxxxxxxxx)
# Argument 2: absolute path to file containing scan lengths for a subject
# Argument 3: absolute path to the output location (NDARINVxxxxxxxx_scans_classified.txt)

import sys
import os
import pandas as pd
import datetime

# ARGS
sub                 =   sys.argv[1]     # subjectid
# INPUT FILES
fp_lens             =   sys.argv[2]     # path to a subject's sub-NDARINVxxxxxxxx_scan_length.txt file
fp_censor           =   sys.argv[3]     # path to a subjects data_prep/censor_files/sub-NDARINVxxxxxxxx_censor.txt file
# OUTPUT
fp_class_out        =   sys.argv[4]     # filepath where to save the classified scans (data_prep/data/stage_2/scan_length_analyze_classify/sub-NDARINVxxxxxxxx_scans_classified.txt)
fp_censored_lens    =   sys.argv[5]     # filepath where to save the post-censor scan legths (data_prep/data/stage_2/scan_length_analyze_classify/sub-NDARINVxxxxxxxx_censored_scan_lengths.txt)
fp_censor_clean     =   sys.argv[6]     # filepath where to save a subject's final, clean censor file (data_prep/censor_files_clean/sub-NDARINVxxxxxxxx_censor.txt)

if (os.path.exists(fp_censor) & os.path.exists(fp_lens)):
    # If the censor file and lengths files exist, proceed

    # Open file where we save post-censoring lengths
    post_censor_len_file = open(fp_censored_lens,"w")

    censor = [line.rstrip('\n') for line in open(fp_censor)]
    censor = [int(i) for i in censor]

    # scan lengths
    scan_lengths = [line.rstrip('\n') for line in open(fp_lens)]
    scan_lengths = [int(i) for i in scan_lengths]

    classifier=[]       # list, stores 0 or 1 for each scan (in order of scans)
    agg_censor=[]       # aggregated censor list (used to output the final clean censor)
    scan_num=1          # scan idx
    running_idx=0       # idx for censor
    total_good_length=0 # sum up total good scan length, used to determine if subject include or exclude

    # Iterate over scan lengths for sub
    for length in scan_lengths:

        # Pull out censor data for this particular scan
        stop_idx = running_idx+length
        censor_subset=censor[running_idx:stop_idx]
        running_idx=stop_idx

        # Now count number of post-censor timepoints (count number of zeroes in this censor segment)
        # This is TIMEPOINTS, not TIME
        post_censor_length=censor_subset.count(0)
        # save the post-censor length of this scan
        post_censor_len_file.write(post_censor_length)

        if post_censor_length >= 285:
            # Sufficient length run
            total_good_length=total_good_length+post_censor_length
            # save this censor component
            agg_censor.extend(censor_subset)
            # classify scan as pass
            classifier.append(1)
            continue
        else:
            # Run too short, won't use censor or length data
            # classify scan as fail
            classifier.append(0)
            continue
        
        scan_num+=1
    
    # Write the classifier results
    with open(fp_class_out, "w") as output:
        for item in classifier:
            output.write('%s\n' % item)

    # Save the subsetted censor
    with open(fp_censor_clean, "w") as output:
        for item in agg_censor:
            output.write('%s\n' % item)

else:
    print("ERROR: missing either censor file or lengths file for subject {}. Skipping subject!".format(sub))
    sys.exit(0)

post_censor_len_file.close()

# Successful code run, now return a code for whether or not this subject is usable
# Note, use 750 tps since tr=0.8s (750tps == 600sec = 10 min)
if total_good_length >= 750:
    # Subject is good to use
    sys.exit(1)
elif total_good_length < 750:
    # Subject has too little time
    sys.exit(2)
else:
    # something else went wrong
    sys.exit(0)