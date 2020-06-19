#! /bin/bash

# prep_stage_0.sh
# Created: 6/19/20
# Updated:

# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
# 0th stage script in our pipeline; does the following data-prep:
#   1.  Generates a file of pre-censor scan lengths for each subject (stored in /data_prep/data/stage_0/pre_censor_lengths/)
#   2.  Generates censors, post-censor length files (for 0.3mm and 0.2mm FD thresholds) (stored in /data_prep/data/stage_0/censor_files/)

# Expected tools on PATH:
# fsl

# Example usage:
# ./prep_stage_0.sh

# Check for FSL on path, else error
fsl_exec=$(which fsl)
if [ ! -x "$fsl_exec" ] ; then
    echo "Error - FSL is not on PATH. Exiting"
    exit 1
fi

# Check for and load config (else error)
ABCD_CCA_REPLICATION="$(dirname "$PWD")"
if [[ -f $ABCD_CCA_REPLICATION/pipeline.config ]]; then
    # config exists, so run it
    # This will load BIDS_PATH, DERIVATIVES_PATH, DATA_PREP variables
    . $ABCD_CCA_REPLICATION/pipeline.config
else
    echo "$ABCD_CCA_REPLICATION/pipeline.config does not exist! Please run create_config.sh."
    exit 1
fi

# Logging, delete if already exists (since we're starting fresh)
if [[ -f $PREP_LOG ]]; then
    rm $PREP_LOG
    touch $PREP_LOG
else
    touch $PREP_LOG
fi

# Check if we have censor files directory
if [[ -d $CENSOR_FILES ]]; then
    # Delete the files inside here
    # rm $CENSOR_FILES/*.txt
    :
else
    mkdir $CENSOR_FILES
fi

# Check if we have pre-censor length directory
if [[ -d $PRE_CENSOR_LENGTHS ]]; then
    # Delete the files inside here
    rm $PRE_CENSOR_LENGTHS/*.txt
else
    mkdir $PRE_CENSOR_LENGTHS
fi

# Check if the following folders exists
STAGE_0_OUT=$DATA_PREP/data/stage_0/
if [[ -d $STAGE_0_OUT ]]; then
    rm $STAGE_0_OUT/*.txt
    rm $STAGE_0_OUT/*.csv
    # rm $CENSOR_FILES/*/*.txt
else
    mkdir $STAGE_0_OUT
fi

echo "--- STAGE 0 ---"
echo "$(date) - START"

echo "--- STAGE 0 LOG ---" >> $PREP_LOG
echo "$(date) - START" >> $PREP_LOG

# STEP  1 - get the pre-censor scan lengths, store in $PRE_CENSOR_LENGTHS
# List of all subjects
echo "$(date) - Step 1: Getting list of all subjects in raw data. Determining pre-censor scan lengths."
echo "$(date) - Getting list of all subjects in raw data folder. Determining pre-censor scan lengths." >> $PREP_LOG
ls $BIDS_PATH | grep sub- > $STAGE_0_OUT/all_subjects.txt
while read sub; do
    tseries=${DERIVATIVES_PATH}/${sub}/ses-baselineYear1Arm1/func/${sub}_ses-baselineYear1Arm1_task-rest_bold_desc-filtered_timeseries.dtseries.nii
    if [[ -f "$tseries" ]]; then
        echo $sub >> $STAGE_0_OUT/subjects_with_rsfmri.txt
    else
        echo $sub >> $STAGE_0_OUT/subjects_missing_rsfmri.txt
    fi
done < $STAGE_0_OUT/all_subjects.txt


while read sub; do
# Get scan lengths for all available scans
    echo $sub >> $STAGE_0_OUT/subs_and_lengths.txt
    find $BIDS_PATH/$sub/ses-baselineYear1Arm1/func/ -type f -name "*task-rest_run*[0-9][0-9]_bold.nii.gz" | sort | xargs -L 1 fslnvols | tee -a $STAGE_0_OUT/subs_and_lengths.txt | tee $PRE_CENSOR_LENGTHS/${sub}.txt > /dev/null
done < $STAGE_0_OUT/subjects_with_rsfmri.txt

# STEP 2 - create censors, get post-censor lengths
echo "$(date) - Step 2: Generating swarm file to calculate censors, post-censor length for each subject."

echo "$(date) - STOP" >> $PREP_LOG
echo "--- END STAGE 0 LOG ---" >> $PREP_LOG
echo "" >> $PREP_LOG