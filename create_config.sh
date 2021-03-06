#! /bin/bash

# create_config.sh
# Created: 6/15/20
# Updated: 7/27/20 (added variables for pipeline_version1.5)
# Update: 4/7/21 (user no longer needs to enter the nda2.0.1.Rds file as input. Now assumed to be in data_prep/data/)


usage()
{
	echo "usage: create_config.sh <path/to/abcd_cca_replication/> <path/to/main/abcd_bids/bids/> <path/to/reprocessed/DCAN/output/> <path/to/conda/python>"
    echo "ex: ./create_config.sh /data/NIMH_scratch/abcd_cca/abcd_cca_replication/ /data/ABCD_MBDU/abcd_bids/bids/ /data/ABCD_MBDU/abcd_bids/bids/derivatives/dcan_reproc/ /data/goyaln2/conda/envs/abcd_cca_replication/bin/python"
    # echo "NOTE you must provide the ABSOLUTE PATH to the main directory of the ABCD collection 3165 download. for example: /data/ABCD/abcd_bids/bids/"
    # echo "NOTE you must provide the ABSOLUTE PATH to the NDA RDS file. for example /data/ABCD_MBDU/goyaln2/abcd_cca_replication/data_prep/data/nda2.0.1.Rds"
}

if (( $# < 2 ))
then
    usage
	exit 1
fi

ABCD_CCA_REPLICATION=$1
BIDS_PATH=$2
DCAN_REPROC=$3
PYTHON=$4

DERIVATES_PATH=$BIDS_PATH/derivatives/abcd-hcp-pipeline/
DATA_PREP=$PWD/data_prep/
MAIN_REPO_DATA_FOLDER=$PWD/data/
PIPELINE_LOG_DIR=$DATA_PREP/logs/
PREP_LOG=$DATA_PREP/logs/prep_log.txt
SUPPORT_SCRIPTS=$DATA_PREP/support_scripts/
PRE_CENSOR_LENGTHS=$DATA_PREP/data/stage_0/pre_censor_lengths/
CONFIG=$PWD/pipeline.config
STAGE_0_OUT=$DATA_PREP/data/stage_0/
STAGE_1_OUT=$DATA_PREP/data/stage_1/
STAGE_2_OUT=$DATA_PREP/data/stage_2/
STAGE_3_OUT=$DATA_PREP/data/stage_3/
STAGE_4_OUT=$DATA_PREP/data/stage_4/
STAGE_5_OUT=$DATA_PREP/data/stage_5/
FINAL_SUBJECTS=$STAGE_3_OUT/final_subjects.txt
FINAL_SUBJECT_MEASURES=$STAGE_2_OUT/final_subject_measures.txt

# Change file name as needed.
NDA_RDS_RAW=$DATA_PREP/data/nda2.0.1.Rds

# DONT FORGET TO CHANGE THESE MANUALLY (as needed)!
TR_INTERVAL=0.8
MIN_TPS=190
FD_THRESH=0.3
SCAN_FD_THRESH_1=0.3
SCAN_FD_THRESH_2=0.15


# THE FOLLOWING GET SET DYANMICALLY IN
# STAGE_3 (specifically in script verify_icafix_outputs.sh)
#   $NUMSUBS
#   $GICA
#   $DR
#   $CCA_PROC_DATA

if [[ -f $CONFIG ]]; then
    read -p "A config file already exists. Are you sure you want to overwrite it [y/n]? " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # overwrite itss
        echo "Configuration file overwritten."
        echo
        rm $CONFIG
        touch $CONFIG
    else
        # Exit
        echo "NOT overwriting config file."
        exit 1
    fi
else
    # config doesn't exist, so create it
    touch $CONFIG
fi

echo
echo "---ABCD CCA Pipeline Config Setup---"
echo "--PATHS--"
echo "BIDS_PATH=$BIDS_PATH"
echo "NDA_RDS_RAW=$NDA_RDS_RAW"
echo "DCAN_REPROC=$DCAN_REPROC"
echo "DERIVATIVES_PATH=$DERIVATES_PATH"
echo "DATA_PREP=$DATA_PREP"
echo "MAIN_REPO_DATA_FOLDER=$MAIN_REPO_DATA_FOLDER"
echo "PIPELINE_LOG_DIR=$PIPELINE_LOG_DIR"
echo "PREP_LOG=$PREP_LOG"
echo "SUPPORT_SCRIPTS=$SUPPORT_SCRIPTS"
echo "PRE_CENSOR_LENGTHS=$PRE_CENSOR_LENGTHS"
echo "CONFIG=$CONFIG"

echo "STAGE_0_OUT=$STAGE_0_OUT"
echo "STAGE_1_OUT=$STAGE_1_OUT"
echo "STAGE_2_OUT=$STAGE_2_OUT"
echo "STAGE_3_OUT=$STAGE_3_OUT"
echo "STAGE_4_OUT=$STAGE_4_OUT"
echo "STAGE_5_OUT=$STAGE_5_OUT"

echo "FINAL_SUBJECTS=$FINAL_SUBJECTS"
echo "FINAL_SUBJECT_MEASURES=$FINAL_SUBJECT_MEASURES"

echo "PYTHON=$PYTHON"

echo
echo "--VARIABLES--"
echo "TR_INTERVAL=$TR_INTERVAL"
echo "MIN_TPS=$MIN_TPS"
echo "FD_THRESH=$FD_THRESH"
echo "SCAN_FD_THRESH_1=$SCAN_FD_THRESH_1"
echo "SCAN_FD_THRESH_2=$SCAN_FD_THRESH_2"
echo "------------------------------------"

# Now write these variables
echo "BIDS_PATH=$BIDS_PATH" >> $CONFIG
echo "NDA_RDS_RAW=$NDA_RDS_RAW" >> $CONFIG
echo "DCAN_REPROC=$DCAN_REPROC" >> $CONFIG
echo "DERIVATIVES_PATH=$DERIVATES_PATH" >> $CONFIG
echo "DATA_PREP=$DATA_PREP" >> $CONFIG
echo "MAIN_REPO_DATA_FOLDER=$MAIN_REPO_DATA_FOLDER" >> $CONFIG
echo "PIPELINE_LOG_DIR=$PIPELINE_LOG_DIR" >> $CONFIG
echo "PREP_LOG=$PREP_LOG" >> $CONFIG
echo "SUPPORT_SCRIPTS=$SUPPORT_SCRIPTS" >> $CONFIG
echo "PRE_CENSOR_LENGTHS=$PRE_CENSOR_LENGTHS" >> $CONFIG
echo "CONFIG=$CONFIG" >> $CONFIG

echo "STAGE_0_OUT=$STAGE_0_OUT" >> $CONFIG
echo "STAGE_1_OUT=$STAGE_1_OUT" >> $CONFIG
echo "STAGE_2_OUT=$STAGE_2_OUT" >> $CONFIG
echo "STAGE_3_OUT=$STAGE_3_OUT" >> $CONFIG
echo "STAGE_4_OUT=$STAGE_4_OUT" >> $CONFIG
echo "STAGE_5_OUT=$STAGE_5_OUT" >> $CONFIG

echo "FINAL_SUBJECTS=$FINAL_SUBJECTS" >> $CONFIG
echo "FINAL_SUBJECT_MEASURES=$FINAL_SUBJECT_MEASURES" >> $CONFIG

echo "TR_INTERVAL=$TR_INTERVAL" >> $CONFIG
echo "MIN_TPS=$MIN_TPS" >> $CONFIG
echo "FD_THRESH=$FD_THRESH" >> $CONFIG
echo "SCAN_FD_THRESH_1=$SCAN_FD_THRESH_1" >> $CONFIG
echo "SCAN_FD_THRESH_2=$SCAN_FD_THRESH_2" >> $CONFIG

echo "PYTHON=$PYTHON" >> $CONFIG