% abcd_cca.m
% Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020

% CCA processing script for the ABCD connectome and SM data
% Required inputs are the NET.txt and VARS.txt files.

%% Add the dependencies folders to the PATH, and read in necessary data
addpath(genpath('./dependencies/'));
addpath(genpath('./data/'));

% Read in data, set some variables, create confounds matrix
VARS=strcsvread('./data/VARS.csv');  % Subjects X SMs text file
% NET=load('../data/NET.txt');          % Load the Subjects X Nodes matrix (should be size 461x19900)

% Now, change subject ids to just be numbers 0001 to 7810 (needed for hcp2blocks)
% Create the lookup table
sub_lookup_tab = horzcat(VARS(2:end,1),num2cell([1:7810]'))
tmp=horzcat(["subjectid",1:7810]',VARS(:,2:end));
VARS=VARS(2:end,:);

% Number of PCA and CCA components
N_dim=70;
% Number of permutations
N_perm=10;

% Generate permutations using the hcp2blocks package
% EB=hcp2blocks_abcd(tmp, [ ], false, VARS(:,1));
EB=hcp2blocks_abcd(tmp, [ ], false);
PAPset=palm_quickperms([ ], EB, Nperm); % the final matrix of permuations


% Set up confounds matrix. Confounds are demeaned, any missing data is set to 0
% Confounds are:
% 1. abcd_site
% 2. mri_info_manufacturer
% 3. remaining_frame_mean_FD
% 4. anthro_bmi_calc
% 5. anthro_weight_calc
% 6. smri_vol_subcort.aseg_wholebrain
% 7. smri_vol_subcort.aseg_intracranialvolume
% Additional confounds from demeaning and squaring all confounds 3-7
conf=palm_inormal([ VARS(:,[7 8 9 10 11]) VARS(:,[12 13]).^(1/3) ]);   % Gaussianise
conf(isnan(conf)|isinf(conf))=0;                % impute missing data as zeros
conf=nets_normalise([conf conf(:,3:end).^2]);   % add on squared terms and renormalise (additional SMs made from 3-7)
conf(isnan(conf)|isinf(conf))=0;                % again convert NaN/inf to 0 (above line makes them reappear for some reason)

S1=[VARS(:,17:end)]

% Now, prepare the final SM matrix and run the PCA
% S2, formed by gaussianizing the SMs we keep
S2=palm_inormal(S1); % Gaussianise

% Now generate S3, formed by deconfounding the 17 confounds out of S2
S3=S2;
for i=1:size(S3,2) % deconfound ignoring missing data
  grot=(isnan(S3(:,i))==0);
  grotconf=nets_demean(conf(grot,:));
  S3(grot,i)=normalize(S3(grot,i)-grotconf*(pinv(grotconf)*S3(grot,i)));
end

% Determine how much data is missing:
sum(sum(isnan(S3)))/(size(S3,1)*size(S3,2))*100

% Next, we need to generate S4 (461x158 matrix)
% First, estimate the SubjectsXSubjects covariance matrix (where for any two subjects, SMs missing for either subject are ignored)
% The approximate covariance matrix (varsdCOV) is then projected onto the nearest valid covariance matrix using nearestSPD toolbox.
% This method avoids imputation, and S4 can be fed into PCA.
S3Cov=zeros(size(S3,1));
for i=1:size(S3,1) % estimate "pairwise" covariance, ignoring missing data
  for j=1:size(S3,1)
    grot=S3([i j],:);
    grot=cov(grot(:,sum(isnan(grot))==0)');
    S3Cov(i,j)=grot(1,2);
  end
end
S4=nearestSPD(S3Cov); % project onto the nearest valid covariance matrix. This method avoids imputation (we can't have any missing values before running the PCA)

% Check the before and after correlation:
corrcoef(S4,S3Cov)  %0.9999

% Generate S5, the top 100 eigenvectors for SMs, to avoid overfitting and reduce dimensionality
[uu,dd]=eigs(S4,N_dim);       % SVD (eigs actually)
S5=uu-conf*(pinv(conf)*uu);   % deconfound again just to be safe