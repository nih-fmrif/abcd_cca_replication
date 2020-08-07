#! /bin/bash

# prep_stage_1.sh
# Created: 6/15/20
# Updated: 6/22/20 (pipeline_version_1.4)

# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
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


# Check if the following folders exists
if [[ -d "$STAGE_1_OUT" ]]; then
    rm $STAGE_1_OUT/*.txt
    rm $STAGE_1_OUT/*.csv
    rm $STAGE_1_OUT/swarm_logs/*.{e,o}

    rm $STAGE_1_OUT/icafix_cmds/$FD_THRESH/$SCAN_FD_THRESH_1/*.txt
    rm $STAGE_1_OUT/icafix_cmds/$FD_THRESH/$SCAN_FD_THRESH_2/*.txt

    rm $STAGE_1_OUT/subjects_classified/$FD_THRESH/$SCAN_FD_THRESH_1/keep/*
    rm $STAGE_1_OUT/subjects_classified/$FD_THRESH/$SCAN_FD_THRESH_2/keep/*

    rm $STAGE_1_OUT/subjects_classified/$FD_THRESH/$SCAN_FD_THRESH_1/discard/*
    rm $STAGE_1_OUT/subjects_classified/$FD_THRESH/$SCAN_FD_THRESH_2/discard/*

    rm $STAGE_1_OUT/subjects_classified/$FD_THRESH/$SCAN_FD_THRESH_1/error/*
    rm $STAGE_1_OUT/subjects_classified/$FD_THRESH/$SCAN_FD_THRESH_2/error/*

    rm $STAGE_1_OUT/classifiers/$FD_THRESH/$SCAN_FD_THRESH_1/*.txt
    rm $STAGE_1_OUT/classifiers/$FD_THRESH/$SCAN_FD_THRESH_2/*.txt

    rm $STAGE_1_OUT/subject_mean_fd/$FD_THRESH/$SCAN_FD_THRESH_1/*.txt
    rm $STAGE_1_OUT/subject_mean_fd/$FD_THRESH/$SCAN_FD_THRESH_2/*.txt

    rm $STAGE_1_OUT/concat_censors/$FD_THRESH/$SCAN_FD_THRESH_1/*.txt
    rm $STAGE_1_OUT/concat_censors/$FD_THRESH/$SCAN_FD_THRESH_2/*.txt

    rm $STAGE_1_OUT/subjects_missing_data/*

    rm $STAGE_1_OUT/motion_tsv_files/*.txt

    rm $STAGE_1_OUT/censor_file_paths/*.txt

else
    mkdir "$STAGE_1_OUT/"
    mkdir "$STAGE_1_OUT/swarm_logs/"

    mkdir -p "$STAGE_1_OUT/icafix_cmds/$FD_THRESH/$SCAN_FD_THRESH_1/"
    mkdir -p "$STAGE_1_OUT/icafix_cmds/$FD_THRESH/$SCAN_FD_THRESH_2/"

    mkdir -p "$STAGE_1_OUT/subjects_classified/$FD_THRESH/$SCAN_FD_THRESH_1/keep"
    mkdir -p "$STAGE_1_OUT/subjects_classified/$FD_THRESH/$SCAN_FD_THRESH_2/keep/"

    mkdir -p "$STAGE_1_OUT/subjects_classified/$FD_THRESH/$SCAN_FD_THRESH_1/discard/"
    mkdir -p "$STAGE_1_OUT/subjects_classified/$FD_THRESH/$SCAN_FD_THRESH_2/discard/"

    mkdir -p "$STAGE_1_OUT/subjects_classified/$FD_THRESH/$SCAN_FD_THRESH_1/error/"
    mkdir -p "$STAGE_1_OUT/subjects_classified/$FD_THRESH/$SCAN_FD_THRESH_2/error/"

    mkdir -p "$STAGE_1_OUT/classifiers/$FD_THRESH/$SCAN_FD_THRESH_1/"
    mkdir -p "$STAGE_1_OUT/classifiers/$FD_THRESH/$SCAN_FD_THRESH_2/"

    mkdir -p "$STAGE_1_OUT/subject_mean_fd/$FD_THRESH/$SCAN_FD_THRESH_1/"
    mkdir -p "$STAGE_1_OUT/subject_mean_fd/$FD_THRESH/$SCAN_FD_THRESH_2/"

    mkdir -p "$STAGE_1_OUT/concat_censors/$FD_THRESH/$SCAN_FD_THRESH_1/"
    mkdir -p "$STAGE_1_OUT/concat_censors/$FD_THRESH/$SCAN_FD_THRESH_2/"

    mkdir -p "$STAGE_1_OUT/subjects_missing_data/"

    mkdir -p "$STAGE_1_OUT/motion_tsv_files/"

    mkdir -p "$STAGE_1_OUT/censor_file_paths/"
fi

echo "--- STAGE 1 ---"
echo "$(date) - START"

echo "--- STAGE 1 LOG ---" >> $PREP_LOG
echo "$(date) - START" >> $PREP_LOG

# STEP 1
# Generate swarm commands
echo "$(date) - Generating .swarm file with commands for classifying scans and subjects for use."
$PYTHON $SUPPORT_SCRIPTS/stage_1/stage_1_swarm_gen.py $STAGE_0_OUT/subjects_with_rsfmri.txt $ABCD_CCA_REPLICATION $SUPPORT_SCRIPTS/stage_1/subject_classifier.sh $STAGE_1_OUT

echo "$(date) - swarm file created, call with the following commands. MAKE SURE TO ACTIVATE ABCD_CCA_REPLICATION CONDA ENVIRONMENT PRIOR TO RUNNING!"
echo "          swarm -f $STAGE_1_OUT/stage_1.swarm -b 500 --logdir $STAGE_1_OUT/swarm_logs/ --time=00:10:00 --job-name stage_1"

echo "$(date) - swarm file created, call with the following commands. MAKE SURE TO ACTIVATE ABCD_CCA_REPLICATION CONDA ENVIRONMENT PRIOR TO RUNNING!" >> $PREP_LOG
echo "          swarm -f $STAGE_1_OUT/stage_1.swarm -b 500 --logdir $STAGE_1_OUT/swarm_logs/ --time=00:10:00 --job-name stage_1" >> $PREP_LOG

echo "$(date) - STOP" >> $PREP_LOG
echo "--- END STAGE 1 LOG ---" >> $PREP_LOG
echo "" >> $PREP_LOG