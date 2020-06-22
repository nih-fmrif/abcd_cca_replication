#! /bin/bash

# subject_classifier.sh
# Created: 6/15/20
# Updated: 6/19/20 (pipeline_version_1.1)

# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020

# Example usage:
# ./subject_classifier.sh <subjectid> </abs/path/to/abcd_cca_replication/>

set -x

# Check for config
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

# Define some paths (FOLDERS) we need
CLASSIFIERS=$STAGE_1_OUT/classifiers/$FD_THRESH/
ICAFIX=$STAGE_1_OUT/icafix_cmds/$FD_THRESH/
KEEP_DIR=$STAGE_1_OUT/subjects_classified/$FD_THRESH/
DISCARD_DIR=$STAGE_1_OUT/subjects_classified/$FD_THRESH/
ERROR_DIR=$STAGE_1_OUT/subjects_classified/$FD_THRESH/
SUBJECT_MEAN_FD_DIR=$STAGE_1_OUT/subject_mean_fd/$FD_THRESH/

# Define paths to two files we will need
pre_censor_lens=$STAGE_0_OUT/pre_censor_lengths/${sub}.txt
post_censor_lens=$STAGE_0_OUT/censor_files/$sub/good_TRs_${FD_THRESH}.censor.txt

tsv_paths=`find $DERIVATIVES_PATH/$sub/ses-baselineYear1Arm1/ -maxdepth 2 -type f -name "sub-*ses-baselineYear1Arm1_task-rest*motion.tsv" ! -name "*desc-filtered*" 2> /dev/null | sort | uniq`

# check if path variable is an empty line (nothing except a newline terminator)
if [ -z "$tsv_paths" ]; then
    # Skip this subject
    touch $STAGE_1_OUT/subjects_missing_motion_data/$sub
    exit
else
    num_tsv_files=$(echo "$tsv_paths" | wc -l)
    num_scans=$(cat $num_scans | wc -l)

    # check for mis-match between the length of classifier file and number of motion.tsv files
    if [ $num_tsv_files -eq $len_classifier ]; then
        # correct number of tsv files for number of runs

        # Save the filepaths for .tsv files to the $stage_2_out directory
        echo "$tsv_paths" > $STAGE_1_OUT/motion_tsv_files/${sub}.txt

        # Now call python script to calc
        # python $SUPPORT_SCRIPTS/stage_2/subject_motion_to_meanFD.py $sub $DATA_PREP/data/stage_1/classifiers/0.3mm/$sub.txt $STAGE_2_OUT/motion_data/${sub}_tsv_paths.txt $STAGE_2_OUT/motion_data/$sub.txt

    else
        # Error, skip this subject
        echo "ERROR: subject $sub mismatch between number of rsfMRI runs ($num_scans) number of motion.tsv files ($num_tsv_files)."
        exit
    fi
fi

# STEP 1 - 0.3mm FD, SCAN_FD_THRESH_1
THRESH_TO_USE=$SCAN_FD_THRESH_1
# sub                     =   sys.argv[1]
# pre_censor_lengths_fp   =   sys.argv[2]
# post_censor_lengths_fp  =   sys.argv[3]
# tsv_files_fp            =   sys.argv[4]
# classifier_output_fp    =   sys.argv[5]
# subject_mean_fd_outp_fp =   sys.argv[6]
# min_tps                 =   int(sys.argv[7])
# scan_fd_thresh          =   float(sys.argv[8])
python $SUPPORT_SCRIPTS/stage_1/scan_subject_classifier.py $sub $pre_censor_lens $post_censor_lens $STAGE_1_OUT/motion_tsv_files/${sub}.txt $CLASSIFIERS/$THRESH_TO_USE/$sub.txt $SUBJECT_MEAN_FD_DIR/$THRESH_TO_USE/$sub.txt $MIN_TPS $THRESH_TO_USE
result=$?

# Check that the subject has enough total time based on returned "result"
if [[ $result -eq 2 ]]; then
    # Subject dropped from study, note this
    # echo "Dropping subject $sub, has less than 600 seconds of scan time post-censoring."
    # echo $sub >> $DATA_PREP/data/stage_1/subjects_drop_0.3mm.txt
    touch $DISCARD_DIR/$THRESH_TO_USE/${sub}
