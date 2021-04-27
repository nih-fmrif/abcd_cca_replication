#! /bin/bash

# verify_icafix_outputs.sh
# Created: 4/1/2021
# Updated: 4/1/2021

# This script is run after ICA+FIX is done running. It will perform the following tasks:
#   a. of the list of final subjects from Stage 2, how many completed ICA+FIX successfully, and how many failed
#   b. for the subjects that failed, provide the user a swarm command (for NIH BIOWULF) to be run that will clean the subjects (remove files related to the failed ICA+FIX run) so they can be re-submitted for ICA_+FIX
#   c. generate a swarm command to re-run ICA+FIX for those remaining subjects

# EXAMPLE USAGE
# ./verify_icafix_outputs.sh /data/NIMH_scratch/abcd_cca/abcd_cca_replication/

ABCD_CCA_REPLICATION=$1
# Check for and load config
if [[ -f $ABCD_CCA_REPLICATION/pipeline.config ]]; then
    . $ABCD_CCA_REPLICATION/pipeline.config
else
    echo "$ABCD_CCA_REPLICATION/pipeline.config does not exist! Please run create_config.sh."
    exit 1
fi

if [[ -f $STAGE_3_OUT/ICAFIX_FAILED.txt ]]; then
    rm $STAGE_3_OUT/ICAFIX_FAILED.txt
fi
if [[ -f $STAGE_3_OUT/ICAFIX_SUCCESS.txt ]]; then
    rm $STAGE_3_OUT/ICAFIX_SUCCESS.txt
fi


echo "--- STAGE 3 - VERIFY_ICAFIX_OUTPUTS LOG ---" >> $PREP_LOG
echo "$(date) - START" >> $PREP_LOG

# A. CHECK NUMBER SUBJECTS SUCCESS AND FAIL
# store list of all subject folders located in $DCAN_REPROC
# example: 'sub-NDARINVXXXXXXXX'
# find $DCAN_REPROC -type d -maxdepth 1| awk -F/ '{print $NF}' > $STAGE_3_OUT/tmp_foldernames.txt

while read line
do
    FILE=$DCAN_REPROC/$line/ses-baselineYear1Arm1/files/MNINonLinear/Results/fix_proc/task-rest_concat_hp2000_clean.nii.gz
    if test -f "$FILE"; then
        # record all subjects that DO HAVE final ICA+FIX output (store their path to the file)
        echo "$line" >> $STAGE_3_OUT/ICAFIX_SUCCESS.txt
    else
        # record all subjects that DO NOT HAVE final ICA+FIX output (store subject ID)
        echo "$line" >> $STAGE_3_OUT/tmp_nofile.txt
    fi
done < $STAGE_2_OUT/stage_2_final_subjects.txt

# Of subjects destined for ICA+FIX (which are in $STAGE_2_OUT/stage_2_final_subjects.txt) see which ones have FAILED ICA+FIX
comm -12 <(sort $STAGE_2_OUT/stage_2_final_subjects.txt) <(sort $STAGE_3_OUT/tmp_nofile.txt) > $STAGE_3_OUT/ICAFIX_FAILED.txt

# rm $STAGE_3_OUT/tmp_foldernames.txt
rm $STAGE_3_OUT/tmp_nofile.txt

NUMSUBS_INPUT=$(cat $STAGE_2_OUT/stage_2_final_subjects.txt | wc -l)
NUMSUBS_FAILED=$(cat $STAGE_3_OUT/ICAFIX_FAILED.txt | wc -l)
NUMSUBS_SUCCESS=$(cat $STAGE_3_OUT/ICAFIX_SUCCESS.txt | wc -l)

echo
echo "ICA+FIX Results:"
echo "NUMBER INPUT: $NUMSUBS_INPUT"
echo "NUMBER SUCCESSFUL: $NUMSUBS_SUCCESS"
echo "NUMBER FAILED: $NUMSUBS_FAILED. The following failed (top 10 shown):"
head -n 10 $STAGE_3_OUT/ICAFIX_FAILED.txt
echo

