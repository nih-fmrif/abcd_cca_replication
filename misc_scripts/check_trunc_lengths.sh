#! /bin/bash

# check_trunc_lengths.sh
# Created: 7/7/20
# Updated:

# Script to verify that subject scans are the proper length (specified as argument) in TIMEPOINTS
# e.c. 750 tps == 600 seconds for TR=0.8


fsl_exec=$(which fsl)
 if [ ! -x "$fsl_exec" ] ; then
    echo "Error - FSL is not on PATH. Exiting"
    exit 1
 fi

# path to txt file with absolute paths to the censored+truncated scans
files=$1

# desired tps threshold
tps=$2

count=0
while read file; do

    scan_len=$(fslnvols $file)

    if [ $scan_len -ne $tps ]; then
        echo "ERROR, $file length NOT $tps"
        ((count++))
    fi
    
done < $files

if [ $count -gt 0 ]; then
    echo "$count subjects with incorrect number of tps"
else
    echo "all subjects have proper number of tps"
fi