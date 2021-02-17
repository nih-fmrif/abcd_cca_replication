
# example usage:
#   ./icafix_swarm_patch.sh /data/NIMH_scratch/abcd_cca/abcd_cca_replication/ /data/ABCD_MBDU/abcd_bids/bids/derivatives/dcan_reproc/


ABCD_CCA_REPLICATION=$1
newpath=$2


# Check for and load config
if [[ -f $ABCD_CCA_REPLICATION/pipeline.config ]]; then
    # config exists, so run it
    # This will load BIDS_PATH, DERIVATIVES_PATH, DATA_PREP variables
    . $ABCD_CCA_REPLICATION/pipeline.config
else
    echo "$ABCD_CCA_REPLICATION/pipeline.config does not exist! Please run create_config.sh."
    exit 1
fi

echo "- NOW GENERATING THE icafix.swarm FILE"
while read subject; do
    icafix=$(cat $STAGE_1_OUT/icafix_cmds/$FD_THRESH/$SCAN_FD_THRESH_1/$subject.txt)
    echo "export MCR_CACHE_ROOT=/lscratch/\$SLURM_JOB_ID && module load R fsl connectome-workbench && cd /data/ABCD_MBDU/abcd_bids/bids/derivatives/dcan_reproc/$subject/ses-baselineYear1Arm1/files/MNINonLinear/Results && /data/ABCD_MBDU/goyaln2/fix/fix_multi_run.sh $icafix 2000 fix_proc/task-rest_concat TRUE /data/ABCD_MBDU/goyaln2/fix_training/code/ABCD_20subjs_training.RData" >> $STAGE_3_OUT/icafix_patch.swarm
done < $newpath/icafix_failed_missing.txt
echo
echo "- ICA+FIX SWARM file generated! Located in $STAGE_3_OUT/icafix.swarm."
echo "- Run the swarm as follows:"
echo "      swarm -f $STAGE_3_OUT/icafix.swarm -g 32 --gres=lscratch:50 --time 24:00:00 --logdir $STAGE_3_OUT/swarm_logs/icafix/ --job-name icafix"

echo "- ICA+FIX SWARM file generated! Located in $STAGE_3_OUT/icafix.swarm." >> $PREP_LOG
echo "- Run the swarm as follows:" >> $PREP_LOG
echo "      swarm -f $STAGE_3_OUT/icafix.swarm -g 32 --gres=lscratch:50 --time 24:00:00 --logdir $STAGE_3_OUT/swarm_logs/icafix/ --job-name icafix" >> $PREP_LOG