#! /bin/bash

# icafix_cmd_gen.sh
# Created: 6/23/20
# Updated:

# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
# 

# Example usage:
# ./icafix_cmd_gen.sh subject_list.txt

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

subject_list=$1
output_folder=$2

# STEP 1
# Generate swarm commands
while read subject; do
    icafix=$(cat $STAGE_1_OUT/icafix_cmds/$FD_THRESH/$SCAN_FD_THRESH_1/$subject.txt)
    echo "export MCR_CACHE_ROOT=/lscratch/$SLURM_JOB_ID && module load R fsl connectome-workbench && cd /data/ABCD_MBDU/abcd_bids/bids/derivatives/dcan_reproc/$subject/ses-baselineYear1Arm1/files/MNINonLinear/Results && /data/ABCD_MBDU/goyaln2/fix/fix_multi_run.sh $icafix 2000 fix_proc/task-rest_concat TRUE /data/ABCD_MBDU/goyaln2/fix/training_files/HCP_Style_Single_Multirun_Dedrift.RData" >> $output_folder/icafix.swarm
done < $subject_list