#! /bin/bash

# run_dual_regression.sh
# Created: 7/27/20 (pipeline_version_1.5)
# Updated:

# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
# NOTE, This was written for use on the NIH BIOWULF, and MAY NOT FUNCTION PROPERLY ON OTHER SYSTEMS.

# Expected tools on PATH:
# FSL

# Example usage:
#   ./run_dual_regression.sh /data/NIMH_scratch/abcd_cca/abcd_cca_replication/

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

echo "run_dual_regression.sh - Running dual_regression"
echo "WARNING: This script was designed to be run the NIH Biowulf where dual_regression is AUTOMATICALLY SWARMED, and may not work on other systems."

# Need to split up the job into 1000 subject sub-jobs
# Step 1 - Split up the paths file into 1000 subject sub-jobs, and create an associated file with just subject IDs (needed later when we make our aggregated connectome matrix)
# split -l 1000 -d $STAGE_3_OUT/paths_to_NIFTI_files.txt $STAGE_3_OUT/split_paths_

# path_files=$STAGE_3_OUT/split_paths_*

# export FSL_MEM=32 
# count=0
# for path_f in path_files
# do
#     # submit a dual_regression job for each paths file
#     dual_regression $GICA/melodic_IC 1 -1 0 $STAGE_3_OUT/dr_$count.dr `cat $path_f`
#     ((count++))
# done

echo "Calling the following command:"
echo "      export FSL_MEM=64 && export FSL_QUEUE=norm && dual_regression $GICA/melodic_IC 1 -1 0 $DR \`cat $STAGE_3_OUT/paths_to_NIFTI_files.txt\`"

export FSL_MEM=64 && export FSL_QUEUE=norm && dual_regression $GICA/melodic_IC 1 -1 0 $DR `cat $STAGE_3_OUT/paths_to_NIFTI_files.txt`