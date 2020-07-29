#! /bin/bash

# run_melodic.sh
# Created: 7/27/20 (pipeline_version_1.5)
# Updated:

# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
# NOTE, This was written for use on the NIH BIOWULF, and MAY NOT FUNCTION PROPERLY ON OTHER SYSTEMS.

# Expected tools on PATH:
# FSL

# Example usage:
#   ./run_melodic.sh

# Check for fsl
fsl_exec=$(which fsl)
 if [ ! -x "$fsl_exec" ] ; then
    echo "Error - FSL is not on PATH. Exiting"
    exit 1
 fi

ABCD_CCA_REPLICATION=$1
if [[ -f $ABCD_CCA_REPLICATION/pipeline.config ]]; then
    # config exists, so run it
    # This will load BIDS_PATH, DERIVATIVES_PATH, DATA_PREP variables
    . $ABCD_CCA_REPLICATION/pipeline.config
else
    echo "$ABCD_CCA_REPLICATION/pipeline.config does not exist! Please run create_config.sh."
    exit 1
fi

# Get final paths to the NIFTI inputs
find $STAGE_3_OUT/NIFTI/ -type f -name "*.nii.gz" | sort | >> $STAGE_3_OUT/paths_to_NIFTI_files.txt

echo "run_melodic.sh - Running MELODIC"
echo "WARNING: This script was designed to be run the NIH Biowulf, and may not work on other systems."

# The first portion of the command loads our pipeline.config.
# $STAGE_3_OUT/paths_to_NIFTI_files.txt points to a text file with absolute paths to the censored+truncated NIFTI files for input to MELODIC.
# The variable $GICA points to the melodic output folder (inside data_prep/).

melodic -i $STAGE_3_OUT/paths_to_NIFTI_files.txt -o $GICA -m /usr/local/apps/fsl/6.0.1/data/standard/MNI152_T1_2mm_brain_mask_dil1.nii.gz --nobet -a concat --tr=$TR_INTERVAL --Oall -d 200



