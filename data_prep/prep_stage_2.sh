#! /bin/bash

# prep_stage_2.sh
# Created: 6/16/20
# Updated:

# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
# This script is the second stage in our analysis pipeline for ABCD data
# This script will do the following (in this order):
#   1.
#   2.

# Expected inputs:
#   1.  absolute path to the parent directory containing the subject folders with raw scan data
#   2.  absolute path to the nda2.0.1.Rds (or other version?) R data structure

# Expected tools on PATH:

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

echo "--- STAGE 2 LOG ---" >> $PREP_LOG
echo "$(date) - START" >> $PREP_LOG

# Check if the following folders/files exist
STAGE_2_OUT=$DATA_PREP/data/stage_2/
if [[ -d $STAGE_2_OUT ]]; then
    rm -r $STAGE_2_OUT
    mkdir $STAGE_2_OUT
else
    mkdir $STAGE_2_OUT
fi

# STEP 1 - call scan_and_motion_analysis.py to do basic subject exclusion
echo "$(date): Step 2 - Broad subject filtering based on scan and motion summary data."
echo "$(date) - calling scan_and_motion_analysis.py" >> $PREP_LOG
python $SUPPORT_SCRIPTS/stage_2/scan_and_motion_analysis.py $DATA_PREP

# STEP 2 - run more refined subject exclusion (elim subjects based on post-censoring total scan length)

echo "$(date) - STOP" >> $PREP_LOG
echo "--- END STAGE 2 LOG ---" >> $PREP_LOG
echo "" >> $PREP_LOG