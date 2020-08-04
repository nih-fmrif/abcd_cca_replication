# VARS.py - final processing script for the VARS matrix, adding the motion data (pulled from the motion/data/motion_summary_data.csv file)
# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
# Last edited 3/28/20


import sys
import os
import pandas as pd
import datetime

# sub_fp          =   "/data/ABCD_MBDU/goyaln2/abcd_cca_replication/data_prep//data/stage_3//final_subjects.txt"
# sm_fp           =   "/data/ABCD_MBDU/goyaln2/abcd_cca_replication/data_prep//data/stage_2//final_subject_measures.txt"
# motion_data     =   "/data/ABCD_MBDU/goyaln2/abcd_cca_replication/data_prep//data/stage_2//subjects_mean_fds.txt"
# vars_txt        =   "/data/ABCD_MBDU/goyaln2/abcd_cca_replication/data_prep//data/stage_2//VARS_no_motion.txt"
# out_folder      =   "/data/ABCD_MBDU/goyaln2/abcd_cca_replication/data//5013/"

# LOAD DATA
sub_fp      =   sys.argv[1]
sm_fp       =   sys.argv[2]
motion_data =   sys.argv[3]
vars_txt    =   sys.argv[4]
out_folder      =   sys.argv[5]

final_subs = [line.rstrip('\n') for line in open(sub_fp)]
sms = [line.rstrip('\n') for line in open(sm_fp)]

# Keep only subjects from the data_prep/data/stage_3/final_subjects.txt list
df_vars = pd.read_csv(vars_txt, sep=',')
df_vars = df_vars[df_vars['subjectid'].isin(final_subs)]

# STEP 1 - Properly code the scanner type variable (since it is not binary)
# Our encoding scheme will require n-1 columns (i.e. 4 cols if there are 5 unique scanners)
# # This is required to properly deconfound

# First, convert any NaNs to "nan" string (otherwise this wont encode properly)
df_vars['mri_info_device.serial.number'] = df_vars['mri_info_device.serial.number'].fillna('nan')
# Get number of unique scanners
num_unique_scanners = df_vars['mri_info_device.serial.number'].nunique(dropna=False)
# Get list of unique scanner hashes
unique_scanners = list(df_vars['mri_info_device.serial.number'].unique().astype(str))
unique_scanners.sort()

# Folder to write our our confound column names
scanner_cols_file = open("{}/scanner_confounds.txt".format(out_folder),'a')

# Perform the encoding
for i in range(0,num_unique_scanners-1,1):
    type_i = unique_scanners[i]
    type_iplus1 = unique_scanners[i+1]
    new_col_name = "scanners_{}_{}".format(type_i, type_iplus1)
    # Also save these column names to a file, makes it easier to generate our confounds later in the matlab CCA script
    scanner_cols_file.write('%s\n' % new_col_name)
    # Define new col for these scanners, initialize to 0
    df_vars[new_col_name] = 0
    # Now set values for 1 if scanner type == type_i, -1 if scanner type == type_iplus1
    df_vars.loc[df_vars['mri_info_device.serial.number'] == type_i, new_col_name] = 1
    df_vars.loc[df_vars['mri_info_device.serial.number'] == type_iplus1, new_col_name] = -1

scanner_cols_file.close()

df_motion = pd.read_csv(motion_data, sep=',')
# Extract the appropriate subjects from the motion file
df_motion = df_motion[df_motion['subjectid'].isin(final_subs)]

# Merge the df_vars and df_motion
df_final = df_vars.merge(df_motion,on='subjectid',how='left')

# Finally, sort the rows alphabetically (ASCENDING ORDER) based on the subject ID (for future ref, since the final VARS.txt file has NO INDEX!)
# This will sort subject id A-->Z and row index 0-->N
df_final.sort_values('subjectid',inplace=True)
# df_final = df_final[sms]
# Sort columns in descending order (so Zygosity is last)
df_final.sort_index(axis=1, inplace=True, ascending=False)

# Now save the final .txt file
df_final.to_csv("{}/VARS.txt".format(out_folder), index=False)