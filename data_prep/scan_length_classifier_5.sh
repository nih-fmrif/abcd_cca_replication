#! /bin/bash

# Scan length crawler
# Tool does the following:
#   1.  Iterates over the scans (raw data) for all subjects, and determines how long their scans are (stores as one file per subject)
#       [generate file: NDARINVxxxxxxx_scan_lengths.txt]
#   2.  Determines a group average scan length (omitting scans with length < 50, based on observation these scans fail the ICA+FIX high pass stage)
#   3.  Based on group average scan length calculated, it will classify scans as 0 (exclude, scan length < 0.75*380)
#       or 1 (include, scan length >= 0.75*380) [generate file: NDARINVxxxxxxx_scan_classified.txt]
#   4.  Based on the scan lengths [NDARINVxxxxxxx_scan_lengths.txt] and scan include/exclude [NDARINVxxxxxxx_scans_to_use.txt] clean their censor file
#       (this calls a separate script called clean_censors.py, input is a list of subjects)
# Based on scan length, scans will be classified as 0 for exclude (scan has less than ), 1 for include.

# NOTE: this script must be called from the abcd_cca_replicaton/data_prep/ folder

# Inputs:
#   1. Absolute path to location of the sub-NDARINVxxxxxxxx/ RAW data folders (/data/ABCD_MBDU/abcd_bids/bids/)
#   2. Absolute path to location of the sub-NDARINVxxxxxxxx/ PROCCESSED data folders (/abcd_bids/bids/derivatives/dcan_reproc/)

# function average_scan_len {
# PYTHON_ARG="$1" python - <<END
# import os
# with open(os.environ['PYTHON_ARG'],'r') as f:
#     data = [float(line.rstrip()) for line in f.readlines()]
#     f.close()
# mean = float(sum(data))/len(data) if len(data) > 0 else float('nan')
# print(int(mean))
# END
# }

show_usage(){
    echo "usage scan_length_classifier_5.sh <absolute/path/to/folder/with/RAW/subjectdata/> <absolute/path/to/folder/with/PROCESSED/subjectdata/>"
}
show_example(){
    echo "usage scan_length_classifier_5.sh /data/ABCD_MBDU/abcd_bids/bids/ /data/ABCD_MBDU/abcd_bids/bids/derivatives/dcan_reproc/"
}

# Verbose output (debugging)
set -x

RAWDATA_PATH=$1
PROCDATA_PATH=$2

if (( $# < 2 ))
then
    show_usage
    show_example
	exit 1
fi

if [[ -d $PWD/data/scan_length_proc/ ]]; then
    rm -r $PWD/data/scan_length_proc/
else
    mkdir $PWD/data/scan_length_proc/
fi
# Data working dir
DATAFOLDER=$PWD/data/scan_length_proc/

# Get a list of the raw data folders (these are absolute paths since $RAWDATA_PATH is an absolute path)
find $RAWDATA_PATH -maxdepth 1 -type d -name "sub-NDARINV*" >> $DATAFOLDER/rawdata_folder_paths.txt

# Now, iterate over the subjects and collect their scan length data (this can collect data for scans labeled 00 to 99, assumes 2 digit naming convention)
echo "Fetching scan length data for each subject and classifying scans for inclusion/exclusion."
while read raw_path
do
    # Pull subjectid from the given path (format sub-NDARINVxxxxxxxx, and truncated format NDARINVxxxxxxxx)
    sub_id=${raw_path##*/}
    sub_id_noprefix=$(echo $sub_id | cut -d"-" -f2)

    # summary file, all subject ids + scan lengths
    echo $sub_id >> $PWD/data/timepoints_subs.txt

    # Pull scan lengths from all available scans (format sub-NDARINVFL02R0H4_ses-baselineYear1Arm1_task-rest_run-[0-9][0-9]_bold.nii.gz)
    # Note, values are written to file in ascending order (i.e. scan 1 length on line one, scan 2 on line 2, etc...)
    find $raw_path/ses-baselineYear1Arm1/func/ -type f -name "*task-rest_run*[0-9][0-9]_bold.nii.gz" | sort | -exec fslnvols {} \; tee -a $DATAFOLDER/timepoints_subs.txt | tee -a $DATAFOLDER/timepoints_no_subs.txt | tee $PWD/censoring_data/${sub_id_noprefix}_scan_lengths.txt

    # Create classifier file for each subject
    count=1
    while read len
    do
        if [[ $len -lt 285 ]]; then
            echo 0 >> $PWD/censoring_data/${sub_id_noprefix}_scans_classified.txt.txt
            echo $sub_id >> $DATAFOLDER/subjects.txt
        elif [[ $len -ge 285 ]]; then
            echo 0 >> $PWD/censoring_data/${sub_id_noprefix}_scans_classified.txt.txt
            echo $sub_id >> $DATAFOLDER/subjects.txt
        else
            echo "An error occured classifying scan $count for subject $sub_id"
            echo "ERR" >> $PWD/censoring_data/${sub_id_noprefix}_scans_classified.txt
        fi
        ((count++))
    done < $PWD/censoring_data/${sub_id_noprefix}_scan_lengths.txt

done < $DATAFOLDER/rawdata_folder_paths.txt
echo "Lengths acquired, now cleaning censor files for all subjects available"

# Now that scans are classified, clean the censors for subjects
python clean_censors.py $DATAFOLDER/subjects.txt