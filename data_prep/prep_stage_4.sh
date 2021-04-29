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
# check for FSL
 fsl_exec=$(which fsl)
 if [ ! -x "$fsl_exec" ] ; then
    echo "Error - FSL is not on PATH. Exiting"
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

# Check if the following folders exists, else make folder structure
STAGE_4_OUT=$DATA_PREP/data/stage_4/
if [[ -d $STAGE_4_OUT ]]; then
    :
else
    mkdir -p $STAGE_4_OUT/$NUMSUBS/
    mkdir -p $STAGE_4_OUT/swarm_logs/
fi

# STEP 1 - FSLNets to generate subject-level connectomes
echo "Generating subject-level connectomes using FSLNets. This may take a while (6-8 hours)."
# echo "stage_4_out=$STAGE_4_OUT/$NUMSUBS/"
# echo "gica_path=$GICA"
# echo "dr_path=$DR"
matlab -nodisplay -nodesktop -nojvm -r "stage_4_out='$STAGE_4_OUT/$NUMSUBS/';gica_path='$GICA';dr_path='$DR';abcd_cca_dir='$ABCD_CCA_REPLICATION';n_subs_in='$NUMSUBS';run $SUPPORT_SCRIPTS/stage_4/abcd_netmats.m"

# STEP 2 - Generate the NET matrix
echo "Generating the aggregated subject connectome matrix."
$PYTHON $SUPPORT_SCRIPTS/stage_4/NET.py $STAGE_4_OUT/$NUMSUBS/raw_netmats_001.txt 200 $NUMSUBS $STAGE_3_OUT/paths_to_NIFTI_files.txt $FINAL_SUBJECTS $MAIN_REPO_DATA_FOLDER/$NUMSUBS/NET.txt

# STEP 3 - Generate VARS matrix
echo "Generating the finalized subject measure matrix."
$PYTHON $SUPPORT_SCRIPTS/stage_4/VARS.py $FINAL_SUBJECTS $FINAL_SUBJECT_MEASURES $STAGE_2_OUT/subjects_mean_fds.txt $STAGE_2_OUT/VARS_no_motion.txt $MAIN_REPO_DATA_FOLDER/$NUMSUBS/