elif [[ $result -eq 1 ]]; then
    # subject still eligible, create its task-rest0 string for ICA+FIX cmd
    # add subject to final list of subjects
    # echo $sub >> $DATA_PREP/data/stage_1/subjects_keep_0.3mm.txt
    touch $KEEP_DIR/$THRESH_TO_USE/${sub}
    # Now create their cmd
    # Keep track of which scan we're looking at
    count=1 
    # total timepoints for valid scans for a subject
    cmd_str=""
    while read classification
    do
        if [[ $classification -eq 1 ]]; then
            # scan flagged as keep
            if [[ $count -eq 1 ]]; then
                # Prepend a 0, remove @ at beginning
                cmd_str=task-rest0$count/task-rest0$count.nii.gz
            elif [[ $count -lt 10 ]]; then
                # Prepend 0 since < 10, but include the @ at beginning
                cmd_str=$cmd_str@task-rest0$count/task-rest0$count.nii.gz
            else
                # No need to prepend 0 since number is 10 or greater
                cmd_str=$cmd_str@task-rest$count/task-rest$count.nii.gz
            fi
        else
            # Not using this scan
            :
        fi
        ((count++))
    done < $CLASSIFIERS/$THRESH_TO_USE/$sub.txt

    # echo the ICA+FIX cmd to file
    echo $cmd_str >> $ICAFIX/$THRESH_TO_USE/$sub.txt
else
    # Something else went wrong (maybe not needed?)
    # echo $sub >> $DATA_PREP/data/stage_1/subjects_error_0.3mm.txt
    touch $ERROR_DIR/$THRESH_TO_USE/${sub}
fi

# STEP 2 - 0.3mm (FD_THRESH), SCAN_FD_THRESH_2
THRESH_TO_USE=$SCAN_FD_THRESH_2
python $SUPPORT_SCRIPTS/stage_1/scan_subject_classifier.py $pre_censor_lens $post_censor_lens $STAGE_1_OUT/motion_tsv_files/${sub}.txt $CLASSIFIERS/$THRESH_TO_USE/$sub.txt $MIN_TPS $THRESH_TO_USE
result=$?

# Check that the subject has enough total time based on returned "result"
if [[ $result -eq 2 ]]; then
    # Subject dropped from study, note this
    # echo "Dropping subject $sub, has less than 600 seconds of scan time post-censoring."
    # echo $sub >> $DATA_PREP/data/stage_1/subjects_drop_0.3mm.txt
    touch $DISCARD_DIR/$THRESH_TO_USE/${sub}
elif [[ $result -eq 1 ]]; then
    # subject still eligible, create its task-rest0 string for ICA+FIX cmd
    # add subject to final list of subjects
    # echo $sub >> $DATA_PREP/data/stage_1/subjects_keep_0.3mm.txt
    touch $KEEP_DIR/$THRESH_TO_USE/${sub}
    # Now create their cmd
    # Keep track of which scan we're looking at
    count=1 
    # total timepoints for valid scans for a subject
    cmd_str=""
    while read classification
    do
        if [[ $classification -eq 1 ]]; then
            # scan flagged as keep
            if [[ $count -eq 1 ]]; then
                # Prepend a 0, remove @ at beginning
                cmd_str=task-rest0$count/task-rest0$count.nii.gz
            elif [[ $count -lt 10 ]]; then
                # Prepend 0 since < 10, but include the @ at beginning
                cmd_str=$cmd_str@task-rest0$count/task-rest0$count.nii.gz
            else
                # No need to prepend 0 since number is 10 or greater
                cmd_str=$cmd_str@task-rest$count/task-rest$count.nii.gz
            fi
        else
            # Not using this scan
            :
        fi
        ((count++))
    done < $CLASSIFIERS/$THRESH_TO_USE/$sub.txt

    # echo the ICA+FIX cmd to file
    echo $cmd_str >> $ICAFIX/$THRESH_TO_USE/$sub.txt
else
    # Something else went wrong (maybe not needed?)
    # echo $sub >> $DATA_PREP/data/stage_1/subjects_error_0.3mm.txt
    touch $ERROR_DIR/$THRESH_TO_USE/${sub}
fi