#! /bin/bash

# clean_all_subjects_icafix.sh
# Created: 6/26/20
# Updated:

# NOTE, the subjects need to be folders, NOT .tar files

#Example command:
# ./clean_all_subjects_icafix.sh /data/ABCD_MBDU/abcd_bids/bids/derivatives/dcan_reproc/icafix_failed_missing.txt /data/ABCD_MBDU/abcd_bids/bids/derivatives/dcan_reproc/ /data/NIMH_scratch/abcd_cca/abcd_cca_replication/data_prep/data/stage_3/cleanup

# subject IDs to be cleaned
subjects_run=$1
# absolute path to /data/ABCD_MBDU/abcd_bids/bids/derivatives/dcan_reproc/
dcan_reproc=$2
# Where to save this script's outputs
out_dir=$3


while read sub; do

    # Create swarm command
    echo $PWD/fix_cleanup.sh $dcan_reproc/$sub/ >> $out_dir/cleanup.swarm

done < $subjects_run

echo "$(date) - swarm file created, call with following command:"
echo "          swarm -f $out_dir/cleanup.swarm -b 10 --logdir $out_dir/swarm_logs/ --time=01:00:00 --job-name cleanup"