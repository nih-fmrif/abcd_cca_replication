#!/usr/bin/python3

# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
# This script is used to pull the mean frame displacement (along with other fields) for subjects for a given FD threshold
# It also generates a histogram of frame displacements

# sub-<NDAR ID>_ses-baselineYear1Arm1_task-rest_desc-filtered_motion_mask.mat

from helper_functions import mat_files
import numpy as np
import matplotlib.pyplot as plt
from matplotlib import colors
from matplotlib.ticker import PercentFormatter
import os
import sys

cwd = os.getcwd()

filepath = sys.argv[1]      # path to mat_files.txt (a text file with a list of paths to .mat files)
FD = float(sys.argv[2])     # frame displacement threshold of interest (ex. 0.xx) (range 0.00 to 0.50)

fp = os.path.join(cwd,'data/motion_summary_data.csv')
fout1 = open(fp, 'a')
fout1.write("sub,total_frame_count,remaining_frame_count,remaining_seconds,remaining_frame_mean_FD\n")

fp = os.path.join(cwd,'data/mean_FDs.txt')
fout2 = open('data/mean_FDs.txt','a')    # just the mean FD data

print("Pulling motion data, please be patient..\n")
i=1
file_list = [line.rstrip('\n') for line in open(filepath)]
for fp in file_list:
    print(i)
    mat_contents = mat_files.loadmat(fp)        # load the .mat file (Version 5.0)
    motion_data = mat_contents['motion_data']   # array of mat_struct objects, need to iterate over them

    for struct in motion_data:
        # Now we can access the data like a matlab structure
        if struct.FD_threshold == FD:
            # found the correct structure
            sub = fp.split('/')[-1].split('_')[0].split('-')[-1]
            # pull the subject id from each filepath
            # ex. path/to/the/sub-<NDAR_ID>_ses-baselineYear1Arm1_task-rest_desc-filtered_motion_mask.mat
            # this extracts just <NDAR_ID>

            print_str = '{},{},{},{},{}\n'.format(
                                            sub,
                                            struct.total_frame_count, 
                                            struct.remaining_frame_count, 
                                            struct.remaining_seconds,
                                            struct.remaining_frame_mean_FD)
            fout1.write(print_str)
            fout2.write('{}\n'.format(struct.remaining_frame_mean_FD))
        else:
            continue
    
    i+=1

fout1.close()
fout2.close()