#!/usr/bin/python3

# pull_motion_data.py
# Created: 6/15/20
# Updated:

# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
# This script is used to pull the mean frame displacement (along with other fields) for subjects for a given FD threshold
# Please note that this script expects a .mat file with version 5.0, and MAY NOT WORK OTHERWISE!

# We pull motion data from these files:
# sub-<NDAR ID>_ses-baselineYear1Arm1_task-rest_desc-filtered_motion_mask.mat

from custom_loadmat import custom_loadmat
import numpy as np
import os
import sys
import scipy.io as spio
import datetime

# cwd = os.getcwd()
# path to mat_files.txt (a text file with a list of paths to .mat files)
motion_mat_files_fp = sys.argv[1]
# frame displacement threshold of interest (ex. 0.xx) (range 0.00 to 0.50)
FD = float(sys.argv[2])
out_path = sys.argv[3]
censor_folder = sys.argv[4]

fp = os.path.join(out_path,"motion_summary_data.csv")
fout1 = open(fp, 'a')
fout1.write("subjectid,total_frame_count,remaining_frame_count,remaining_seconds,remaining_frame_mean_FD\n")

# just the mean FD data
fp = os.path.join(out_path,'mean_FDs.txt')
fout2 = open(fp,'a')    

print("Pulling motion data, please be patient..")
i=0
file_list = [line.rstrip('\n') for line in open(motion_mat_files_fp)]

for fp in file_list:
    mat_contents = custom_loadmat(fp)           # load the .mat file (Version 5.0)
    motion_data = mat_contents['motion_data']   # array of mat_struct objects, need to iterate over them

    for struct in motion_data:
        # Now we can access the data like a matlab structure
        if struct.FD_threshold == FD:
            # found the correct structure for FD threshold
            # pull the subject id from each filepath
            # ex. path/to/the/sub-NDARINVxxxxxxxx_ses-baselineYear1Arm1_task-rest_desc-filtered_motion_mask.mat
            # this extracts sub-NDARINVxxxxxxxx
            sub = fp.split('/')[-1].split('_')[0]
            print_str = '{},{},{},{},{}\n'.format(sub, struct.total_frame_count, struct.remaining_frame_count, struct.remaining_seconds, struct.remaining_frame_mean_FD)
            fout1.write(print_str)
            fout2.write('{}\n'.format(struct.remaining_frame_mean_FD))

            # Finally, save the censoring data for this subject
            # data is in struct.frame_removal
            censor_out = os.path.join(censor_folder,sub+"_censor.txt")
            np.savetxt(censor_out, list(struct.frame_removal), fmt="%d")

        else:
            continue
    
    i+=1

print("Finished extracting data for %d subjects.\n" % i)

fout1.close()
fout2.close()