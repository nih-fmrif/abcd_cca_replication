#!/usr/bin/python3

# usage: python3 NET.py <path to .txt files with partial parcellations>
# Note, the output file will go same location as the original .txt files with the specified name

import numpy as np
from numpy import genfromtxt
import os
import sys
import pandas as pd

def is_symmetric(a):
	return (np.abs(a - a.T) <= tol).all()

in_path = sys.argv[1]
ICA = int(sys.argv[2]) #number of ICA components (ex. 200)
num_subs = int(sys.argv[3])
out_path= sys.argv[4]

expected_cols = int((ICA * (ICA-1))/2)

print('Expected matrix shape: ({}, {})'.format(num_subs, expected_cols))

netmat = pd.read_csv(in_path, header=None)

myList = [] # list of the subject x 200*199/2 matrix enties (the lower diagonal)
col = 200

# Now, pull out each row from netmat2.txt (each is the flattened 200x200 matrix for each subject), then get the lower tri and flatten it
count=0
for index, row in netmat.iterrows():
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