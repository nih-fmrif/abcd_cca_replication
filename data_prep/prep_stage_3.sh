#! /bin/bash

# prep_stage_3.sh
# Created: 6/21/20 (pipeline_version_1.3)
# Updated:

# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020

# Expected tools on PATH:
# R

# Example usage:
#   ./prep_stage_3.sh

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
STAGE_3_OUT=$DATA_PREP/data/stage_3/
if [[ -d $STAGE_3_OUT ]]; then
    rm $STAGE_3_OUT/*.txt
    rm $STAGE_3_OUT/*.Rds
else
    mkdir $STAGE_3_OUT
fi

echo "--- PREP_STAGE_3 ---"
echo "$(date) - START"

echo "--- STAGE 3 LOG ---" >> $PREP_LOG
echo "$(date) - START" >> $PREP_LOG


# STEP 0 - Get path to subject list from Stage 2, also generate a motion file using data in /data/stage_2/motion_data/sub-NDARINVxxxxxxxx.txt
stage_2_subjects=$DATA_PREP/data/stage_2/prep_stage_2_rds_subjects.txt

motion_file=$DATA_PREP/data/stage_3/subjects_mean_fds.txt
touch $motion_file
echo "subjectid,mean_fd" >> $motion_file
while read subject; do
    cat $DATA_PREP/data/stage_2/motion_data/$subject.txt >> $motion_file
done < $stage_2_subjects

# STEP 1 - Call R script to extract final subjects and SMs
echo "$(date) - STEP 1 - Extracting final subject list and SM matrix (final_rds_proc)" >> $PREP_LOG
echo "$(date) - STEP 1 - Extracting final subject list and SM matrix (final_rds_proc)"
Rscript $SUPPORT_SCRIPTS/stage_3/final_rds_proc.r $DATA_PREP/data/stage_2/nda2.0.1_stage_2.Rds $stage_2_subjects $DATA_PREP/data/subject_measures.txt $DATA_PREP/data/ica_subject_measures.txr $STAGE_3_OUT

# STEP 2 - Generate final VARS.txt matrix
echo "$(date) - STEP 2 - Generating final VARS.txt matrix (abcd_cca_replication/data/VARS.txt)" >> $PREP_LOG
echo "$(date) - STEP 2 - Generating final VARS.txt matrix (abcd_cca_replication/data/VARS.txt)"
python $SUPPORT_SCRIPTS/stage_3/vars.py $STAGE_3_OUT/final_subjects.txt $DATA_PREP/data/subject_measures.txt $motion_file $STAGE_3_OUT/VARS_no_motion.txt $ABCD_CCA_REPLICATION/data/VARS.txt

echo "$(date) - STOP" >> $PREP_LOG
echo "--- END STAGE 3 LOG ---" >> $PREP_LOG
echo "" >> $PREP_LOG
echo