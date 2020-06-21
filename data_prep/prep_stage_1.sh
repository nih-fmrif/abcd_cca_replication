#! /bin/bash

# prep_stage_1.sh
# Created: 6/15/20
# Updated: 6/19/20 (pipeline_version_1.1)

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
    rm $STAGE_1_OUT/icafix_cmds/0.2mm/*.txt
    rm $STAGE_1_OUT/icafix_cmds/0.3mm/*.txt
    rm $STAGE_1_OUT/swarm_logs/*.{e,o}
    rm $STAGE_1_OUT/subjects_classified/*
    rm $STAGE_1_OUT/subjects_classified/keep/*
    rm $STAGE_1_OUT/subjects_classified/discard/*
    rm $STAGE_1_OUT/subjects_classified/error/*
else
    mkdir $STAGE_1_OUT
    mkdir $STAGE_1_OUT/icafix_cmds/0.2mm/
    mkdir $STAGE_1_OUT/swarm_logs/0.3mm/
    mkdir $STAGE_1_OUT/subjects_classified/
    mkdir $STAGE_1_OUT/subjects_classified/keep/
    mkdir $STAGE_1_OUT/subjects_classified/discard/
    mkdir $STAGE_1_OUT/subjects_classified/error/
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

echo "$(date) - swarm file created, call with the following commands. MAKE SURE TO ACTIVATE ABCD_CCA_REPLICATION CONDA ENVIRONMENT PRIOR TO RUNNING!" >> $PREP_LOG
echo "          swarm -f $STAGE_1_OUT/stage_1.swarm -b 50 --logdir $STAGE_1_OUT/swarm_logs/ --job-name stage_1" >> $PREP_LOG

echo "$(date) - STOP" >> $PREP_LOG
echo "--- END STAGE 1 LOG ---" >> $PREP_LOG
echo "" >> $PREP_LOG