# classify_scans.py
#   this code will classify a subject's scans as usable or unusable based on length, and length after censoring
# Created: 6/13/20
# Last edited: 6/13/20
# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020

# Argument 1: subjectid in format (NDARINVxxxxxxxx)
# Argument 2: absolute path to file containing scan lengths for a subject
# Argument 3: absolute path to the output location (NDARINVxxxxxxxx_scans_classified.txt)

import sys
import os
import pandas as pd
import datetime

# Load data
sub             =   sys.argv[1]
fp_lens         =   sys.argv[2]
fp_class_out    =   sys.argv[3]
fp_censored_lens=   sys.argv[4]
fp_cens_out     =   os.path.join(cwd,"censoring_data_subset/"+sub+"_censor.txt")
fp_censor       =   os.path.join(cwd,"censoring_data/"+sub+"_censor.txt")

# open the censored len file
# This file will have lengths for all scans, but post censoring
censored_len_out = open(fp_censored_lens,"w")

if (os.path.exists(fp_censor) & os.path.exists(fp_lens)):
    # If the censor file and lengths files exist, proceed
    censor = [line.rstrip('\n') for line in open(fp_censor)]
    censor = [int(i) for i in censor]

    # scan lengths
    scan_lengths = [line.rstrip('\n') for line in open(fp_lens)]
    scan_lengths = [int(i) for i in scan_lengths]

    # Now, for scans > 285 tps, iterate over scans to generate a list of their individual lengths once timepoints are removed
    # Save the subsetted censor
    classifier=[]
    agg_censor=[]
    scan_num=1
    running_idx=0
    total_good_length=0
    for length in scan_lengths:
        stop_idx = running_idx+length
        censor_subset=censor[running_idx:stop_idx]
        running_idx=stop_idx

        # Now count how long scan will be (count number of zeroes in this censor segment)
        post_censor_length=censor_subset.count(0)
        censored_len_out.write(post_censor_length)

        if post_censor_length >= 285:
            # Sufficient length run
            total_good_length=total_good_length+post_censor_length
            agg_censor.extend(censor_subset)
            classifier.append(1)
            continue
        else:
            # Run too short
            classifier.append(0)
            continue
        
        scan_num+=1
    
    # Write the classifier results
    with open(fp_class_out, "w") as output:
        for item in classifier:
            output.write('%s\n' % item)

    # Save the subsetted censor
    with open(fp_cens_out, "w") as output:
        for item in agg_censor:
            output.write('%s\n' % item)

else:
    print("ERROR: missing either censor file or lengths file for subject {}. Skipping subject!".format(sub))
    sys.exit(0)

censored_len_out.close()

# Successful code run, now return a code for whether or not this subject is usable
if total_good_length >= 600:
    # Subject is good to use
    sys.exit(1)
elif total_good_length < 600:
    # Subject has too little time
    sys.exit(2)
else
    # something went wrong
    sys.exit(0)