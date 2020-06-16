#!/usr/bin/python3

# motion_scan_analysis.py
# Created: 6/16/20
# Last edited:
# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020

# This script takes the motion summary (generated in prep_stage_1) and:
#   1.  Drop subjects missing any data in scan_data.csv (Subject Inclusion Criteria 2)
#   2.  Drop subjects who have less than 600 seconds of 'good' data based on the remaining_seconds field from .mat files (data derived by DCAN pipeline)
#   3.  Drop subjects missing that don't meet the QC/PC minimum requirements for scan data (at least one T1 pass PC/QC, at least 2 rsfmri pass QC/PC)
#   4.  Drop subjects with anomalous amount of motion (in upper or lower 0.25pct of motion)
#   5.  Exports filtered subject list (data_prep/data/stage_2/scan_and_motion_subjects.txt)

from find_anomalies import find_anomalies
# from plot_hist import plot_hist
import seaborn as sns
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from scipy import stats
from matplotlib import colors
from matplotlib.ticker import PercentFormatter
import os
import sys
import datetime

# Load CMD line Args and Data
# cwd = os.getcwd()
data_prep_dir = sys.argv[1]   # Abs path to abcd_cca_replication/data_prep/

# Text file with the FD values from HCP 500 (originally obtained from https://www.fmrib.ox.ac.uk/datasets/HCP-CCA/)
fp = os.path.join(data_prep_dir,'data/HCP500_rfMRI_motion.txt')
hcp_fds=np.loadtxt(fp)

# ABCD motion_summary_data.csv (abbreviated "msd")
fp = os.path.join(data_prep_dir,'data/stage_1/motion_summary_data.csv')
msd = pd.read_csv(fp, sep=',')
numeric = ['remaining_seconds','remaining_frame_mean_FD']
msd[numeric] = msd[numeric].apply(pd.to_numeric, errors='coerce')

# ABCD scan_data.txt
fp = os.path.join(data_prep_dir,'data/stage_1/scan_data.csv')
scan_data = pd.read_csv(fp, sep=',')
numeric = ['iqc_t1_good_ser','iqc_rsfmri_good_ser']
scan_data[numeric] = scan_data[numeric].apply(pd.to_numeric, errors='coerce')

# Subject list from prep_stage_1
fp = os.path.join(data_prep_dir,'data/stage_1/prep_stage_1_final_subjects.txt')
subs_1 = [line.rstrip('\n') for line in open(fp)]

# STEP 1 - Drop any subjects who are missing elementary data in scan or motion data
scan_data_1 = scan_data.dropna(axis=0,how="any")
subs = scan_data_1['subjectid']
# Drop subjects missing either the remaining_seconds or remaining_frame_mean_FD pulled from .mat files
msd_1 = msd[msd['subjectid'].isin(subs)]
msd_1 = msd_1[~np.isnan(msd_1['remaining_seconds'])]
msd_1 = msd_1[~np.isnan(msd_1['remaining_frame_mean_FD'])]
subs_1 = msd_1['subjectid']

# STEP 2 - Drop subjects with less than 600 seconds 'good' scan time
msd_2 = msd_1[(msd_1['remaining_seconds'].astype('float')>=600)]
subs_2 = msd_2['subjectid']
scan_data_2 = scan_data_1[scan_data_1['subjectid'].isin(subs_2)]

# STEP 3 - Drop subjects missing that don't meet the QC/PC minimum requirements for scan data
scan_data_3 = scan_data_2.drop(scan_data_2[ ~( (scan_data_2['iqc_t1_good_ser'] > 0) & (scan_data_2['iqc_rsfmri_good_ser'] > 1) ) ].index)
subs_3 = scan_data_3['subjectid']
msd_3 = msd_2[msd_2['subjectid'].isin(subs_3)]

# STEP 4 - Drop subjects with anomalous amount of motion (outlier detection)
abcd_fd = msd_3['remaining_frame_mean_FD'].tolist()
[anoms,upper_lim,lower_lim]=find_anomalies(abcd_fd)
msd_4 = msd_3[~msd_3['remaining_frame_mean_FD'].isin(anoms)]
subs_4 = msd_4['subjectid']
print("Upper 0.25pct motion cutoff:\t{}\nLower 0.25pct motion cutoff:\t{}\n".format(upper_lim,lower_lim))

# Output final subject list
f1=open(os.path.join(data_prep_dir,'data/stage_2/scan_and_motion_subjects.txt'),'w')
for sub in subs_4:
    f1.write(sub+'\n')
f1.close()