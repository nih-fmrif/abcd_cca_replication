# VARS.py - final processing script for the VARS matrix, adding the motion data (pulled from the motion/data/motion_summary_data.csv file)
# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
# Last edited 3/28/20

import sys
import os
import pandas as pd
import datetime

# LOAD DATA

sub_fp      =   sys.argv[1]
sm_fp       =   sys.argv[2]
motion_data =   sys.argv[3]
vars_txt    =   sys.argv[4]
out_fp      =   sys.argv[5]

df_vars = pd.read_csv(vars_txt, sep=',')

final_subs = [line.rstrip('\n') for line in open(sub_fp)]
sms = [line.rstrip('\n') for line in open(sm_fp)]

df_motion = pd.read_csv(motion_data, sep=',')
# Extract the appropriate subjects from the motion file
df_motion = df_motion[df_motion['subjectid'].isin(final_subs)]

# Merge the df_vars and df_motion
df_final = df_vars.merge(df_motion,on='subjectid',how='left')

# Finally, sort the rows alphabetically (ASCENDING ORDER) based on the subject ID (for future ref, since the final VARS.txt file has NO INDEX!)
df_final.sort_values('subjectid',inplace=True)
df_final = df_final[sms]
# Sort columns in descending order (so Zygosity is last)
df_vars.sort_index(axis=1, inplace=True, ascending=False)

# Now save the final .txt file
df_final.to_csv(out_fp, index=False)