#! /bin/bash

# prep_stage_1.sh
# Created: 6/15/20
# Updated:

# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
# This script is the first stage in our analysis pipeline for ABCD data
# This script will do the following (in this order):
#   1.  Get a list of all available subject folders from the ABCD DCAN download (based on pointing it to the parent folding containing the subject folders)
#   2.  Crawl the directories and determine which subjects have their .mat motion files (and store these in a list)
#   3.  Run a R script to correct the naming convention in the ABCD 2.0.1 RDS file, and pull scan data (this will also reduce this file to just baseline scans)
#   4.  Pull motion data from the .mat files (using scrpt pull_motion_data.py), and acquire censor files (store in /data_prep/data/censor_files/)

# Expected inputs:
#   1.  absolute path to the parent directory containing the subject folders with raw scan data
#   2.  absolute path to the nda2.0.1.Rds (or other version?) R data structure

# Expected tools on PATH:
# R, connectome workbench

# Example usage:
#   ./prep_stage_1.sh /data/ABCD_MBDU/goyaln2/abcd_cca_replication/data_prep/data/nda2.0.1.Rds

# BIDS_PATH=$1
NDA_RDS=$1
# DERIVATES_PATH=$BIDS_PATH/derivatives/abcd-hcp-pipeline/

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
# Logging
if [[ -f $PREP_LOG ]]; then
    rm $PREP_LOG
    touch $PREP_LOG
else
    touch $PREP_LOG
fi
# Check if we have censor files directory
if [[ -d $CENSOR_FILES ]]; then
    rm -r $CENSOR_FILES
    mkdir $CENSOR_FILES
else
    mkdir $CENSOR_FILES
fi

echo "--- STAGE 1 LOG ---" >> $PREP_LOG
echo "$(date) - START" >> $PREP_LOG

# Before proceeding, make sure everything we need is present:
Rscript_exec=$(which Rscript)
 if [ ! -x "$Rscript_exec" ] ; then
    echo "Error - Rscript is not on PATH. Exiting"
    exit 1
 fi

# Check if the following folders/files exist
STAGE_1_OUT=$DATA_PREP/data/stage_1/
if [[ -d $STAGE_1_OUT ]]; then
    rm -r $STAGE_1_OUT
    mkdir $STAGE_1_OUT
else
    mkdir $STAGE_1_OUT
fi

# STEP 1 - get list of subjects that have their .mat files, store in STAGE_1_OUT folder
# find $BIDS_PATH -maxdepth 1 -type d -name "sub-NDARINV*" >> $STAGE_1_OUT/all_subjects.txt
ls $BIDS_PATH | grep sub- > $STAGE_1_OUT/all_subjects.txt
NUM_ALL_SUBS=$(cat $STAGE_1_OUT/all_subjects.txt | wc -l)

# STEP 2 - find which subjects have their .mat files
echo "$(date) - Total subjects in release: $NUM_ALL_SUBS" >> $PREP_LOG

echo "Generating a list of subjects with motion .mat files available..."
while read sub; do
    matfile=${DERIVATIVES_PATH}/${sub}/ses-baselineYear1Arm1/func/${sub}_ses-baselineYear1Arm1_task-rest_desc-filtered_motion_mask.mat
    if [[ -f "$matfile" ]]; then
        echo $matfile >> $STAGE_1_OUT/motion_mat_files.txt
        echo $sub >> $STAGE_1_OUT/subjects_with_motion_files.txt
    else
        echo $sub >> $STAGE_1_OUT/subjects_missing_files.txt
    fi
done < $STAGE_1_OUT/all_subjects.txt

NUM_MOT_SUBS=$(cat $STAGE_1_OUT/subjects_with_motion_files.txt | wc -l)
echo "$(date) - Subjects with scan and motion data present: $NUM_MOT_SUBS" >> $PREP_LOG

# STEP 3 - Get scan data
Rscript $SUPPORT_SCRIPTS/stage_1/clean_rds_pull_scandata.r $NDA_RDS $STAGE_1_OUT/subjects_with_motion_files.txt $STAGE_1_OUT

# STEP 4
# inputs, in order
#   1.  absolute path to motion_mat_files.txt
#   2.  desired FD threshold (default 0.30)
#   3.  Output path (data_prep/data/stage_1/)
#   4.  Where to save censor file data
python $SUPPORT_SCRIPTS/stage_1/pull_motion_data.py $STAGE_1_OUT/motion_mat_files.txt 0.30 $STAGE_1_OUT $CENSOR_FILES

echo "$(date) - STOP" >> $PREP_LOG
echo "--- END STAGE 1 LOG ---" >> $PREP_LOG
echo "" >> $PREP_LOG