#!/usr/bin/env python
# This script takes a subject ID and FD threshold and:
# 1. Grabs all rest runs that exist for the subject (raw data directory is currently hard coded)
# 2. Runs fsl_motion_outliers to generate the fdrms file: https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FSLMotionOutliers
# 3. Creates a censor file where timepoints are removed if:
#        - TR > FD_thresh
#        - segment length is < seg
# 4. Writes censor files and the number of surviving TRs for each run to text
#
# usage: abcd_censor.py -subj <subjectID> -FD_th <threshold> -seg <segment_length> -out <output directory>
# inputs: subjectID, as it exists in the raw data directory (eg, sub-NDARINVCLL3TR97)
#         FD_th: motion threshold (in mm) (eg 0.3)
#         seg: segment length (segments less than seg will be censored) (eg 5)
#         output directory structure:
#           output_directory/
#                   <subjectID>/  (will be created if it doesn't exists)
#                         good_TRs_<FD_th>mm.censor.txt: numebrs of uncensored TRs for each run. One run per row.
#                         run-XX_fdrms.txt: head motion data from fsl_motion_outliers
#                         run-XX_<FD_th>mm.censor.txt: censor file for each run

import numpy as np
from glob import glob
import argparse
import os
import sys

def find_runs(subj):
    # find all of the rest runs for the subject
    runs = []
    bold = glob(f'/data/ABCD_MBDU/abcd_bids/bids/{subj}/ses-baselineYear1Arm1/func/*task-rest_run-*_bold.nii.gz')
    for b in bold:
        r = b.split('run-')[1].split('_')[0]
        runs.append(r)

    return runs

def run_fsl_outliers(subj,runs,out):
    print('Running fsl_motion_outliers...')

    data_in = f'/data/ABCD_MBDU/abcd_bids/bids/{subj}/ses-baselineYear1Arm1/func'
    for r in runs:
        print(f'  Run: {r}')
        if not os.path.isfile(f'{out}/{subj}/run-{r}_fdrms.txt'):
            cmd = f'fsl_motion_outliers -i {subj}_ses-baselineYear1Arm1_task-rest_run-{r}_bold.nii.gz -o {out}/{subj}/run-{r}_fdconfound.txt -s {out}/{subj}/run-{r}_fdrms.txt --fdrms -v'
            os.chdir(data_in)
            os.system(cmd)
        else:
            print(f'  run-{r}_fdrms.txt already exists')

        # clean up, we don't need confound files here
        cf = f'{out}/{subj}/run-{r}_fdconfound.txt'
        if os.path.isfile(cf):
            os.remove(cf)

def censor(out,subj,runs,FD_th,seg_len):
    print('Creating censor files for each run...')
    for th in FD_th:
        # container for number of good timepoints
        summary = []
        th = float(th)
        seg_len = int(seg_len)
        cen = str(th)

        for r in runs:
            # read in FD file
            FD_file = np.loadtxt(f'{out}/{subj}/run-{r}_fdrms.txt')

            # find timepoints that exceed thresholds
            FD_censor_vec = (FD_file <= th).astype(int)
            
            # find the segments
            segs = np.diff(np.pad(FD_censor_vec,1))
            seg_srt = np.where(segs == 1)[0]
            seg_end = np.where(segs == -1)[0]-1
            
            # if segment < discard seg_length, set to 0
            for idx, val in enumerate(seg_srt):
                if (seg_end[idx]-seg_srt[idx]+1) < seg_len:
                    FD_censor_vec[seg_srt[idx]:seg_end[idx]+1] = 0

            # write censor to file and grab number of timepoints
            np.savetxt(f'{out}/{subj}/run-{r}_{cen}mm.censor.txt', FD_censor_vec, fmt='%1.0f')
            summary.append(sum(FD_censor_vec))

        with open(f'{out}/{subj}/good_TRs_{cen}mm.censor.txt', 'w') as f:
            for line in summary:
                f.write(f'{line}\n')        

def Main(subj,out,FD_th,seg):
    print(f'Current subject: {subj}')
    if not os.path.isdir(f'{out}/{subj}'):
        os.mkdir(f'{out}/{subj}')

    # do the things
    FD_th = [FD_th]
    runs = find_runs(subj)
    run_fsl_outliers(subj, runs, out)
    censor(out,subj,runs,FD_th,seg)


if __name__ == "__main__":
    # parse input
    parser = argparse.ArgumentParser()
    parser.add_argument('-subj',action='store',dest='subj')
    parser.add_argument('-FD_th',action='store',dest='FD_th')
    parser.add_argument('-seg',action='store',dest='seg')
    parser.add_argument('-out',action='store',dest='out')
    r = parser.parse_args()
    locals().update(r.__dict__)

    # check for FSL
    try:
        os.environ['FSLDIR']
    except:
        print('\nFSL must be in your path, try:\n> module load fsl\n')
        sys.exit(-1)

    # check output
    if not os.path.isdir(out):
        os.mkdir(out)

    print(f'\nOutput directory: {out}')

    # do the thing
    Main(subj,out,FD_th,seg)
