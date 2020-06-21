#!/usr/bin/python3

# motion_exclusion.py
# Created: 6/21/20 (pipeline_version_1.3)
# Last edited:
# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020

# Inputs:
#   absolute path to file:              /data/stage_3/subjects_mean_fds.txt
#   absolute path to output folder:     /data/stage_3/

import os
import sys
import pandas as pd
import numpy as np
from find_anomalies import find_anomalies

motion_file_fp  =   sys.argv[1]
output_folder   =   sys.argv[2]

# STEP 0 - Load motion file
motion = pd.read_csv(motion_file_fp, sep=',')
motion['mean_fd'] = motion['mean_fd'].apply(pd.to_numeric, errors='coerce')

# STEP 1 - Find subjects whose average FD is anomalous in overall distribution
fds = motion['mean_fd'].tolist()
[anoms,upper_lim,lower_lim]=find_anomalies(fds)
motion_clean = motion[~motion['mean_fd'].isin(anoms)]

final_subjects = motion_clean['subjectid']

print("Number subjects after dropping those excessive motion: {}".format(len(final_subjects)))
print("Upper 0.25pct motion cutoff:\t{}\nLower 0.25pct motion cutoff:\t{}\n".format(upper_lim,lower_lim))

f1=open(os.path.join(output_folder,'motion_filtered_subjects.txt'),'w')
for sub in final_subjects:
    f1.write(sub+'\n')
f1.close()