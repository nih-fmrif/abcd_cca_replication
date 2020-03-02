#! /bin/bash

# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
# melodic_setup.sh - a script to prep the resting state timeseries files for MELODIC group-ICA processing

# Run this function within the melodic/ folder it resides inside.
# Example usage:
#   ./melodic_prep.sh -d /data/ABCD_MBDU/abcd_bids/bids -o outputs/

##### Functions
usage()
{
	echo "usage: melodic_setup.sh -d <path/to/main/abcd_bids/> -o </path/to/melodic outputs>"
    echo "NOTE you must provide the ABSOLUTE PATH to the main directory of the ABCD download. for example: /data/ABCD/abcd_bids/bids/"
}

#### Setup stuff
while getopts ":f:d:o:h" arg; do
    case $arg in
        d) 	BIDS_PATH=$OPTARG;;
        o) 	OUT_PATH=$OPTARG;;
        h) 	usage
            exit 1
            ;;
    esac
done

# Before proceeding, make sure everything we need is present:
path_to_executable=$(which wb_command)
 if [ ! -x "$path_to_executable" ] ; then
    echo "Error - HCP Workbench is not on PATH. Exiting"
    exit 1
 fi

# Check if the output .txt files exist, if so delete because we want to overwrite them
if test -f data/subject_list.txt; then
    rm data/subject_list.txt
fi
if test -f data/CIFTI_files.txt; then
    rm data/CIFTI_files.txt
fi
if test -f data/mat_files.txt; then
    rm data/mat_files.txt
fi
if test -f data/subjects_with_mat_CIFTI.txt; then
    rm data/subjects_with_mat_CIFTI.txt
fi
if test -f data/missing_files.txt; then
    rm data/missing_files.txt
fi

echo "Generating a list of subjects with task-rest_bold_desc-filtered_timeseries.dtseries.nii (CIFTI) files..."
# Generate a list of all subjects who have files in the derivatives folder(ex. sub-NDARINVZN4F9J96)
ls $BIDS_PATH/derivatives/abcd-hcp-pipeline | grep sub- > data/subject_list.txt

while read sub; do
    # Get absolute path for their sub-<subject_ID>_ses-baselineYear1Arm1_task-rest_bold_desc-filtered_timeseries.dtseries.nii files (CIFTIs)
    tseries=${BIDS_PATH}/derivatives/abcd-hcp-pipeline/${sub}/ses-baselineYear1Arm1/func/${sub}_ses-baselineYear1Arm1_task-rest_bold_desc-filtered_timeseries.dtseries.nii
    matfile=${BIDS_PATH}/derivatives/abcd-hcp-pipeline/${sub}/ses-baselineYear1Arm1/func/${sub}_ses-baselineYear1Arm1_task-rest_desc-filtered_motion_mask.mat
    
    if [[ -f "$tseries" && -f "$matfile" ]]; then
        echo $tseries >> data/CIFTI_files.txt
        echo $matfile >> data/mat_files.txt
        echo $sub >> data/subjects_with_mat_CIFTI.txt
    else
        echo $fname >> data/missing_files.txt
    fi
done < data/subject_list.txt

# Conversion from CIFTI --> NIFTI
# Before doing conversion, check if the file exists (so this script can be run multiple times, adding the new NIFTI files as they appear in subsequent releases)
NUMSUBS=$(cat data/subjects_with_mat_CIFTI.txt| wc -l)
read -p "Generate NIFTI files for ${NUMSUBS} subjects, proceed? [y/n]: " -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
else
    # Convert the CIFTI files to NIFTI, and store in the NIFTI folder
    while read sub; do
        fname=${BIDS_PATH}/derivatives/abcd-hcp-pipeline/${sub}/ses-baselineYear1Arm1/func/${sub}_ses-baselineYear1Arm1_task-rest_bold_desc-filtered_timeseries.dtseries.nii
        if test -f "$PWD/NIFTI/$sub.nii"; then
            # This file exists, so skip
            # echo "$PWD/NIFTI/$sub.nii exists"
            true
        else
            wb_command -cifti-convert -to-nifti $fname $PWD/NIFTI/$sub.nii
        fi
    done < data/subjects_with_CIFTI.txt
fi