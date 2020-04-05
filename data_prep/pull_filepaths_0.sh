#! /bin/bash

# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
# pull_filepaths_0.sh - a script to determine subjects who have the resting state timeseries and motion .mat files for MELODIC group-ICA processing

# Run this function while INSIDE the data_prep/ folder in which resides
# You must have the Connectome Workbench software on path

# Example usage:
#   ./pull_filepaths_0.sh -d /data/ABCD_MBDU/abcd_bids/bids -o data/

##### Functions
usage()
{
	echo "usage: pull_filepaths_0.sh -d <path/to/main/abcd_bids/> -o </path/to/abcd_cca_replication/data_prep/data>"
    echo "NOTE you must provide the ABSOLUTE PATH to the main directory of the ABCD collection 3165 download. for example: /data/ABCD/abcd_bids/bids/"
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
if test -f data/all_release_subjects.txt; then
    rm data/all_release_subjects.txt
fi
if test -f data/rsfMRI_files.txt; then
    rm data/rsfMRI_files.txt
fi
if test -f data/motion_mat_files.txt; then
    rm data/motion_mat_files.txt
fi
if test -f data/subjects_with_files.txt; then
    rm data/subjects_with_files.txt
fi
if test -f data/subjects_missing_files.txt; then
    rm data/subjects_missing_files.txt
fi

# Generate a list of ALL subjects who are present in the ABCD derivatives folder(ex. sub-NDARINVZN4F9J96)
ls $BIDS_PATH/derivatives/abcd-hcp-pipeline | grep sub- > data/all_release_subjects.txt
ALLNUMSUBS=$(cat data/all_release_subjects.txt| wc -l)

echo "Generating a list of subjects with task-rest_bold_desc-filtered_timeseries.dtseries.nii (CIFTI) and motion .mat files available..."
while read sub; do
    # Get absolute path for their sub-<subject_ID>_ses-baselineYear1Arm1_task-rest_bold_desc-filtered_timeseries.dtseries.nii files (CIFTIs)
    tseries=${BIDS_PATH}/derivatives/abcd-hcp-pipeline/${sub}/ses-baselineYear1Arm1/func/${sub}_ses-baselineYear1Arm1_task-rest_bold_desc-filtered_timeseries.dtseries.nii
    matfile=${BIDS_PATH}/derivatives/abcd-hcp-pipeline/${sub}/ses-baselineYear1Arm1/func/${sub}_ses-baselineYear1Arm1_task-rest_desc-filtered_motion_mask.mat
    
    if [[ -f "$tseries" && -f "$matfile" ]]; then
        echo $tseries >> data/rsfMRI_files.txt
        echo $matfile >> data/motion_mat_files.txt
        echo $sub >> data/subjects_with_files.txt
    else
        echo $sub >> data/subjects_missing_files.txt
    fi
done < data/all_release_subjects.txt

# Conversion from CIFTI --> NIFTI
# Before doing conversion, check if the file exists (so this script can be run multiple times, adding the new NIFTI files as they appear in subsequent releases)
NUMSUBS=$(cat data/subjects_with_files.txt| wc -l)
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
    done < data/subjects_with_files.txt
fi

# Finally, log results
echo "--- RESULTS OF pull_filepaths_0.sh ---" >> log.txt
echo $(date) >> log.txt
echo "total subjects in release: $ALLNUMSUBS" >> log.txt
echo "subjects with scan and motion data present: $NUMSUBS" >> log.txt
echo "" >> log.txt