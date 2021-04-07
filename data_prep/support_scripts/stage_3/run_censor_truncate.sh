#! /bin/bash

# run_censor_truncate.sh
# Created: 4/3/2021
# Updated: 4/7/21

# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020

# Expected tools on PATH:
# None.

# Example usage:
#   ./run_censor_truncate.sh /data/NIMH_scratch/abcd_cca/abcd_cca_replication/

# Check for and load config
ABCD_CCA_REPLICATION=$1
if [[ -f $ABCD_CCA_REPLICATION/pipeline.config ]]; then
    . $ABCD_CCA_REPLICATION/pipeline.config
else
    echo "$ABCD_CCA_REPLICATION/pipeline.config does not exist! Please run create_config.sh."
    exit 1
fi

echo "--- STAGE 3 - CENSOR+TRUNCATE - LOG ---" >> $PREP_LOG
echo "$(date) - START" >> $PREP_LOG

# Check if the following folders/files exist, remove to re-run
if [[ -f $STAGE_3_OUT/censor_and_truncate.swarm ]]; then
    rm $STAGE_3_OUT/censor_and_truncate.swarm
fi

# File containing list of subjects that successfully finish ICA+FIX:
# $STAGE_3_OUT/ICAFIX_SUCCESS.txt

# PREP STAGE 3 - STEP 3: generate swarm commands for censor+truncate
while read subject; do
    # $SUPPORT_SCRIPTS/stage_3/cen_then_truncate.sh -subj $subject -in $DCAN_REPROC -cen $STAGE_1_OUT/concat_censors/$FD_THRESH/$SCAN_FD_THRESH_1/ -out $STAGE_3_OUT/NIFTI/
    echo "$SUPPORT_SCRIPTS/stage_3/cen_then_truncate.sh -subj $subject -in $DCAN_REPROC -cen $STAGE_1_OUT/concat_censors/$FD_THRESH/$SCAN_FD_THRESH_1/ -out $STAGE_3_OUT/NIFTI/" >> $STAGE_3_OUT/censor_and_truncate.swarm
done < $STAGE_3_OUT/ICAFIX_SUCCESS.txt

echo "Run Censor+Trucate with the following swarm command:"
echo "  swarm -f $STAGE_3_OUT/censor_and_truncate.swarm -g 12 --gres=lscratch:10 --time 00:15:00 --module afni --logdir $STAGE_3_OUT/swarm_logs/censor_and_truncate/ --job-name cen_trunc"

echo "Run Censor+Trucate with the following swarm command:" >> $PREP_LOG
echo "  swarm -f $STAGE_3_OUT/censor_and_truncate.swarm -g 12 --gres=lscratch:10 --time 00:15:00 --module afni --logdir $STAGE_3_OUT/swarm_logs/censor_and_truncate/ --job-name cen_trunc" >> $PREP_LOG

echo "$(date) - STOP" >> $PREP_LOG
echo "--- END STAGE 3 - CENSOR+TRUNCATE - LOG ---" >> $PREP_LOG
echo "" >> $PREP_LOG