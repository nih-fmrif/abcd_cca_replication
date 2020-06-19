#! /bin/bash

# create_config.sh
# Created: 6/15/20
# Updated:

usage()
{
	echo "usage: create_config.sh <path/to/main/abcd_bids/bids/>"
    echo "NOTE you must provide the ABSOLUTE PATH to the main directory of the ABCD collection 3165 download. for example: /data/ABCD/abcd_bids/bids/"
}

if (( $# < 1 ))
then
    usage
	exit 1
fi

BIDS_PATH=$1
NDA_RDS_RAW=$2
DERIVATES_PATH=$BIDS_PATH/derivatives/abcd-hcp-pipeline/
DATA_PREP=$PWD/data_prep/
MAIN_REPO_DATA_FOLDER=$PWD/data/
PIPELINE_LOG_DIR=$DATA_PREP/logs/
PREP_LOG=$DATA_PREP/logs/prep_log.txt
SUPPORT_SCRIPTS=$DATA_PREP/support_scripts/
CENSOR_FILES=$PWD/data_prep/censor_files/
CENSOR_FILES_CLEAN=$PWD/data_prep/censor_files_clean/
CONFIG=$PWD/pipeline.config

echo
echo "---ABCD CCA Pipeline Config Setup---"
echo "BIDS_PATH=$BIDS_PATH"
echo "NDA_RDS_RAW=$NDA_RDS_RAW"
echo "DERIVATIVES_PATH=$DERIVATES_PATH"
echo "DATA_PREP=$DATA_PREP"
echo "MAIN_REPO_DATA_FOLDER=$_MAIN_REPO_DATA_FOLDER"
echo "PIPELINE_LOG_DIR=$PIPELINE_LOG_DIR"
echo "PREP_LOG=$PREP_LOG"
echo "SUPPORT_SCRIPTS=$SUPPORT_SCRIPTS"
echo "CENSOR_FILES=$CENSOR_FILES"
echo "CENSOR_FILES_CLEAN=$CENSOR_FILES_CLEAN"
echo "CONFIG=$CONFIG"
echo "------------------------------------"

if [[ -f $CONFIG ]]; then
    read -p "A config file already exists. Are you sure you want to overwrite it? " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # overwrite it
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

# Now write these variables
echo "BIDS_PATH=$BIDS_PATH" >> $CONFIG
echo "NDA_RDS_RAW=$NDA_RDS_RAW" >> $CONFIG
echo "DERIVATIVES_PATH=$DERIVATES_PATH" >> $CONFIG
echo "DATA_PREP=$DATA_PREP" >> $CONFIG
echo "MAIN_REPO_DATA_FOLDER=$MAIN_REPO_DATA_FOLDER" >> $CONFIG
echo "PIPELINE_LOG_DIR=$PIPELINE_LOG_DIR" >> $CONFIG
echo "PREP_LOG=$PREP_LOG" >> $CONFIG
echo "SUPPORT_SCRIPTS=$SUPPORT_SCRIPTS" >> $CONFIG
echo "CENSOR_FILES=$CENSOR_FILES" >> $CONFIG
echo "CENSOR_FILES_CLEAN=$CENSOR_FILES_CLEAN" >> $CONFIG
echo "CONFIG=$CONFIG" >> $CONFIG