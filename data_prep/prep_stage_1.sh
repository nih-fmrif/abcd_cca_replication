#! /bin/bash

# prep_stage_1.sh
# Created: 6/15/20
# Updated:

# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
# This script is the first stage in our analysis pipeline for ABCD data
# This script will do the following (in this order):
#   1.  Run a R script to correct the naming convention in the ABCD 2.0.1 RDS file, pull scan data(this will also reduce this file to just baseline scans)
#   2.  Pull a list of all available subject folders from the ABCD DCAN download (based on pointing it to the parent folding containing the subject folders)
#   3.  Crawl the directories and determine which subjects have their .mat motion files (and store these in a list)
#   4.  Extract subject motion data
#   5.  

# Expected inputs:
#   1.  absolute path to the parent directory containing the subject folders with raw scan data
#   2.  absolute path to the nda2.0.1.Rds (or other version?) R data structure

# Expected tools on PATH:
# R, connectome workbench

# Example usage:
#   ./prep_stage_1.sh /data/ABCD_MBDU/abcd_bids/bids/ /data/ABCD_MBDU/goyaln2/abcd_cca_replication/data_prep/data/nda2.0.1.Rds

BIDS_PATH=$1
NDA_RDS=$2

# Before proceeding, make sure everything we need is present:
Rscript_exec=$(which Rscript)
 if [ ! -x "$Rscript_exec" ] ; then
    echo "Error - Rscript is not on PATH. Exiting"
    exit 1
 fi

# Check if the following folders/files exist
STAGE_1_OUT=$PWD/data/stage_1/
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

echo "Generating a list of subjects with motion .mat files available..."
while read sub; do

    matfile=${BIDS_PATH}/derivatives/abcd-hcp-pipeline/${sub}/ses-baselineYear1Arm1/func/${sub}_ses-baselineYear1Arm1_task-rest_desc-filtered_motion_mask.mat
    
    if [[ -f "$matfile" ]]; then
        echo $matfile >> $STAGE_1_OUT/motion_mat_files.txt
        echo $sub >> $STAGE_1_OUT/subjects_with_motion_files.txt
    else
        echo $sub >> $STAGE_1_OUT/subjects_missing_files.txt
    fi
    
done < $STAGE_1_OUT/all_subjects.txt

NUM_MOT_SUBS=$(cat $STAGE_1_OUT/subjects_with_motion_files.txt | wc -l)

# STEP ? - change the naming convention in the RDS file from NDAR_INVxxxxxxxx to sub-NDARINVxxxxxxxx
# $Rscript_exec $PWD/support_scripts/stage_1/clean_rds_pull_scandata.r $NDA_RDS $STAGE_1_OUT/subjects_with_motion_files.txt $PWD/data/subject_measures.txt

# STEP 2
