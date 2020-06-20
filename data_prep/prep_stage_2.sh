#! /bin/bash

# prep_stage_2.sh
# Created: 6/16/20
# Updated: 6/20/20 (pipeline_version_1.2)

# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020

# Expected tools on PATH:
# R

# Example usage:
#   ./prep_stage_2.sh

# usage()
# {
# 	echo "usage: prep_stage_2.sh <path/to/nda2.0.1.Rds/>"
#     echo "NOTE you must provide the ABSOLUTE PATH to the NDA RDS file nda2.0.1.Rds (or whichever version is being used)"
# }

# if (( $# < 1 ))
# then
#     usage
# 	exit 1
# fi

# Check for R
Rscript_exec=$(which Rscript)
 if [ ! -x "$Rscript_exec" ] ; then
    echo "Error - Rscript is not on PATH. Exiting"
    exit 1
 fi

# Check for and load config
ABCD_CCA_REPLICATION="$(dirname "$PWD")"
if [[ -f $ABCD_CCA_REPLICATION/pipeline.config ]]; then
    # config exists, so run it
    # This will load BIDS_PATH, DERIVATIVES_PATH, DATA_PREP variables
    . $ABCD_CCA_REPLICATION/pipeline.config
else
    echo "$ABCD_CCA_REPLICATION/pipeline.config does not exist! Please run create_config.sh."
    exit 1
fi

# Check if the following folders/files exist
STAGE_2_OUT=$DATA_PREP/data/stage_2/
if [[ -d $STAGE_2_OUT ]]; then
    rm $STAGE_2_OUT/*.txt
    rm $STAGE_2_OUT/*.Rds
else
    mkdir $STAGE_2_OUT
fi


echo "--- PREP_STAGE_2 ---"
echo "$(date) - START"

echo "--- STAGE 2 LOG ---" >> $PREP_LOG
echo "$(date) - START" >> $PREP_LOG

stage_1_subjects=$DATA_PREP/data/stage_1/subjects_keep_0.3mm.txt

echo "$(date) - STEP 1 - calling RDS cleaning script" >> $PREP_LOG
echo "$(date) - STEP 1 - calling RDS cleaning script"
# STEP 1 - Call R script to clean RDS, pull scan data, filter subjects missing scandata or not meeting QC/PC requirement for T1w scans
Rscript $SUPPORT_SCRIPTS/stage_2/clean_rds_pull_scandata.r $NDA_RDS $stage_1_subjects $STAGE_2_OUT

NUM_SUBS_MISSING=$(cat $STAGE_2_OUT/prep_stage_2_missing_subjects.txt | wc -l)
NUM_SUBS_DROPPED=$(cat $STAGE_2_OUT/prep_stage_2_dropped_scan_subjects.txt | wc -l)
NUM_SUBS_RDS=$(cat $STAGE_2_OUT/prep_stage_2_final_subjects.txt | wc -l)
echo "$(date) - Number subjects missing from RDS file: $NUM_SUBS_MISSING"
echo "$(date) - Number subjects missing from RDS file: $NUM_SUBS_MISSING" >> $PREP_LOG
echo "$(date) - Number subjects dropped due to missing scan data or not meeting requirements: $NUM_SUBS_DROPPED"
echo "$(date) - Number subjects dropped due to missing scan data or not meeting requirements: $NUM_SUBS_DROPPED" >> $PREP_LOG
echo "$(date) - Number subjects after RDS cleaning: $NUM_SUBS_RDS"
echo "$(date) - Number subjects after RDS cleaning: $NUM_SUBS_RDS" >> $PREP_LOG

# STEP 2 - Calculate average motion for subjects in $STAGE_2_OUT/prep_stage_2_final_subjects.txt

# STEP 3 - Motion filtering

echo "$(date) - STOP" >> $PREP_LOG
echo "--- END STAGE 2 LOG ---" >> $PREP_LOG
echo "" >> $PREP_LOG
echo