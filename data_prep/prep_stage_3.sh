#! /bin/bash

# prep_stage_3.sh
# Created: 6/21/20 (pipeline_version_1.3)
# Updated: (rewritten) 7/24/20 pipeline_version_1.5

# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020

# Expected tools on PATH:
# None.

# Example usage:
#   ./prep_stage_3.sh

# Check for and load config
ABCD_CCA_REPLICATION="$(dirname "$PWD")"
if [[ -f $ABCD_CCA_REPLICATION/pipeline.config ]]; then
    # config exists, so run it
    # This will load BIDS_PATH, DERIVATIVES_PATH, DATA_PREP variables
    . $ABCD_CCA_REPLICATION/pipeline.config
else
    echo "$ABCD_CCA_REPLICATION/pipeline.config does not exist! Please run create_config.sh."
    exit 1
fi

# Check if the following folders/files exist
if [[ -d $STAGE_3_OUT ]]; then
    read -p "Stage 3 Outputs Exist. Are you sure you want to overwrite it [y/n]? " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "OVERWRITING STAGE 3 FILES."
        rm -rf $STAGE_3_OUT/*.txt
        rm -rf $STAGE_3_OUT/*.Rds
        rm -rf $STAGE_3_OUT/swarm_logs/icafix/*.{e,o}
        rm -rf $STAGE_3_OUT/swarm_logs/censor_and_truncate/*.{e,o}
    else
        echo "Stage 3 files not overwritten."
    fi
else
    mkdir -p $STAGE_3_OUT
    mkdir -p $STAGE_3_OUT/swarm_logs/icafix/
    mkdir -p $STAGE_3_OUT/swarm_logs/censor_and_truncate/
    mkdir -p $STAGE_3_OUT/NIFTI/
fi


echo "--- STAGE 3 LOG ---" >> $PREP_LOG
echo "$(date) - START" >> $PREP_LOG

echo
echo "--- PREP_STAGE_3 ---"
echo "$(date) - START"
echo "PREP STAGE 3 Requires some steps to be performed manually. A number of scripts will be run to generate batch commands (designed for the NIH Biowulf) along with instructions on how to use the commands."
echo "If you are not using the NIH Biowulf, you will need to adapt these commands to your own HPC."

# Step 1
echo "- STEP 1: ICA+FIX -"
echo "- For the ICA+FIX runs, we recommend using our included fix_multi_run.sh script, with ICA+FIX 1.06.15 and HPC pipeline 4.1.3"
echo "- You will need to properly configure the ICA+FIX settings.sh file for your system."
echo "- Example ICA+FIX command: "
echo "  cd /path/to/subject/folder/MNINonLinear/Results/ /path/to/fix_multi_run.sh task-rest01/task-rest01.nii.gz@task-rest02/task-rest02.nii.gz 2000 fix_proc/task-rest_concat TRUE"
echo "- NOTE, if you want to change the SWARM commands, you need to manually change the code in this script."

echo "- NOW GENERATING THE icafix.swarm FILE"
while read subject; do
    icafix=$(cat $STAGE_1_OUT/icafix_cmds/$FD_THRESH/$SCAN_FD_THRESH_1/$subject.txt)
    echo "export MCR_CACHE_ROOT=/lscratch/\$SLURM_JOB_ID && module load R fsl connectome-workbench && cd /data/ABCD_MBDU/abcd_bids/bids/derivatives/dcan_reproc/$subject/ses-baselineYear1Arm1/files/MNINonLinear/Results && /data/ABCD_MBDU/goyaln2/fix/fix_multi_run.sh $icafix 2000 fix_proc/task-rest_concat TRUE /data/ABCD_MBDU/goyaln2/fix_training/code/ABCD_20subjs_training.RData" >> $STAGE_3_OUT/icafix.swarm
done < $STAGE_2_OUT/stage_2_final_subjects.txt
echo
echo "- ICA+FIX SWARM file generated! Located in $STAGE_3_OUT/icafix.swarm."
echo "- Run the swarm as follows:"
echo "      swarm -f icafix.swarm -g 32 --gres=lscratch:50 --time 24:00:00 --logdir $STAGE_3_OUT/swarm_logs/icafix/ --job-name icafix"

echo "- ICA+FIX SWARM file generated! Located in $STAGE_3_OUT/icafix.swarm." >> $PREP_LOG
echo "- Run the swarm as follows:" >> $PREP_LOG
echo "      swarm -f icafix.swarm -g 32 --gres=lscratch:50 --time 24:00:00 --logdir $STAGE_3_OUT/swarm_logs/icafix/ --job-name icafix" >> $PREP_LOG


# Step 2 and 3
echo
echo "- STEP 2: Get final subject list (based on presence of task-rest_concat_hp2000_clean.nii.gz) -"
echo "- STEP 3: Generate censor+truncate commands)"
echo "- NOTE, Step 3 will require manually submitting/running a SWARM job to do censor+truncate."
echo "- To perform steps 2 & 3, run the script:"
echo "      $SUPPORT_SCRIPTS/stage_3/prep_stage_3_steps2and3.sh $ABCD_CCA_REPLICATION"

echo "- NOTE, Step 3 will require manually submitting/running a SWARM job to do censor+truncate." >> $PREP_LOG
echo "- To perform steps 2 & 3, run the script:" >> $PREP_LOG
echo "      $SUPPORT_SCRIPTS/stage_3/prep_stage_3_steps2and3.sh $ABCD_CCA_REPLICATION" >> $PREP_LOG


# Step 4
echo
echo "- STEP 4: MELODIC Group-ICA -"
echo "- Run MELODIC using the script:"
echo "      $SUPPORT_SCRIPTS/stage_3/run_melodic.sh $ABCD_CCA_REPLICATION"

echo "- STEP 4: MELODIC Group-ICA -" >> $PREP_LOG
echo "- Run MELODIC using the script:" >> $PREP_LOG
echo "      $SUPPORT_SCRIPTS/stage_3/run_melodic.sh $ABCD_CCA_REPLICATION" >> $PREP_LOG


# Step 5
echo
echo "- STEP 5: dual_regression -"
echo "- Run dual_regression using the script:"
echo "      $SUPPORT_SCRIPTS/stage_3/run_dual_regression.sh $ABCD_CCA_REPLICATION"

echo "- STEP 5: dual_regression -" >> $PREP_LOG
echo "- Run dual_regression using the script:" >> $PREP_LOG
echo "      $SUPPORT_SCRIPTS/stage_3/run_dual_regression.sh $ABCD_CCA_REPLICATION" >> $PREP_LOG


# Step 6
echo
echo "- STEP 6: slices_summary -"
echo "- Run slices_summary using the script:"
echo "      $SUPPORT_SCRIPTS/stage_3/run_slices_summary.sh $ABCD_CCA_REPLICATION"
echo

echo "- STEP 6: slices_summary -" >> $PREP_LOG
echo "- Run slices_summary using the script:" >> $PREP_LOG
echo "      $SUPPORT_SCRIPTS/stage_3/run_slices_summary.sh $ABCD_CCA_REPLICATION" >> $PREP_LOG

echo "$(date) - STOP" >> $PREP_LOG
echo "--- END STAGE 3 LOG ---" >> $PREP_LOG
echo "" >> $PREP_LOG