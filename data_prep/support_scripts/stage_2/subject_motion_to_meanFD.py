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

def calc_fd(file):
    mot = pd.read_csv(file, sep='\t+', engine='python')
    derv_col = ['XDt', 'YDt', 'ZDt', 'RotXDt', 'RotYDt', 'RotZDt']
    derv = mot[derv_col].abs()
    motion_val = round(np.mean(derv.mean())/len(derv_col),6)
    return motion_val

sub                 =   sys.argv[1]
scan_classifier     =   sys.argv[2]
subject_tsv_files   =   sys.argv[3]
outfile             =   sys.argv[4]

classifier = [line.rstrip('\n') for line in open(scan_classifier)]
classifier = [int(i) for i in classifier]
tsv_files = [line.rstrip('\n') for line in open(subject_tsv_files)]

motion_vals=[]
for scan_class,tsv in zip(classifier,tsv_files):
    if scan_class == 1:
        scan_fd = calc_fd(tsv)
        motion_vals.append(scan_fd)
    else:
        continue

avg_fd = Average(motion_vals)

with open(outfile, "a") as output:
    output.write('{},{}\n'.format(sub, avg_fd))