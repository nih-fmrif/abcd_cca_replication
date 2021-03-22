#! /bin/bash

# clean_all_subjects_icafix.sh
# Created: 6/26/20
# Updated:

# NOTE, the subjects need to be folders, NOT .tar files

#Example command:
# ./clean_all_subjects_icafix.sh /data/NIMH_scratch/abcd_cca/abcd_cca_replication/data_prep/data/stage_2/stage_2_final_subjects.txt /data/ABCD_MBDU/abcd_bids/bids/derivatives/dcan_reproc/ /data/NIMH_scratch/abcd_cca/abcd_cca_replication/data_prep/data/stage_3/cleanup

# path to txt file with list of subjects that were run
subjects_run=$1
# absolute path to /data/ABCD_MBDU/abcd_bids/bids/derivatives/dcan_reproc/
dcan_reproc=$2
# Where to save this script's outputs
out_dir=$3

while read sub; do
    # generate list of subjects
    FILE=$dcan_reproc/$sub/ses-baselineYear1Arm1/files/MNINonLinear/Results/fix_proc/task-rest_concat_hp2000_clean.nii.gz
    echo $sub >> $out_dir/cleanup_sub_list.txt
    # if test -f "$FILE"; then
    #     # file exists, add them to cleaning list
    #     echo $sub >> $out_dir/successful_subjects.txt
    # else
    #     # File does not exist, subjec
    #     echo $sub >> $out_dir/remaining_subjects.txt
    # fi
done < $subjects_run

NUM_CLEANING=$(cat $out_dir/cleanup_sub_list.txt | wc -l)
echo "Number to clean=$NUM_CLEANING"

while read sub; do

    # Create swarm command
    echo $PWD/fix_cleanup.sh $dcan_reproc/$sub/ >> $out_dir/cleanup.swarm

done < $out_dir/cleanup_sub_list.txt

echo "$(date) - swarm file created, call with following command:"
echo "          swarm -f $out_dir/cleanup.swarm -b 10 --logdir $out_dir/swarm_logs/ --time=01:00:00 --job-name cleanup"