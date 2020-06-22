#! /bin/bash

# calc_mean_fd.sh
# Created: 6/20/20 (pipeline_version_1.2)
# Updated:

# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020

sub=$1
ABCD_CCA_REPLICATION=$2

if [[ -f $ABCD_CCA_REPLICATION/pipeline.config ]]; then
    # config exists, so run it
    # This will load BIDS_PATH, DERIVATIVES_PATH, DATA_PREP variables
    . $ABCD_CCA_REPLICATION/pipeline.config
else
    echo "$ABCD_CCA_REPLICATION/pipeline.config does not exist! Please run create_config.sh."
    exit 1
fi

STAGE_2_OUT=$DATA_PREP/data/stage_2
# detect files of format:
# sub-NDARINVxxxxxxxx_ses-baselineYear1Arm1_task-rest_run-<1,2,3...>_motion.tsv
tsv_paths=`find $DERIVATIVES_PATH/$sub/ses-baselineYear1Arm1/ -maxdepth 2 -type f -name "sub-*ses-baselineYear1Arm1_task-rest*motion.tsv" ! -name "*desc-filtered*" 2> /dev/null | sort | uniq`

# check if path variable is an empty line (nothing except a newline terminator)
if [ -z "$tsv_paths" ]; then
    # Skip this subject
    touch $STAGE_2_OUT/subs_missing_motion_data/$sub
else
    num_tsv_files=$(echo "$tsv_paths" | wc -l)
    len_classifier=$(cat $DATA_PREP/data/stage_1/classifiers/0.3mm/$sub.txt | wc -l)

    # check for mis-match between the length of classifier file and number of motion.tsv files
    if [ $num_tsv_files -eq $len_classifier; then
        # correct number of tsv files for number of runs

        # Save the filepaths for .tsv files to the $stage_2_out directory
        echo "$tsv_paths" > $STAGE_2_OUT/motion_data/${sub}_tsv_paths.txt

        # Now call python script to calc
        python $SUPPORT_SCRIPTS/stage_2/subject_motion_to_meanFD.py $sub $DATA_PREP/data/stage_1/classifiers/0.3mm/$sub.txt $STAGE_2_OUT/motion_data/${sub}_tsv_paths.txt $STAGE_2_OUT/motion_data/$sub.txt

    else
        # Error, skip this subject
        echo "ERROR: subject $sub mismatch between number of rsfMRI runs ($len_classifier) number of motion.tsv files ($num_files)."
        exit
    fi
fi