# VARS.py - final processing script for the VARS matrix, adding the motion data (pulled from the motion/data/motion_summary_data.csv file)
# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
# Last edited 3/28/20

import sys
import os
import pandas as pd

import datetime

# LOAD DATA
cwd = os.getcwd()
motion_summary_fp = os.path.join(cwd,'/data/ABCD_MBDU/goyaln2/abcd_cca_replication/data_prep/data/motion_summary_data.csv')
vars_fp = os.path.join(cwd,'/data/ABCD_MBDU/goyaln2/abcd_cca_replication/data_prep/data/VARS_no_motion.txt')
subs_fp = os.path.join(cwd,'/data/ABCD_MBDU/goyaln2/abcd_cca_replication/data_prep/data/final_subjects.txt')
sm_fp = os.path.join(cwd,'/data/ABCD_MBDU/goyaln2/abcd_cca_replication/data_prep/data/subject_measures.txt')


df_vars = pd.read_csv(vars_fp, sep=',')

final_subs = [line.rstrip('\n') for line in open(subs_fp)]
sms = [line.rstrip('\n') for line in open(sm_fp)]

df_motion_1 = pd.read_csv(motion_summary_fp, sep=',')
df_motion = df_motion_1[['sub','remaining_frame_mean_FD']]


# NOW PULL SUBJECTS FROM motion_summary_data.csv, ADD DATA TO VARS
# Make slight modification to subject names, convert NDARXXXXXX to NDAR_XXXXXXX
df_motion['sub'] = df_motion['sub'].apply(lambda x: "{}{}".format('NDAR_', x.split("NDAR")[1]))
# Drop subjects from df_motion who are NOT in final_subs
df_motion = df_motion[df_motion['sub'].isin(final_subs)]

# Merge the df_vars and df_motion
df_final = df_vars.merge(df_motion.rename(columns={'sub':'subjectid'}),on='subjectid',how='left')

# Finally, sort the rows alphabetically (ASCENDING ORDER) based on the subject ID (for future ref, since the final VARS.txt file has NO INDEX!)
df_final.sort_values('subjectid',inplace=True)
df_final = df_final[sms]
# Sort columns in descending order (so Zygosity is last)
# df_vars.sort_index(axis=1, inplace=True, ascending=False)

# Now, make some slight modifications to the zygosity fields for compatibility with hcp2blocks package
# KEY:
# Zygosity (these codings are from the sm_processing_3.r script):
#   DZ = 1
#   missing = 2
#   MZ = 3
# rel_relationship (defined in NDA, here https://nda.nih.gov/data_structure.html?short_name=acspsw03, but website is slightly wrong, correct codes are here):
#   1 = single
#   2 = non-twin sibling
#   3 = twin
#   4 = triplet

# df_final.rename(columns={'Zygosity':'Zygosity_orig'},inplace=True)
# # df_final['Zygosity']=df_final['Zygosity_orig']


# # Logic used:
# #   CASE 0: for any subjects whose 'Zygosity' field is blank, set them to 'nottwin'
#         # IF Zygosity_orig=='', then set Zygosity='nottwin'
# # mask = df_final['Zygosity_orig'].isna()
# # df_final.loc[mask,'Zygosity']='nottwin'
# # #   CASE 1: single child or regular siblings, or triplets (Note, for some reason in the ABCD dataset no one has rel_relationship=0 despite being single chilren.)
# # #       IF rel_relationship==1 | rel_relationship==2 | rel_relationship=4, then set Zygosity='nottwin'
# # mask = (df_final['rel_relationship']==1) | (df_final['rel_relationship']==2) | (df_final['rel_relationship']==4)
# # df_final.loc[mask,'Zygosity']='nottwin'
# # #   CASE 2: MZ Twins
# # #       IF rel_relationship==3 & Zygosity_orig==3, then set Zygosity='mz'
# # mask = (df_final['rel_relationship']==3) & (df_final['Zygosity_orig']==3)
# # df_final.loc[mask,'Zygosity']='mz'
# # #   CASE 3: DZ Twins
# # #       IF rel_relationship==3 & Zygosity_orig==1, then set Zygosity='nottwin'
# # mask = (df_final['rel_relationship']==3) & (df_final['Zygosity_orig']==1)
# # df_final.loc[mask,'Zygosity']='nottwin'

# #   CASE 1: Anything else is 'nottwin'
# df_final['Zygosity']='nottwin'  #this is for all other cases where the twins are not MZ.
# #   CASE 2: MZ Twins
# #       IF Zygosity_orig==3, then set Zygosity='mz'
# mask = (df_final['Zygosity_orig']==3)
# df_final.loc[mask,'Zygosity']='mz'
# # CASE 3: DZ Twins
# #       IF Zygosity_orig==1, then set Zygosity='dz'
# mask = (df_final['Zygosity_orig']==1)
# df_final.loc[mask,'Zygosity']='dz'

# df_final.drop(columns='Zygosity_orig',inplace=True)

# Now save the final .txt file
out_fp = os.path.join(cwd,'/data/ABCD_MBDU/goyaln2/abcd_cca_replication/data/VARS.csv')
df_final.to_csv(out_fp, index=False)

# Logging
fp = os.path.join(cwd,'log.txt')
f_log = open(fp, 'a')
f_log.write("--- RESULTS OF VARS_4.py ---\n")
f_log.write('%s\n' % datetime.datetime.now())
f_log.write("Final size of VARS matrix:\t%s\n".format(df_final.shape))
f_log.close()