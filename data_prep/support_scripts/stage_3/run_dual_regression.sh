#! /bin/bash

# run_dual_regression.sh
# Created: 7/27/20 (pipeline_version_1.5)
# Updated:

# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
# NOTE, This was written for use on the NIH BIOWULF, and MAY NOT FUNCTION PROPERLY ON OTHER SYSTEMS.

# Expected tools on PATH:
# FSL

# Example usage:
#   ./run_dual_regression.sh

# Check for fsl
fsl_exec=$(which fsl)
 if [ ! -x "$fsl_exec" ] ; then
    echo "Error - FSL is not on PATH. Exiting"
    exit 1
 fi

ABCD_CCA_REPLICATION="$(dirname $PWD | rev | cut -d/ -f3- | rev)"
if [[ -f $ABCD_CCA_REPLICATION/pipeline.config ]]; then
    # config exists, so run it
    # This will load BIDS_PATH, DERIVATIVES_PATH, DATA_PREP variables
    . $ABCD_CCA_REPLICATION/pipeline.config
else
    echo "$ABCD_CCA_REPLICATION/pipeline.config does not exist! Please run create_config.sh."
    exit 1
fi

echo "run_dual_regression.sh - Running dual_regression"
echo "WARNING: This script was designed to be run the NIH Biowulf where dual_regression is AUTOMATICALLY SWARMED, and may not work on other systems."

export FSL_MEM=32 && dual_regression $GICA/melodic_IC 1 -1 0 $DR `cat $FINAL_SUBJECTS`