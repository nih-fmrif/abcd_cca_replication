#!/usr/bin/python3

# Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
# This script is used to pull the mean frame displacement (along with other fields) for subjects for a given FD threshold
# Please note that this script expects a .mat file with version 5.0, and MAY NOT WORK OTHERWISE!

# We pull motion data from these files:
# sub-<NDAR ID>_ses-baselineYear1Arm1_task-rest_desc-filtered_motion_mask.mat

import numpy as np
import matplotlib.pyplot as plt
from matplotlib import colors
from matplotlib.ticker import PercentFormatter
import os
import sys
import scipy.io as spio
import datetime

# https://stackoverflow.com/questions/7008608/scipy-io-loadmat-nested-structures-i-e-dictionaries
def custom_loadmat(filename):
    '''
    this function should be called instead of direct spio.loadmat
    as it cures the problem of not properly recovering python dictionaries
    from mat files. It calls the function check keys to cure all entries
    which are still mat-objects
    '''
    def _check_keys(d):
        '''
        checks if entries in dictionary are mat-objects. If yes
        todict is called to change them to nested dictionaries
        '''
        for key in d:
            if isinstance(d[key], spio.matlab.mio5_params.mat_struct):
                d[key] = _todict(d[key])
        return d

    def _todict(matobj):
        '''
        A recursive function which constructs from matobjects nested dictionaries
        '''
        d = {}
        for strg in matobj._fieldnames:
            elem = matobj.__dict__[strg]
            if isinstance(elem, spio.matlab.mio5_params.mat_struct):
                d[strg] = _todict(elem)
            elif isinstance(elem, np.ndarray):
                d[strg] = _tolist(elem)
            else:
                d[strg] = elem
        return d

    def _tolist(ndarray):
        '''
        A recursive function which constructs lists from cellarrays
        (which are loaded as numpy ndarrays), recursing into the elements
        if they contain matobjects.
        '''
        elem_list = []
        for sub_elem in ndarray:
            if isinstance(sub_elem, spio.matlab.mio5_params.mat_struct):
                elem_list.append(_todict(sub_elem))
            elif isinstance(sub_elem, np.ndarray):
                elem_list.append(_tolist(sub_elem))
            else:
                elem_list.append(sub_elem)
        return elem_list
    data = spio.loadmat(filename, struct_as_record=False, squeeze_me=True)
    return _check_keys(data)

cwd = os.getcwd()

filepath = os.path.join(cwd,'data/mat_files.txt')   # path to mat_files.txt (a text file with a list of paths to .mat files)
FD = 0.30   # frame displacement threshold of interest (ex. 0.xx) (range 0.00 to 0.50)

fp = os.path.join(cwd,'data/motion_summary_data.csv')
fout1 = open(fp, 'a')
fout1.write("sub,total_frame_count,remaining_frame_count,remaining_seconds,remaining_frame_mean_FD\n")

fp = os.path.join(cwd,'data/mean_FDs.txt')
fout2 = open('data/mean_FDs.txt','a')    # just the mean FD data

print("Pulling motion data, please be patient..\n")
i=0
file_list = [line.rstrip('\n') for line in open(filepath)]
for fp in file_list:
    mat_contents = custom_loadmat(fp)           # load the .mat file (Version 5.0)
    motion_data = mat_contents['motion_data']   # array of mat_struct objects, need to iterate over them

    for struct in motion_data:
        # Now we can access the data like a matlab structure
        if struct.FD_threshold == FD:
            # found the correct structure for FD threshold

            # pull the subject id from each filepath
            # ex. path/to/the/sub-<NDAR_ID>_ses-baselineYear1Arm1_task-rest_desc-filtered_motion_mask.mat
            # this extracts just <NDAR_ID>
            sub = fp.split('/')[-1].split('_')[0].split('-')[-1]

            print_str = '{},{},{},{},{}\n'.format(
                                            sub,
                                            struct.total_frame_count, 
                                            struct.remaining_frame_count, 
                                            struct.remaining_seconds,
                                            struct.remaining_frame_mean_FD)
            fout1.write(print_str)
            fout2.write('{}\n'.format(struct.remaining_frame_mean_FD))

            # Finally, save the censoring data for this subject
            # data is in struct.frame_removal
            censor_list = list(struct.frame_removal)
            censor_out = "censoring_data/"+sub+"_censor.txt"
            np.savetxt(os.path.join(cwd,censor_out), list(struct.frame_removal), fmt="%d")

        else:
            continue
    
    i+=1

print("Finished extracting data for %d subjects.\n" % i)

fout1.close()
fout2.close()

fp = os.path.join(cwd,'log.txt')
f_log = open(fp, 'a')
f_log.write("--- RESULTS OF pull_motion_data_1.py ---\n")
f_log.write('%s\n' % datetime.datetime.now())
f_log.write("Extracted data for :\t%d subjects\n" % i)
f_log.close()