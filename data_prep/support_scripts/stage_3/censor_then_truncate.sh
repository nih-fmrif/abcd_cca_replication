#!/usr/bin/env bash

# Usage: censor_then_truncate.sh -subj <subject ID> -in <input data directory> -cen <censor file directory> -out <output directory>

# parse arguments and prepare
while [[ $# -gt 0 ]]; do
	case "$1" in
		-subj)
			subj=$2
			shift
			shift
		;;
		-in)
			data_in=$2
			shift
			shift
		;;
		-cen)
			cen_dir=$2
			shift
			shift
		;;
		-out)
			out=$2
			shift
			shift
		;;
		-*)
			echo
			echo "ERROR: Unknown option: $1"
			exit 1
		;;
	esac
done


# set input files
clean_file="ses-baselineYear1Arm1/files/MNINonLinear/Results/fix_proc/task-rest_concat_hp2000_clean.nii.gz"
tool_cmd="1d_tool.py -infile $cen_dir/$subj.txt -show_trs_uncensored encoded"

# prepare environment
export TMPDIR=/lscratch/$SLURM_JOB_ID
module load afni

# copy data over
cp $data_in/$subj/$clean_file $TMPDIR

# # apply the censor
3dTcat -prefix $TMPDIR/${subj}_censored.nii.gz $TMPDIR/task-rest_concat_hp2000_clean.nii.gz[`$tool_cmd`]

# truncate to 10 minutes
3dTcat -prefix $out/${subj}_truc.nii.gz $TMPDIR/${subj}_censored.nii.gz[0..749]