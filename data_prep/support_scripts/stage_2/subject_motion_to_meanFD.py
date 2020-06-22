#!/usr/bin/python3

# subject_motion_to_meanFD.py
# Created: 6/16/20
# Last edited:
# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020

import pandas as pd
import numpy as np
import sys

def Average(lst):
    return sum(lst) / len(lst)

def calc_fd(motion_list,censor_path):
    mot     =   pd.read_csv(motion_list, sep='\t+', engine='python')
    censor  =   [line.rstrip('\n') for line in open(censor_path)]
    censor  =   [int(i) for i in censor]
    # Get indices of the 0s in the censor (1 = include frame, 0 = exclude frame)
    drop_idxs   =   [i for i, x in enumerate(censor) if x == 0]
    derv_col = ['XDt', 'YDt', 'ZDt', 'RotXDt', 'RotYDt', 'RotZDt']
    derv = mot[derv_col].abs()
    derv = derv.drop(derv.index[drop_idxs])
    motion_val = round(np.mean(derv.mean())/len(derv_col),6)
    return motion_val

sub                     =   sys.argv[1]
scan_classifier         =   sys.argv[2]
subject_tsv_files       =   sys.argv[3]
subject_censor_files    =   sys.argv[4]
outfile                 =   sys.argv[5]

classifier      =   [line.rstrip('\n') for line in open(scan_classifier)]
classifier      =   [int(i) for i in classifier]
tsv_files       =   [line.rstrip('\n') for line in open(subject_tsv_files)]
censor_files    =   [line.rstrip('\n') for line in open(subject_censor_files)]

motion_vals=[]
for scan_class,tsv,censor in zip(classifier,tsv_files,censor):
    if scan_class == 1:
        scan_fd = calc_fd(tsv,censor)
        motion_vals.append(scan_fd)
    else:
        continue

avg_fd = Average(motion_vals)

with open(outfile, "w") as output:
    output.write('{},{}\n'.format(sub, avg_fd))