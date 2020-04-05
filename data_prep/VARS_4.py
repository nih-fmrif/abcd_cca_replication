# VARS.py - final processing script for the VARS matrix, adding the motion data (pulled from the motion/data/motion_summary_data.csv file)
# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
# Last edited 3/28/20

import sys
import os
import pandas as pd

import datetime

# LOAD DATA
cwd = os.getcwd()
motion_summary_fp = os.path.join(cwd,'./data/motion_summary_data.csv')
vars_fp = os.path.join(cwd,'./data/VARS_no_motion.txt')
subs_fp = os.path.join(cwd,'./data/final_subjects.txt')


df_vars = pd.read_csv(vars_fp, sep=',')

final_subs = [line.rstrip('\n') for line in open(subs_fp)]

df_motion_1 = pd.read_csv(motion_summary_fp, sep=',')
df_motion = df_motion_1[['sub','remaining_frame_mean_FD']]


# NOW PULL SUBJECTS FROM motion_summary_data.csv, ADD DATA TO VARS
# Make slight modification to subject names, convert NDARXXXXXX to NDAR_XXXXXXX
df_motion['sub'] = df_motion['sub'].apply(lambda x: "{}{}".format('NDAR_', x.split("NDAR")[1]))
# Drop subjects from df_motion who are NOT in final_subs
df_motion = df_motion[df_motion['sub'].isin(final_subs)]

# Merge the df_vars and df_motion
df_vars.merge(df_motion.rename(columns={'sub':'subjectid'}),on='subjectid',how='left')

# Finally, sort the rows alphabetically (ASCENDING ORDER) based on the subject ID (for future ref, since the final VARS.txt file has NO INDEX!)
df_vars.sort_values('subjectid',inplace=True)
# Sort columns in descending order (so Zygosity is last)
df_vars.sort_index(axis=1, inplace=True, ascending=False)

# Now save the final .txt file
out_fp = os.path.join(cwd,'../data/VARS.txt')
df_vars.to_csv(out_fp, index=False)

# Logging
fp = os.path.join(cwd,'log.txt')
f_log = open(fp, 'a')
f_log.write("--- RESULTS OF VARS_4.py ---\n")
f_log.write('%s\n' % datetime.datetime.now())
f_log.write("Final size of VARS matrix:\t%s\n".format(df_vars.shape()))
f_log.close()