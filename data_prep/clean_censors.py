# clean_censors.py
#   this code will cut out the relevant censoring points from a subject's motion censoring file, based on which of their scans are utilized in ICA+FIX
# Created: 6/9/20
# Last edited: 6/11/20
# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020

# Argument: list of subjects in format NDARINVxxxxxxx (This must be provided on an ABSOLUTE PATH!)

import sys
import os
import pandas as pd
import datetime

# Load data
subs_fp=sys.argv[1]
cwd = os.getcwd()

# format of each line in text file is NDARINVxxxxxxx on each line (need to drop the sub- prefix)
subs = [line.rstrip('\n') for line in open(subs_fp)]
failed_subs = []
# For each subject, we need to do the following:
# 1. Load their NDARINVxxxxxxx_scans_classified.txt and NDARINVxxxxxxx_scan_lengths.txt files
# 2. Determine which scans to use, and based on that, cut the needed subset of censoring points from the censor file.
for sub in subs:
    # Make sure all files are present, otherwise throw an error
    fp_censor       = os.path.join(cwd,"censoring_data/"+sub+"_censor.txt")
    fp_scan_class   = os.path.join(cwd,"data/scan_length_proc/"+sub+"_scans_classified.txt")
    fp_lens         = os.path.join(cwd,"data/scan_length_proc/"+sub+"_scan_lengths.txt")

    if (os.path.exists(fp_censor) & os.path.exists(fp_scan_class) & os.path.exists(fp_lens)):
        # load their NDARINVA354YMUE_censor.txt file
        censor = [line.rstrip('\n') for line in open(fp_censor)]
        censor = [int(i) for i in censor]

        # which scans to use
        scans = [line.rstrip('\n') for line in open(fp_scan_class)]
        scans = [int(i) for i in scans]

        # scan lengths
        scan_lengths = [line.rstrip('\n') for line in open(fp_lens)]
        scan_lengths = [int(i) for i in scan_lengths]

        running_idx=0
        censor_subset=[]
        # Make sure that the scans and scan_lengths files have same number of lines (otherwise something is wrong)
        if len(scans) == len(scan_lengths):
            # Okay to proceed, we have data we need
            for scan,length in zip(scans,scan_lengths):
                # print(scan,length)
                if scan == 0:
                    # Skip this scan
                    running_idx+=length
                    continue
                else:
                    # Use this scan
                    stop_idx = running_idx+length
                    censor_subset.extend(censor[running_idx:stop_idx])
                    running_idx=stop_idx

            # Save the subsetted censor
            with open(os.path.join(cwd,"censoring_data_subset/"+sub+"_censor_subset.txt"), "w") as output:
                for item in censor_subset:
                    output.write('%s\n' % item)

        else:
            print("ERROR: {}_scans_to_use.txt and {}_scan_lengths.txt files have different number of lines! Skipping this subject.\n".format(sub,sub))
            failed_subs.append()
            continue

    else:
        # Not all files are present
        print("ERROR, not all files are present for subject {}. Skipping this subject!.\n".format(sub))
        failed_subs.append()
        continue

if len(failed_subs) > 0:
    print("WARNING: Subjects whose censor files couldn't be edited:\n")
    print(failed_subs)
else:
    print("Done! All subject censors successfully edited.\n")
