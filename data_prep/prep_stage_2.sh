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

echo
echo "--- PREP_STAGE_2 ---"
echo "$(date) - START"

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

# Check if the following folders/files exist
STAGE_2_OUT=$DATA_PREP/data/stage_2/
if [[ -d $STAGE_2_OUT ]]; then
    rm $STAGE_2_OUT/*.txt
else
    mkdir $STAGE_2_OUT
fi

DATAFOLDER=$DATA_PREP/data/stage_2/scan_length_analyze_classify/
ICAFIX_CMDS=$DATA_PREP/data/stage_2/icafix_cmds/
SWARM_DIR=$DATA_PREP/data/stage_2/swarm/

if [[ -d $CENSOR_FILES_CLEAN ]]; then
    rm $CENSOR_FILES_CLEAN/*.txt
else
    mkdir $CENSOR_FILES_CLEAN
fi

if [[ -d $DATAFOLDER ]]; then
    rm $DATAFOLDER/*.txt
else
    mkdir $DATAFOLDER
fi

if [[ -d $ICAFIX_CMDS ]]; then
    rm $ICAFIX_CMDS/*.txt
else
    mkdir $ICAFIX_CMDS
fi

if [[ -d $SWARM_DIR ]]; then
    rm $SWARM_DIR/logs/*.txt
    rm $SWARM_DIR/*.swarm
else
    mkdir $SWARM_DIR
    mkdir $SWARM_DIR/logs
fi

touch $DATA_PREP/data/stage_2/post_censor_subjects.txt
touch $DATA_PREP/data/stage_2/dropped_post_censor_subjects.txt

# STEP 1 - call scan_and_motion_analysis.py to do basic subject exclusion
echo "$(date): Step 1 - Broad subject filtering based on scan and motion summary data."
echo "$(date) - calling scan_and_motion_analysis.py" >> $PREP_LOG
python $SUPPORT_SCRIPTS/stage_2/scan_and_motion_analysis.py $DATA_PREP

# STEP 2 - run more refined subject exclusion (elim subjects based on post-censoring total scan length)
echo "$(date): Step 2 - Generating swarm commands for post-censor length analysis."
echo "$(date) - generating swarm commands for scan_length_analyze_classify_single.sh" >> $PREP_LOG
# sh $SUPPORT_SCRIPTS/stage_2/scan_length_analyze_classify.sh $ABCD_CCA_REPLICATION
# sh $SUPPORT_SCRIPTS/stage_2/scan_length_analyze_classify.sh $ABCD_CCA_REPLICATION $DATAFOLDER $ICAFIX_CMDS

# Generate swarm commands
python $SUPPORT_SCRIPTS/stage_2/stage_2_swarm_gen.py $STAGE_2_OUT/scan_and_motion_subjects.txt $ABCD_CCA_REPLICATION $SWARM_DIR "$SUPPORT_SCRIPTS/stage_2/scan_length_analyze_classify_single.sh"
echo "$(date): Swarm commands generated"
echo "run swarm with command:"
echo "        swarm -f $SWARM_DIR/stage_2.swarm -b 50 --logdir $SWARM_DIR/logs --job-name stage_2"

# number subjects remaining post-censor
# # NUM_SUBS=$(cat $STAGE_2_OUT/post_censor_subjects.txt | wc -l)
# echo "$(date): number of subjects remaining after post-censor filtering is $NUM_SUBS"
# echo "$(date) - number of subjects remaining after post-censor filtering: $NUM_SUBS" >> $PREP_LOG

echo "$(date) - STOP" >> $PREP_LOG
echo "--- END STAGE 2 LOG ---" >> $PREP_LOG
echo "" >> $PREP_LOG
echo