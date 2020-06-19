#!/usr/bin/env python

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
    if not os.environ['FSLDIR']:
        os.system('module load fsl')

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

def Main(subj,out):
    print(f'Current subject: {subj}')
    if not os.path.isdir(f'{out}/{subj}'):
        os.mkdir(f'{out}/{subj}')

    # set up parameters for censor
    FD_th = [0.2, 0.3]
    seg_len = 5

    # do the things
    runs = find_runs(subj)
    run_fsl_outliers(subj, runs, out)
    censor(out,subj,runs,FD_th,seg_len)


if __name__ == "__main__":
    # parse input
    parser = argparse.ArgumentParser()
    parser.add_argument('-subj',action='store',dest='subj')
    parser.add_argument('-out',action='store',dest='out')
    r = parser.parse_args()
    locals().update(r.__dict__)

    # check output
    if not os.path.isdir(out):
        os.mkdir(out)

    print(f'\nOutput directory: {out}')

    # do the thing
    Main(subj,out)
