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

echo "--- VERIFY_ICAFIX_OUTPUTS LOG ---" >> $PREP_LOG
echo "$(date) - START" >> $PREP_LOG

# A. CHECK NUMBER SUBJECTS SUCCESS AND FAIL
# if [[ -f $STAGE_3_OUT/ICAFIX_SUCCESS.txt ]]; then
#     rm $STAGE_3_OUT/ICAFIX_SUCCESS.txt
# fi
# if [[ -f $STAGE_3_OUT/ICAFIX_FAILED.txt ]]; then
#     rm $STAGE_3_OUT/ICAFIX_FAILED.txt
# fi
# if [[ -f $STAGE_3_OUT/cleanup.swarm ]]; then
#     rm $STAGE_3_OUT/cleanup.swarm
# fi
# if [[ -f $STAGE_3_OUT/icafix_patch.swarm ]]; then
#     rm $STAGE_3_OUT/icafix_patch.swarm
# fi

if [[ -d $STAGE_3_OUT ]]; then
    rm $STAGE_3_OUT/ICAFIX_SUCCESS.txt
    rm $STAGE_3_OUT/ICAFIX_FAILED.txt
    rm $STAGE_3_OUT/cleanup.swarm
    rm $STAGE_3_OUT/icafix_patch.swarm
    rm $STAGE_3_OUT/tmp_filenames.txt
    rm $STAGE_3_OUT/tmp_nofile.txt
fi

# store list of all subject folders located in $DCAN_REPROC
# ls -d $DCAN_REPROC/*/ | sed 's#/##' > $STAGE_3_OUT/tmp_filenames.txt
find $DCAN_REPROC -type d -maxdepth 1| awk -F/ '{print $NF}' > $STAGE_3_OUT/tmp_filenames.txt

while read line
do
    FILE=$line/ses-baselineYear1Arm1/files/MNINonLinear/Results/fix_proc/task-rest_concat_hp2000_clean.nii.gz
    if test -f "$FILE"; then
        # record all subjects that DO HAVE final ICA+FIX output
        echo "$FILE" >> $STAGE_3_OUT/ICAFIX_SUCCESS.txt
    else
        # record all subjects that DO NOT HAVE final ICA+FIX output
        echo "$line" >> $STAGE_3_OUT/tmp_nofile.txt
    fi
done < $STAGE_3_OUT/tmp_filenames.txt

# Of subjects destined for ICA+FIX (which are in $STAGE_2_OUT/stage_2_final_subjects.txt) see which ones have FAILED ICA+FIX
comm -12 <(sort $STAGE_2_OUT/stage_2_final_subjects.txt) <(sort $STAGE_3_OUT/tmp_nofile.txt) > $STAGE_3_OUT/ICAFIX_FAILED.txt

# rm $STAGE_3_OUT/tmp_filenames.txt
# rm $STAGE_3_OUT/tmp_nofile.txt

NUMSUBS_FAILED=$(cat $STAGE_3_OUT/ICAFIX_FAILED.txt | wc -l)
NUMSUBS_SUCCESS=$(cat $STAGE_3_OUT/ICAFIX_SUCCESS.txt | wc -l)

