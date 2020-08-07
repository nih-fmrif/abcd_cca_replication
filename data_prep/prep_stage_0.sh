#! /bin/bash

# prep_stage_0.sh
# Created: 6/19/20
# Updated: 7/23/20 to add in call to script for generating censor files

# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
# 0th stage script in our pipeline; does the following data-prep:
#   1.  Generates a file of pre-censor scan lengths for each subject (stored in /data_prep/data/stage_0/pre_censor_lengths/)
#   2.  Generates censors, post-censor length files (for 0.3mm and 0.2mm FD thresholds) (stored in /data_prep/data/stage_0/censor_files/)

# Expected tools on PATH:
# fsl v6.0.1

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

# Check if the following folders exists
STAGE_0_OUT=$DATA_PREP/data/stage_0/
if [[ -d $STAGE_0_OUT ]]; then
    rm $STAGE_0_OUT/*.txt
else
    mkdir -p $STAGE_0_OUT
fi

# Check if we have censor files directory
if [[ -d $CENSOR_FILES ]]; then
    # Delete the files inside here
    # rm $CENSOR_FILES/*.txt
    :
else
    mkdir -p $CENSOR_FILES
fi

# Check if we have pre-censor length directory
if [[ -d $PRE_CENSOR_LENGTHS ]]; then
    # Delete the files inside here
    rm $PRE_CENSOR_LENGTHS/*.txt
else
    mkdir -p $PRE_CENSOR_LENGTHS
fi


echo "--- STAGE 0 ---"
echo "$(date) - START"

echo "--- STAGE 0 LOG ---" >> $PREP_LOG
echo "$(date) - START" >> $PREP_LOG

# STEP  1 - get the pre-censor scan lengths, store in $PRE_CENSOR_LENGTHS
# List of all subjects
echo "$(date) - Step 1: Getting list of all subjects in raw data. Determining pre-censor scan lengths."
echo "$(date) - Step 1: Getting list of all subjects in raw data folder. Determining pre-censor scan lengths." >> $PREP_LOG
ls $BIDS_PATH | grep sub- > $STAGE_0_OUT/all_subjects.txt

# Now iterate over subjects, save names of those who have resting state scans (and save scan lengths)

# check if a subject has > 0 resting state scans, if they do get lengths for scans, save subject id
while read sub; do
    # detect files of format:
    # sub-NDARINV53EP1G5X_ses-baselineYear1Arm1_task-rest_run-01_bold.nii.gz
    # sub-NDARINVYTVCUEA2_ses-baselineYear1Arm1_task-rest_bold.nii.gz
    paths=`find $BIDS_PATH/$sub/ses-baselineYear1Arm1/ -maxdepth 2 -type f -name "sub-*ses-baselineYear1Arm1_task-rest*bold.nii.gz" 2> /dev/null`

    # check if path variable is an empty line (nothing except a newline terminator)
    if [ -z "$paths" ]; then
        # Skip this subject
        echo $sub >> $STAGE_0_OUT/subjects_missing_rsfmri.txt
    else
        num_scans=$(echo "$paths" | wc -l)
        echo $sub >> $STAGE_0_OUT/subjects_with_rsfmri.txt
        echo $sub >> $STAGE_0_OUT/subs_and_lengths.txt

        # Get length for each scan (pre-censoring)
        echo "$paths" | sort | xargs -L 1 fslnvols | tee -a $STAGE_0_OUT/subs_and_lengths.txt | tee $PRE_CENSOR_LENGTHS/${sub}.txt > /dev/null

    fi
done < $STAGE_0_OUT/all_subjects.txt

# STEP 2 - create censors, get post-censor lengths
# This script will output to /data_prep/data/stage_0/censor_files/
# One folder per subject, containing the censors, number of TRs for each run after censoring for the specified FD threshold
echo "$(date) - Step 2: Generating swarm file to calculate censors, post-censor length for each subject."
echo "$(date) - Step 2: Generating swarm file to calculate censors, post-censor length for each subject." >> $PREP_LOG
$PYTHON $SUPPORT_SCRIPTS/stage_0/stage_0_swarm_gen.py $STAGE_0_OUT/subjects_with_rsfmri.txt $SUPPORT_SCRIPTS/stage_0/abcd_censor.py $FD_THRESH 5 $STAGE_0_OUT/censor_files $STAGE_0_OUT


echo "$(date) - STOP" >> $PREP_LOG
echo "--- END STAGE 0 LOG ---" >> $PREP_LOG
echo "" >> $PREP_LOG