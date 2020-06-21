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

# Define some paths we need
CLASSIFIERS=$DATA_PREP/data/stage_1/classifiers/
ICAFIX=$DATA_PREP/data/stage_1/icafix_cmds/
pre_censor_lens=$PRE_CENSOR_LENGTHS/${sub}.txt

KEEP_DIR=$DATA_PREP/data/stage_1/subjects_classified/keep/
DISCARD_DIR=$DATA_PREP/data/stage_1/subjects_classified/discard/
ERROR_DIR=$DATA_PREP/data/stage_1/subjects_classified/error/

# STEP 1 - 0.2mm FD
post_censor_lens=$CENSOR_FILES/$sub/good_TRs_0.2mm.censor.txt
python $SUPPORT_SCRIPTS/stage_1/scan_subject_classifier.py $pre_censor_lens $post_censor_lens $CLASSIFIERS/0.2mm/$sub.txt $MIN_TPS
result=$?

# Check that the subject has enough total time based on returned "result"
if [[ $result -eq 2 ]]; then
    # Subject dropped from study, note this
    # echo "Dropping subject $sub, has less than 600 seconds of scan time post-censoring."
    echo $sub >> $DATA_PREP/data/stage_1/subjects_drop_0.2mm.txt
    touch $DISCARD_DIR/${sub}_0.2mm
elif [[ $result -eq 1 ]]; then
    # subject still eligible, create its task-rest0 string for ICA+FIX cmd
    # add subject to final list of subjects
    echo $sub >> $DATA_PREP/data/stage_1/subjects_keep_0.2mm.txt
    touch $KEEP_DIR/${sub}_0.2mm
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
    done < $CLASSIFIERS/0.2mm/$sub.txt
    # echo the ICA+FIX cmd to file
    echo $cmd_str >> $ICAFIX/0.2mm/$sub.txt
else
    # Something else went wrong (maybe not needed?)
    echo $sub >> $DATA_PREP/data/stage_1/subjects_error_0.2mm.txt
    touch $ERROR_DIR/${sub}_0.2mm
fi


# STEP 2 - 0.3mm FD
post_censor_lens=$CENSOR_FILES/$sub/good_TRs_0.3mm.censor.txt
python $SUPPORT_SCRIPTS/stage_1/scan_subject_classifier.py $pre_censor_lens $post_censor_lens $CLASSIFIERS/0.3mm/$sub.txt $MIN_TPS
result=$?

# Check that the subject has enough total time based on returned "result"
if [[ $result -eq 2 ]]; then
    # Subject dropped from study, note this
    # echo "Dropping subject $sub, has less than 600 seconds of scan time post-censoring."
    echo $sub >> $DATA_PREP/data/stage_1/subjects_drop_0.3mm.txt
    touch $DISCARD_DIR/${sub}_0.3mm
elif [[ $result -eq 1 ]]; then
    # subject still eligible, create its task-rest0 string for ICA+FIX cmd
    # add subject to final list of subjects
    echo $sub >> $DATA_PREP/data/stage_1/subjects_keep_0.3mm.txt
    touch $KEEP_DIR/${sub}_0.3mm
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
    done < $CLASSIFIERS/0.3mm/$sub.txt

    # echo the ICA+FIX cmd to file
    echo $cmd_str >> $ICAFIX/0.3mm/$sub.txt
else
    # Something else went wrong (maybe not needed?)
    echo $sub >> $DATA_PREP/data/stage_1/subjects_error_0.3mm.txt
    touch $ERROR_DIR/${sub}_0.3mm
fi