if [[ $NUMSUBS -gt 0 ]]; then 
    echo "WARNING: $NUMSUBS_FAILED subjects have failed ICA+FIX. These subjects must be re-run before the pipeline can proceed."

    # B. GENERATE CLEANING SWARM
    while read sub; do
        echo $SUPPORT_SCRIPTS/misc_scripts/fix_cleanup.sh $DCAN_REPROC/$sub/ >> $STAGE_3_OUT/cleanup.swarm
    done < $STAGE_3_OUT/ICAFIX_FAILED.txt

    # C. GENERATE ICA+FIX PATCH SWARM
    while read sub; do
        icafix=$(cat $STAGE_1_OUT/icafix_cmds/$FD_THRESH/$SCAN_FD_THRESH_1/$sub.txt)
        echo "export MCR_CACHE_ROOT=/lscratch/\$SLURM_JOB_ID && module load R fsl connectome-workbench && cd /data/ABCD_MBDU/abcd_bids/bids/derivatives/dcan_reproc/$sub/ses-baselineYear1Arm1/files/MNINonLinear/Results && /data/ABCD_MBDU/goyaln2/fix/fix_multi_run.sh $icafix 2000 fix_proc/task-rest_concat TRUE /data/ABCD_MBDU/goyaln2/fix_training/code/ABCD_20subjs_training.RData" >> $STAGE_3_OUT/icafix_patch.swarm
    done < $STAGE_3_OUT/ICAFIX_FAILED.txt

    echo "- Run the CLEANING swarm as follows:"
    echo "          swarm -f $STAGE_3_OUT/cleanup.swarm -b 10 --logdir $STAGE_3_OUT/swarm_logs/ --time=01:00:00 --job-name cleanup"

    echo "- Run the ICA+FIX PATCH swarm as follows:"
    echo "      swarm -f $STAGE_3_OUT/icafix_patch.swarm -g 32 --gres=lscratch:50 --time 24:00:00 --logdir $STAGE_3_OUT/swarm_logs/icafix_patch/ --job-name icafix_patch"

    echo "After running both the CLEANING and ICA+FIX PATCHING swarms, please re-run this script (verify_icafix_outputs.sh)."

else
    echo "ALL SUBJECTS COMPLETED ICA+FIX SUCCESSFULLY. PIPELINE CAN PROCCED WITH $NUMSUBS_SUCCESS SUBJECTS."
    echo "To proceed with pipeline, please run the following remaining steps for Stage 3:"

    # Step 2
    echo
    echo "- STEP 2: Generate censor+truncate commands)"
    echo "- NOTE, Step 2 will require manually submitting/running a SWARM job to do censor+truncate."
    echo "- To perform Step 2, run the script:"
    echo "      $SUPPORT_SCRIPTS/stage_3/run_censor_and_truncate.sh $ABCD_CCA_REPLICATION"

    echo "- STEP 2: Generate censor+truncate commands)" >> $PREP_LOG
    echo "- NOTE, Step 2 will require manually submitting/running a SWARM job to do censor+truncate." >> $PREP_LOG
    echo "- To perform Step 2, run the script:" >> $PREP_LOG
    echo "      $SUPPORT_SCRIPTS/stage_3/run_censor_and_truncate.sh $ABCD_CCA_REPLICATION" >> $PREP_LOG


    # Step 3
    echo
    echo "- STEP 4: MELODIC Group-ICA -"
    echo "- Run MELODIC using the script:"
    echo "      $SUPPORT_SCRIPTS/stage_3/run_melodic.sh $ABCD_CCA_REPLICATION"

    echo "- STEP 4: MELODIC Group-ICA -" >> $PREP_LOG
    echo "- Run MELODIC using the script:" >> $PREP_LOG
    echo "      $SUPPORT_SCRIPTS/stage_3/run_melodic.sh $ABCD_CCA_REPLICATION" >> $PREP_LOG


    # Step 4
    echo
    echo "- STEP 5: dual_regression -"
    echo "- Run dual_regression using the script:"
    echo "      $SUPPORT_SCRIPTS/stage_3/run_dual_regression.sh $ABCD_CCA_REPLICATION"

    echo "- STEP 5: dual_regression -" >> $PREP_LOG
    echo "- Run dual_regression using the script:" >> $PREP_LOG
    echo "      $SUPPORT_SCRIPTS/stage_3/run_dual_regression.sh $ABCD_CCA_REPLICATION" >> $PREP_LOG


    # Step 5
    echo
    echo "- STEP 6: slices_summary -"
    echo "- Run slices_summary using the script:"
    echo "      $SUPPORT_SCRIPTS/stage_3/run_slices_summary.sh $ABCD_CCA_REPLICATION"
    echo

    echo "- STEP 6: slices_summary -" >> $PREP_LOG
    echo "- Run slices_summary using the script:" >> $PREP_LOG
    echo "      $SUPPORT_SCRIPTS/stage_3/run_slices_summary.sh $ABCD_CCA_REPLICATION" >> $PREP_LOG
fi

echo "$(date) - STOP" >> $PREP_LOG
echo "--- END VERIFY_ICAFIX_OUTPUTS LOG ---" >> $PREP_LOG