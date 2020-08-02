#! /bin/bash

# run_slices_summary.sh
# Created: 7/27/20 (pipeline_version_1.5)
# Updated:

# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
# NOTE, This was written for use on the NIH BIOWULF, and MAY NOT FUNCTION PROPERLY ON OTHER SYSTEMah S.

# Expected tools on PATH:
# FSL

# Example usage:
#   ./run_slices_summary.sh

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

echo "run_slices_summary.sh - Running slices_summary"
echo "WARNING: This script was designed to be run the NIH Biowulf, and may not work on other systems."
slices_summary $GICA/melodic_IC 4 /usr/local/apps/fsl/6.0.1/data/standard/MNI152_T1_2mm $GICA/melodic_IC_thick.sum
slices_summary $GICA/melodic_IC 4 /usr/local/apps/fsl/6.0.1/data/standard/MNI152_T1_2mm $GICA/melodic_IC_thin.sum -1

# Or run this line with the [-1] option to do single-slice summary instead of 3 slice summary
# slices_summary $GICA/melodic_IC 4 /usr/local/apps/fsl/6.0.1/data/standard/MNI152_T1_2mm $GICA/melodic_IC.sum -1
