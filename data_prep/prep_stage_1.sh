#! /bin/bash

# prep_stage_1.sh
# Created: 6/15/20
# Updated: 6/19/20 (pipeline_version_1.1)

# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
# 

# Expected tools on PATH:
# 

# Example usage:
# ./prep_stage_1.sh

# Check for config
ABCD_CCA_REPLICATION="$(dirname "$PWD")"
if [[ -f $ABCD_CCA_REPLICATION/pipeline.config ]]; then
    # config exists, so run it
    # This will load BIDS_PATH, DERIVATIVES_PATH, DATA_PREP variables
    . $ABCD_CCA_REPLICATION/pipeline.config
else
    echo "$ABCD_CCA_REPLICATION/pipeline.config does not exist! Please run create_config.sh."
    exit 1
fi

# Before proceeding, make sure everything we need is present:
# Rscript_exec=$(which Rscript)
#  if [ ! -x "$Rscript_exec" ] ; then
#     echo "Error - Rscript is not on PATH. Exiting"
#     exit 1
#  fi

CLASSIFIERS=$DATA_PREP/data/stage_1/classifiers/
if [[ -d $CLASSIFIERS ]]; then
    # Delete the files inside here
    rm $CLASSIFIERS/*.txt
    rm $CLASSIFIERS/0.2mm/*.txt
    rm $CLASSIFIERS/0.3mm/*.txt
else
    mkdir $CLASSIFIERS
    mkdir $CLASSIFIERS/0.2mm/
    mkdir $CLASSIFIERS/0.3mm/
fi

# Check if the following folders exists
STAGE_1_OUT=$DATA_PREP/data/stage_1/
if [[ -d $STAGE_1_OUT ]]; then
    rm $STAGE_1_OUT/*.txt
    rm $STAGE_1_OUT/*.csv
    rm $STAGE_1_OUT/icafix_cmds/*.txt
    rm $STAGE_1_OUT/swarm_logs/*.txt
else
    mkdir $STAGE_1_OUT
    mkdir $STAGE_1_OUT/icafix_cmds/
    mkdir $STAGE_1_OUT/swarm_logs/
fi

echo "--- STAGE 1 ---"
echo "$(date) - START"

echo "--- STAGE 1 LOG ---" >> $PREP_LOG
echo "$(date) - START" >> $PREP_LOG

# STEP 1
# Generate swarm commands
echo "$(date) - Generating .swarm file with commands for classifying scans and subjects for use."
python $SUPPORT_SCRIPTS/stage_1/stage_1_swarm_gen.py $DATA_PREP/data/stage_0/subjects_with_rsfmri.txt $ABCD_CCA_REPLICATION $SUPPORT_SCRIPTS/stage_1/subject_classifier.sh $STAGE_1_OUT

echo "$(date) - swarm file created, call with the following commands. MAKE SURE TO ACTIVATE ABCD_CCA_REPLICATION CONDA ENVIRONMENT PRIOR TO RUNNING!"
echo "          swarm -f $STAGE_1_OUT/stage_1.swarm -b 50 --logdir $STAGE_1_OUT/swarm_logs/ --job-name stage_1"

# # STEP 1 - get list of subjects that have their .mat files, store in STAGE_1_OUT folder
# # find $BIDS_PATH -maxdepth 1 -type d -name "sub-NDARINV*" >> $STAGE_1_OUT/all_subjects.txt
# echo "$(date): Step 1 - getting list of subjects in release."
# ls $BIDS_PATH | grep sub- > $STAGE_1_OUT/all_subjects.txt
# NUM_ALL_SUBS=$(cat $STAGE_1_OUT/all_subjects.txt | wc -l)
# echo "$(date) - Total subjects in release: $NUM_ALL_SUBS" >> $PREP_LOG

# # STEP 2 - find which subjects have their .mat files
# echo "$(date): Step 2 - getting list of subjects with .mat motion file."
# echo "Generating a list of subjects with motion .mat files available..."
# while read sub; do
#     matfile=${DERIVATIVES_PATH}/${sub}/ses-baselineYear1Arm1/func/${sub}_ses-baselineYear1Arm1_task-rest_desc-filtered_motion_mask.mat
#     if [[ -f "$matfile" ]]; then
#         echo $matfile >> $STAGE_1_OUT/motion_mat_files.txt
#         echo $sub >> $STAGE_1_OUT/subjects_with_motion_files.txt
#     else
#         echo $sub >> $STAGE_1_OUT/subjects_missing_files.txt
#     fi
# done < $STAGE_1_OUT/all_subjects.txt

# NUM_MOT_SUBS=$(cat $STAGE_1_OUT/subjects_with_motion_files.txt | wc -l)
# echo "$(date) - Subjects with scan and motion data present: $NUM_MOT_SUBS" >> $PREP_LOG

# # STEP 3 - Get scan data
# echo "$(date): Step 3 - (R script) cleaning RDS file and pulling basic scan data (clean_rds_pull_scandata.r)."
# echo "$(date) - calling clean_rds_pull_scandata.r" >> $PREP_LOG
# Rscript $SUPPORT_SCRIPTS/stage_1/clean_rds_pull_scandata.r $NDA_RDS $STAGE_1_OUT/subjects_with_motion_files.txt $STAGE_1_OUT

# NUM_MISSING=$(wc -l $STAGE_1_OUT/prep_stage_1_missing_subjects.txt)
# echo "$(date): WARNING: $NUM_MISSING subjects will be dropped because they are missing from the RDS file (see $STAGE_1_OUT/prep_stage_1_missing_subjects.txt)."

# echo "$(date) - WARNING: $NUM_MISSING subjects missing from RDS and dropped (see $STAGE_1_OUT/prep_stage_1_missing_subjects.txt)." >> $PREP_LOG

# # STEP 4
# # inputs, in order
# #   1.  absolute path to motion_mat_files.txt
# #   2.  desired FD threshold (default 0.30)
# #   3.  Output path (data_prep/data/stage_1/)
# #   4.  Where to save censor file data
# echo "$(date): Step 4 - Extracting motion data for each subject (pull_motion_data.py)."
# echo "$(date) - calling pull_motion_data.py" >> $PREP_LOG
# python $SUPPORT_SCRIPTS/stage_1/pull_motion_data.py $STAGE_1_OUT/motion_mat_files.txt 0.30 $STAGE_1_OUT $CENSOR_FILES

# FINAL_NUM=$(wc -l $STAGE_1_OUT/prep_stage_1_final_subjects.txt)
# echo "$(date) - Number subjects at end of prep_stage_1: $FINAL_NUM" >> $PREP_LOG


echo "$(date) - STOP" >> $PREP_LOG
echo "--- END STAGE 1 LOG ---" >> $PREP_LOG
echo "" >> $PREP_LOG