#! /bin/bash

# prep_stage_3_steps2and3.sh
# Created: 7/27/20 (pipeline_version_1.5)
# Updated:

# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020

# Expected tools on PATH:
# None.

# Example usage:
#   ./prep_stage_3_steps2and3.sh

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


# PREP STAGE 3 - STEP 2: get final subject list
ls -d $DCAN_REPROC/*/ > $STAGE_3_OUT/folder_names.txt
while read line
do
    FILE=$line/ses-baselineYear1Arm1/files/MNINonLinear/Results/fix_proc/task-rest_concat_hp2000_clean.nii.gz
    if test -f "$FILE"; then
        echo "$FILE" >> $STAGE_3_OUT/final_subjects.txt
    fi
done < $STAGE_3_OUT/folder_names.txt

# Save number subjects
NUMSUBS=$(cat $STAGE_3_OUT/final_subjects.txt | wc -l)
echo "NUMSUBS=$NUMSUBS" >> $CONFIG

# Make the melodic directory & save the path
GICA=$DATA_PREP/${NUMSUBS}_subjects.gica
echo "GICA=$GICA" >> $CONFIG
mkdir -p $GICA

# Save path for dual_regression output
DR=$DATA_PREP/${NUMSUBS}_subjects.dr
echo "DR=$DR" >> $CONFIG


# PREP STAGE 3 - STEP 3: generate swarm commands for censor+truncate
while read subject; do
    # $SUPPORT_SCRIPTS/stage_3/cen_then_truncate.sh -subj $subject -in $DCAN_REPROC -cen $STAGE_1_OUT/concat_censors/$FD_THRESH/$SCAN_FD_THRESH_1/ -out $STAGE_3_OUT/NIFTI/
    echo "$SUPPORT_SCRIPTS/stage_3/cen_then_truncate.sh -subj $subject -in $DCAN_REPROC -cen $STAGE_1_OUT/concat_censors/$FD_THRESH/$SCAN_FD_THRESH_1/ -out $STAGE_3_OUT/NIFTI/" >> $STAGE_3_OUT/censor_and_truncate.swarm
done < $FINAL_SUBJECTS

echo "Done generating censor+truncate swarm, please run with as follow:"
echo "  swarm -f $STAGE_3_OUT/censor_and_truncate.swarm -g 12 --gres=lscratch:10 --time 00:15:00 --module afni --logdir $STAGE_3_OUT/swarm_logs/censor_and_truncate/ --job-name cen_trunc"