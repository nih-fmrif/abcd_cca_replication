#!/usr/bin/python3

# usage: python3 NET.py <path to .txt files with partial parcellations>
# Note, the output file will go same location as the original .txt files with the specified name

import numpy as np
from numpy import genfromtxt
import os
import sys
import pandas as pd

tol=1e-8
in_path="/data/ABCD_MBDU/goyaln2/abcd_cca_replication/data_prep/data/stage_4/5013/raw_netmats_001.txt"
ICA=200
num_subs=5013
input_nifti_file_list="/data/ABCD_MBDU/goyaln2/abcd_cca_replication/data_prep/data/stage_3/paths_to_NIFTI_files.txt"
sub_fp="/data/ABCD_MBDU/goyaln2/abcd_cca_replication/data_prep/data/stage_3/final_subjects.txt"
out_path = "/data/ABCD_MBDU/goyaln2/abcd_cca_replication/data/5013/NET.txt"

def is_symmetric(a):
	return (np.abs(a - a.T) <= tol).all()

in_path = sys.argv[1]	# 	Absolute path to the connectome matrix
ICA = int(sys.argv[2]) 	#	number of ICA components (ex. 200)
num_subs = int(sys.argv[3])
input_nifti_file_list = sys.argv[4]	#	absolute path to the input NIFTI file list fed into melodic and dual_regression (needed to make sure order of subjects is alphabetical)
sub_fp = sys.argv[5]	#	subject list (sorted in alphabetical order)
out_path= sys.argv[6]

# Load the raw connectome matrix
print("Reading in the connectome matrix, this might take a little while...")
netmat_in = pd.read_csv(in_path, header=None)

# STEP 1 - Check if subjects are in the proper order
final_subs = [line.rstrip('\n') for line in open(sub_fp)]
input_nifti_paths = [line.rstrip('\n') for line in open(input_nifti_file_list)]
# First, extract only the subject_id
# Example line: /data/ABCD_MBDU/goyaln2/abcd_cca_replication/data_prep/5013_subjects/NIFTI/sub-NDARINVY0A90FWG_truc.nii.gz
extracted_subject_ids = [line.split("/")[-1].split("_")[0] for line in input_nifti_paths]

if extracted_subject_ids == final_subs:
	# Lists are in same order
	# Can proceed
	print("Connectomes are in proper order, proceeding to create NET matrix.")
	netmat_sorted = netmat
else:
	# Lists are not in same order
	print("Connectomes are not in proper order (subjects are not sorted alphabetically. Correcting this now.")
	sort_index = sorted(range(len(extracted_subject_ids)), key=extracted_subject_ids.__getitem__)
	sorted_list=[]
	for idx in sort_index:
		# Create a new subject list by picking out the entries based on the value of idx
		sorted_list.append(extracted_subject_ids[idx])
		netmat_sorted = netmat_in.reindex(sort_index)
	# Perform final check
	if sorted_list == final_subs:
		print("Subjects have been sorted! Proceeding to create NET matrix.")

expected_cols = int((ICA * (ICA-1))/2)
print('Expected matrix shape: ({}, {})'.format(num_subs, expected_cols))

myList = [] # list of the subject x 200*199/2 matrix enties (the lower diagonal)
col = ICA
# Now, pull out each row from netmat2.txt (each is the flattened 200x200 matrix for each subject), then get the lower tri and flatten it
count=0
for index, row in netmat_sorted.iterrows():
	arr = np.array(row)	# make into a numpy array
	mat = np.array([arr[i:i+col] for i in range(0, len(arr), col)]) 
	print(is_symmetric(mat))
	flat_lower_tri = mat[np.tril(mat, -1) !=0]
	myList.append(flat_lower_tri)
matrix = np.array(myList)
if( (matrix.shape[0]==num_subs) & (matrix.shape[1]==expected_cols) ):
	print("NET Successfully generated! Resulting matrix shape:", matrix.shape)
	np.savetxt(fname=out_path, X=matrix, delimiter=',')
else:
	print('Error occured, resulting matrix shape is: {}, but expected ({},{})'.format(matrix.shape, num_subs, expected_cols))
	print("NET not generated!")