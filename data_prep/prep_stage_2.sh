#! /bin/bash

# prep_stage_2.sh
# Created: 6/12/20
# Updated: 6/22/20 (pipeline_version_1.4)

# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020

# Expected tools on PATH:
# R

# Check for R
Rscript_exec=$(which Rscript)
 if [ ! -x "$Rscript_exec" ] ; then
    echo "Error - Rscript is not on PATH. Exiting"
    exit 1
 fi

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
if [[ -d $STAGE_2_OUT ]]; then
    rm $STAGE_2_OUT/*.txt
    rm $STAGE_2_OUT/*.Rds
else
    mkdir $STAGE_2_OUT
fi

echo "--- PREP_STAGE_2 ---"
echo "$(date) - START"

echo "--- STAGE 2 LOG ---" >> $PREP_LOG
echo "$(date) - START" >> $PREP_LOG

# STEP 0 - Get list of subjects which can proceed from stage 1, get aggregated list of motion
ls $STAGE_1_OUT/subjects_classified/$FD_THRESH/$SCAN_FD_THRESH_1/keep/sub-* | sort | sed "s|${STAGE_1_OUT}/subjects_classified/${FD_THRESH}/${SCAN_FD_THRESH_1}/keep/||" >> $STAGE_2_OUT/motion_filt_subjects.txt

subjects=$STAGE_2_OUT/motion_filt_subjects.txt

NUM_SUBS_STAGE_1=$(cat $subjects | wc -l)
echo "$(date) - Number subjects which passed pre- and post-censor scan length, and motion requirements from stage 1 (FD threshold ${FD_THRESH}mm, scan-level motion threshold ${SCAN_FD_THRESH_1}mm): $NUM_SUBS_STAGE_1" >> $PREP_LOG

# Aggregate the motion data for the subjects that passed filtering in stage 1
motion_file=$STAGE_2_OUT/subjects_mean_fds.txt
touch $motion_file
echo "subjectid,mean_fd" >> $motion_file
while read subject; do
    cat $STAGE_1_OUT/subject_mean_fd/$FD_THRESH/$SCAN_FD_THRESH_1/$subject.txt >> $motion_file
done < $subjects

# STEP 1 - Call R script to clean RDS, pull scan data, filter subjects missing scandata or not meeting QC/PC requirement for T1w scans
echo "$(date) - STEP 1 - calling RDS cleaning script" >> $PREP_LOG
echo "$(date) - STEP 1 - calling RDS cleaning script"
Rscript $SUPPORT_SCRIPTS/stage_2/clean_rds_pull_scandata.r $NDA_RDS_RAW $subjects $STAGE_2_OUT

NUM_SUBS_MISSING=$(cat $STAGE_2_OUT/prep_stage_2_missing_rds_subjects.txt | wc -l)
NUM_SUBS_DROPPED=$(cat $STAGE_2_OUT/prep_stage_2_dropped_rds_scan_subjects.txt | wc -l)
NUM_SUBS_RDS=$(cat $STAGE_2_OUT/prep_stage_2_rds_subjects.txt | wc -l)
echo "$(date) - Number subjects missing from RDS file: $NUM_SUBS_MISSING"
echo "$(date) - Number subjects missing from RDS file: $NUM_SUBS_MISSING" >> $PREP_LOG
echo "$(date) - Number subjects dropped due to missing scan data or not meeting requirements: $NUM_SUBS_DROPPED"
echo "$(date) - Number subjects dropped due to missing scan data or not meeting requirements: $NUM_SUBS_DROPPED" >> $PREP_LOG
echo "$(date) - Number subjects after RDS cleaning: $NUM_SUBS_RDS"
echo "$(date) - Number subjects after RDS cleaning: $NUM_SUBS_RDS" >> $PREP_LOG

# STEP 2 - Call final RDS proc script, extract final subjects and SMs
echo "$(date) - STEP 2 - Call final RDS proc script, extract final subjects and SMs" >> $PREP_LOG
echo "$(date) - STEP 2 - Call final RDS proc script, extract final subjects and SMs"
Rscript $SUPPORT_SCRIPTS/stage_2/final_rds_proc.r $DATA_PREP/data/stage_2/nda2.0.1_stage_2.Rds $STAGE_2_OUT/prep_stage_2_rds_subjects.txt $DATA_PREP/data/subject_measures.txt $DATA_PREP/data/ica_subject_measures.txt $STAGE_2_OUT
NUM_SUBS=$(cat $STAGE_2_OUT/final_subjects.txt | wc -l)
echo "Final number of subjects: $NUM_SUBS"
NUM_SMS=$(cat $STAGE_2_OUT/final_subject_measures.txt | wc -l)
echo "Final number of SMs: $NUM_SMS"

# STEP 3 - Generate final VARS.txt matrix (MOVED TO STAGE 4)
# echo "$(date) - STEP 3 - Generating final VARS.txt matrix (abcd_cca_replication/data/VARS.txt)" >> $PREP_LOG
# echo "$(date) - STEP 3 - Generating final VARS.txt matrix (abcd_cca_replication/data/VARS.txt)"
# python $SUPPORT_SCRIPTS/stage_2/vars.py $STAGE_2_OUT/final_subjects.txt $STAGE_2_OUT/final_subject_measures.txt $motion_file $STAGE_2_OUT/VARS_no_motion.txt $ABCD_CCA_REPLICATION/data/VARS.txt

# Note, if you need to just run step three from command line, do the following (from abcd_cca_replication folder)
# . pipeline.config
# motion_file=$STAGE_2_OUT/subjects_mean_fds.txt
# ABCD_CCA_REPLICATION=/data/ABCD_MBDU/goyaln2/abcd_cca_replication/
# python $SUPPORT_SCRIPTS/stage_2/vars.py $ABCD_CCA_REPLICATION/misc_scripts/final_subs/successful_subjects.txt $STAGE_2_OUT/final_subject_measures.txt $motion_file $STAGE_2_OUT/VARS_no_motion.txt $ABCD_CCA_REPLICATION/data/VARS.txt

echo "$(date) - STOP" >> $PREP_LOG
echo "--- END STAGE 2 LOG ---" >> $PREP_LOG
echo "" >> $PREP_LOG
echo