# PROC_CODE=0 means generate the cleaning and patching swarms
# PROC_CODE=1 means proceed without the missing subjects
PROC_CODE=0

if [[ $NUMSUBS_FAILED -gt 0 ]]; then
    read -p "Some subjects failed ICA+FIX. Y = proceed without them, N = re-run the failed subjects. [y/n]? " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # PROCEED WITHOUT SUBJECTS
        PROC_CODE=1
    else
        # WRITE clean and patching swarm files
        PROC_CODE=0
    fi
else
    echo "No subjects failed ICA+FIX. PIPELINE CAN PROCCED WITH $NUMSUBS_SUCCESS SUBJECTS."
    PROC_CODE=1
fi

# CHECK IF USER WANTS TO PROCEED
echo
read -p "Do you want to proceed with the script, or exit script (no existing files will be removed if exit). [y/n]? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Proceeding..."
else
    # Exit
    exit 1
fi


if [[ $PROC_CODE -eq 0 ]]; then 
    echo "WARNING: $NUMSUBS_FAILED subjects have failed ICA+FIX." >> $PREP_LOG

    # Remove existing cleanup and ICA+FIX patch swarm files
    rm $STAGE_3_OUT/cleanup.swarm
    rm $STAGE_3_OUT/icafix_patch.swarm

    # B. GENERATE CLEANING SWARM
    while read sub; do
        echo $SUPPORT_SCRIPTS/misc_scripts/fix_cleanup.sh $DCAN_REPROC/$sub/ >> $STAGE_3_OUT/cleanup.swarm
    done < $STAGE_3_OUT/ICAFIX_FAILED.txt

    # C. GENERATE ICA+FIX PATCH SWARM
    while read sub; do
        icafix=$(cat $STAGE_1_OUT/icafix_cmds/$FD_THRESH/$SCAN_FD_THRESH_1/$sub.txt)
        echo "export MCR_CACHE_ROOT=/lscratch/\$SLURM_JOB_ID && module load R fsl connectome-workbench && cd /data/ABCD_MBDU/abcd_bids/bids/derivatives/dcan_reproc/$sub/ses-baselineYear1Arm1/files/MNINonLinear/Results && /data/ABCD_MBDU/goyaln2/fix/fix_multi_run.sh $icafix 2000 fix_proc/task-rest_concat TRUE /data/ABCD_MBDU/goyaln2/fix_training/code/ABCD_20subjs_training.RData" >> $STAGE_3_OUT/icafix_patch.swarm
    done < $STAGE_3_OUT/ICAFIX_FAILED.txt
    echo
    echo "- Run the CLEANING swarm as follows:"
    echo "          swarm -f $STAGE_3_OUT/cleanup.swarm -b 10 --logdir $STAGE_3_OUT/swarm_logs/cleanup/ --time=01:00:00 --job-name cleanup"
    echo "- Run the ICA+FIX PATCH swarm as follows:"
    echo "      swarm -f $STAGE_3_OUT/icafix_patch.swarm -g 64 --gres=lscratch:50 --time 24:00:00 --logdir $STAGE_3_OUT/swarm_logs/icafix_patch/ --job-name icafix_patch"
    echo
    echo "After running both the CLEANING and ICA+FIX PATCHING swarms, please re-run this script (verify_icafix_outputs.sh)."
    echo
    echo

    # Print commands to log
    echo "- Run the CLEANING swarm as follows:" >> $PREP_LOG
    echo "          swarm -f $STAGE_3_OUT/cleanup.swarm -b 10 --logdir $STAGE_3_OUT/swarm_logs/ --time=01:00:00 --job-name cleanup" >> $PREP_LOG

    echo "- Run the ICA+FIX PATCH swarm as follows:" >> $PREP_LOG
    echo "      swarm -f $STAGE_3_OUT/icafix_patch.swarm -g 32 --gres=lscratch:50 --time 24:00:00 --logdir $STAGE_3_OUT/swarm_logs/icafix_patch/ --job-name icafix_patch" >> $PREP_LOG

