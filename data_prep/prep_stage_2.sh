#! /bin/bash

# prep_stage_2.sh
# Created: 6/16/20
# Updated: 6/20/20 (pipeline_version_1.2)

# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020

# Expected tools on PATH:
# R

# Example usage:
#   ./prep_stage_2.sh

# usage()
# {
# 	echo "usage: prep_stage_2.sh <path/to/nda2.0.1.Rds/>"
#     echo "NOTE you must provide the ABSOLUTE PATH to the NDA RDS file nda2.0.1.Rds (or whichever version is being used)"
# }

# if (( $# < 1 ))
# then
#     usage
# 	exit 1
# fi

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
STAGE_2_OUT=$DATA_PREP/data/stage_2/
if [[ -d $STAGE_2_OUT ]]; then
    rm $STAGE_2_OUT/*.txt
else
    mkdir $STAGE_2_OUT
fi


echo
echo "--- PREP_STAGE_2 ---"
echo "$(date) - START"



echo "$(date) - STOP" >> $PREP_LOG
echo "--- END STAGE 2 LOG ---" >> $PREP_LOG
echo "" >> $PREP_LOG
echo