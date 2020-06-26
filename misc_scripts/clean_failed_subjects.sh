#! /bin/bash

# clean_failed_subjects.sh
# Created: 6/26/20
# Updated:

# NOTE, the subjects need to be folders, NOT .tar files

# path to txt file with list of subjects that were run
subjects_run=$1
# absolute path to /data/ABCD_MBDU/abcd_bids/bids/derivatives/dcan_reproc/
dcan_reproc=$2
# Where to save text files
out_dir=$3

while read sub; do
    # Check if subject has a file
    FILE=$dcan_reproc/$sub/ses-baselineYear1Arm1/files/MNINonLinear/Results/fix_proc/task-rest_concat_hp2000_clean.nii.gz

    if test -f "$FILE"; then
        # file exists, skip subject
        echo $subject >> $out_dir/successful_subjects.txt 
    else
        # File does not exist, add to list of subjects that need cleaning
        echo $subject >> $out_dir/remaining_subjects.txt
    fi
done < $subjects_run

NUM_DONE=$(cat $out_dir/successful_subjects.txt | wc -l)
NUM_FAIL=$(cat $out_dir/remaining_subjects.txt | wc -l)
echo "Successful=$NUM_DONE, failed=$NUM_FAIL"

while read sub; do

    # Create swarm command
    echo $PWD/fix_cleanup.sh $dcan_reproc/$sub/ >> $out_dir/cleanup.swarm

done < $out_dir/remaining_subjects.txt

echo "$(date) - swarm file created, call with following command:"
echo "          swarm -f $out_dir/cleanup.swarm -b 10 --logdir $out_dir/swarm_logs/ --time=01:00:00 --job-name cleanup"