elif [[ $PROC_CODE -eq 1 ]]; then 
    echo "PIPELINE PROCCEDING WITH $NUMSUBS_SUCCESS SUBJECTS."
    echo "PIPELINE PROCCEDING WITH $NUMSUBS_SUCCESS SUBJECTS." >> $PREP_LOG

    # Make a copy of final subject list (for later scripts to access)
    # store in $STAGE_3_OUT/final_subjects.txt
    cp $STAGE_3_OUT/ICAFIX_SUCCESS.txt $STAGE_3_OUT/final_subjects.txt

    # WRITE VARIABLES TO CONFIG FILE
    echo
    echo "WRITING THE FOLLOWING VARIABLES TO THE CONFIG FILE"
    # store subject number in config
    echo "NUMSUBS=$NUMSUBS_SUCCESS" >> $CONFIG
    echo "Number subjects proceeding from ICAFIX=$NUMSUBS_SUCCESS"

    # Make the melodic directory & save the path
    GICA=$STAGE_3_OUT/${NUMSUBS}.gica
    echo "GICA=$GICA" >> $CONFIG
    echo "Group ICA Folder=$GICA"
    mkdir -p $GICA

    # Save path for dual_regression output
    DR=$STAGE_3_OUT/${NUMSUBS}.dr
    echo "DR=$DR" >> $CONFIG

    # # Make our /data/$NUMSUBS folder where our MATLAB processing will go in Stage 4
    CCA_PROC_DATA=$MAIN_REPO_DATA_FOLDER/$NUMSUBS
    echo "CCA_PROC_DAT=$CCA_PROC_DATA" >> $CONFIG
    echo "Folder for CCA outputs=$CCA_PROC_DATA"
    mkdir -p $CCA_PROC_DATA/permutations
    mkdir -p $CCA_PROC_DATA/iterations
    mkdir -p $CCA_PROC_DATA/iterations/swarm/logs

    echo

    # PRINT REMAINING COMMANDS FOR USER TO RUN
    echo "To proceed with pipeline, please run the following remaining steps for Stage 3:"
    # Step 2
    echo
    echo "- STEP 2: Generate censor+truncate commands)"
    echo "      $SUPPORT_SCRIPTS/stage_3/run_censor_truncate.sh $ABCD_CCA_REPLICATION"

    # Step 3
    echo
    echo "- STEP 3: MELODIC Group-ICA -"
    echo "      $SUPPORT_SCRIPTS/stage_3/run_melodic.sh $ABCD_CCA_REPLICATION"

    # Step 4
    echo
    echo "- STEP 4: dual_regression -"
    echo "      $SUPPORT_SCRIPTS/stage_3/run_dual_regression.sh $ABCD_CCA_REPLICATION"

    # Step 5
    echo
    echo "- STEP 5: slices_summary -"
    echo "      $SUPPORT_SCRIPTS/stage_3/run_slices_summary.sh $ABCD_CCA_REPLICATION"
    echo

    # Write commands to log
    echo "- STEP 2: Generate censor+truncate commands)" >> $PREP_LOG
    echo "      $SUPPORT_SCRIPTS/stage_3/run_censor_and_truncate.sh $ABCD_CCA_REPLICATION" >> $PREP_LOG
    echo "- STEP 3: MELODIC Group-ICA -" >> $PREP_LOG
    echo "      $SUPPORT_SCRIPTS/stage_3/run_melodic.sh $ABCD_CCA_REPLICATION" >> $PREP_LOG
    echo "- STEP 4: dual_regression -" >> $PREP_LOG
    echo "      $SUPPORT_SCRIPTS/stage_3/run_dual_regression.sh $ABCD_CCA_REPLICATION" >> $PREP_LOG
    echo "- STEP 5: slices_summary -" >> $PREP_LOG
    echo "      $SUPPORT_SCRIPTS/stage_3/run_slices_summary.sh $ABCD_CCA_REPLICATION" >> $PREP_LOG
fi

echo "$(date) - STOP" >> $PREP_LOG
echo "--- END STAGE 3 - VERIFY_ICAFIX_OUTPUTS LOG ---" >> $PREP_LOG

echo
echo