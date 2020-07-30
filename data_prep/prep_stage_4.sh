#! /bin/bash

# prep_stage_4.sh
# Created: 7/24/20 pipeline_version_1.5
# Updated:

# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
# This script will prepare the subject-level netmats and connectome matrix NET, as well as prepare the VARS matrix for CCA

# Expected tools on PATH:
# MATLAB 2020a (NOT TESTED WITH OTHER VERSIONS!)
# FSL

# Example usage:
#   ./prep_stage_4.sh

# Check for MATLAB
matlab_exec=$(which matlab)
 if [ ! -x "$matlab_exec" ] ; then
    echo "Error - MATLAB is not on PATH. Exiting"
    exit 1
 fi


ABCD_CCA_REPLICATION="$(dirname "$PWD")"
if [[ -f $ABCD_CCA_REPLICATION/pipeline.config ]]; then
    # config exists, so run it
    # This will load BIDS_PATH, DERIVATIVES_PATH, DATA_PREP variables
    . $ABCD_CCA_REPLICATION/pipeline.config
else
    echo "$ABCD_CCA_REPLICATION/pipeline.config does not exist! Please run create_config.sh."
    exit 1
fi


# STEP 1 - FSLNets to generate subject-level connectomes
echo "Generating subject-level connectomes using FSLNets. This may take a while."

matlab -nodisplay -nodesktop -nojvm -r "stage_4_out="$STAGE_4_OUT/$NUMSUBS/"; gica_path="$GICA"; dr_path="$DR";  run $SUPPORT_SCRIPTS/stage_4/abcd_netmats.m"

# STEP 2 - Generate the NET matrix
echo "Generating the aggregated subject connectome matrix."

# STEP 3 - Generate VARS matrix
echo "Generating the finalized subject measure matrix."