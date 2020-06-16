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
# R

# Example usage:
# ./prep_stage_1.sh /data/ABCD_MBDU/goyaln2/abcd_cca_replication/data_prep/data/nda2.0.1.Rds

usage()
{
	echo "usage: prep_stage_1.sh <path/to/nda2.0.1.Rds/>"
    echo "NOTE you must provide the ABSOLUTE PATH to the NDA RDS file nda2.0.1.Rds (or whichever version is being used)"
}

if (( $# < 1 ))
then
    usage
	exit 1
fi

NDA_RDS=$1

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
    # Delete the files inside here
    rm $CENSOR_FILES/*.txt
else
    mkdir $CENSOR_FILES
fi

# Check if the following folders exists
STAGE_1_OUT=$DATA_PREP/data/stage_1/
if [[ -d $STAGE_1_OUT ]]; then
    rm $STAGE_1_OUT/*.txt
    rm $STAGE_1_OUT/*.csv
else
    mkdir $STAGE_1_OUT
fi

echo "--- STAGE 1 LOG ---" >> $PREP_LOG
echo "$(date) - START" >> $PREP_LOG

# Before proceeding, make sure everything we need is present:
Rscript_exec=$(which Rscript)
 if [ ! -x "$Rscript_exec" ] ; then
    echo "Error - Rscript is not on PATH. Exiting"
    exit 1
 fi


# STEP 1 - get list of subjects that have their .mat files, store in STAGE_1_OUT folder
# find $BIDS_PATH -maxdepth 1 -type d -name "sub-NDARINV*" >> $STAGE_1_OUT/all_subjects.txt
echo "$(date): Step 1 - getting list of subjects in release."
ls $BIDS_PATH | grep sub- > $STAGE_1_OUT/all_subjects.txt
NUM_ALL_SUBS=$(cat $STAGE_1_OUT/all_subjects.txt | wc -l)
echo "$(date) - Total subjects in release: $NUM_ALL_SUBS" >> $PREP_LOG

# STEP 2 - find which subjects have their .mat files
echo "$(date): Step 2 - getting list of subjects with .mat motion file."
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
echo "$(date): Step 3 - (R script) cleaning RDS file and pulling basic scan data (clean_rds_pull_scandata.r)."
echo "$(date) - calling clean_rds_pull_scandata.r" >> $PREP_LOG
Rscript $SUPPORT_SCRIPTS/stage_1/clean_rds_pull_scandata.r $NDA_RDS $STAGE_1_OUT/subjects_with_motion_files.txt $STAGE_1_OUT

NUM_MISSING=$(wc -l $STAGE_1_OUT/prep_stage_1_missing_subjects.txt)
echo "$(date): WARNING: $NUM_MISSING subjects will be dropped because they are missing from the RDS file (see $STAGE_1_OUT/prep_stage_1_missing_subjects.txt)."

echo "$(date) - WARNING: $NUM_MISSING subjects missing from RDS and dropped (see $STAGE_1_OUT/prep_stage_1_missing_subjects.txt)." >> $PREP_LOG

# STEP 4
# inputs, in order
#   1.  absolute path to motion_mat_files.txt
#   2.  desired FD threshold (default 0.30)
#   3.  Output path (data_prep/data/stage_1/)
#   4.  Where to save censor file data
echo "$(date): Step 4 - Extracting motion data for each subject (pull_motion_data.py)."
echo "$(date) - calling pull_motion_data.py" >> $PREP_LOG
python $SUPPORT_SCRIPTS/stage_1/pull_motion_data.py $STAGE_1_OUT/motion_mat_files.txt 0.30 $STAGE_1_OUT $CENSOR_FILES

FINAL_NUM=$(wc -l $STAGE_1_OUT/prep_stage_1_final_subjects.txt)
echo "$(date) - Number subjects at end of prep_stage_1: $FINAL_NUM" >> $PREP_LOG
echo "$(date) - STOP" >> $PREP_LOG
echo "--- END STAGE 1 LOG ---" >> $PREP_LOG
echo "" >> $PREP_LOG