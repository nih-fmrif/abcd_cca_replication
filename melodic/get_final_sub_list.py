# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
# This script is ran after motion_analysis.py, and sm_analysis.py, which determine which subjects to include in the final analysis.
# This script will then create a txt file of the absolute paths to the NIFTI files we want to feed into MELODIC group-ICA.

import pandas as pd
import numpy as np
import os
import sys

cwd = os.getcwd()

nifti_fp = sys.argv[1]  # path to mat_files.txt
subs_fp = sys.argv[2]   # path to list of final subjects (in abcd_cca_replication/data/motion_filtered_subjects.txt)

NIFTI = [line.rstrip('\n') for line in open(nifti_fp)]
subs = [line.rstrip('\n') for line in open(subs_fp)]

ica_NIFTI_files=[]
for fp in NIFTI:
    if(any(substring in fp for substring in subs)):
        ica_NIFTI_files.append(fp)

if( len(ica_NIFTI_files) == len(subs) ):
    print("Writing final list of NIFTI files for use in group-ICA to ./data/ica_NIFTI_files.txt")
    f=open('data/ica_NIFTI_files.txt','w')

    for ele in ica_NIFTI_files:
        f.write(ele+'\n')
    
    f.close()
else:
    print("ERROR: number of NIFTI files is not equal to number of subjects to be included. Exiting.")