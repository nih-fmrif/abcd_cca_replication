% abcd_cca_analysis.m
% Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
% Created: June 2020
% Modified: 7/1/2020

% CCA processing script for the ABCD connectome and SM data
% Required inputs are the NET.txt and VARS.txt files.

%% Add the dependencies folders to the PATH, and read in necessary data
addpath(genpath('./dependencies/'));
addpath(genpath('./data/'));

% Number of PCA and CCA components
N_dim=70;
% Number of permutations
N_perm=100;

% Read in data, set some variables, create confounds matrix
VARS0=strcsvread('./data/VARS_500.txt');   % Subjects X SMs text file
N0=load('./data/NET_500.txt');          % Load the Subjects X Nodes matrix (should be size 461x19900)

sms_0 = fileread('./data/subject_measures.txt')
sms = strsplit(sms_0)

ica_sms_0=fileread('./data/ica_subject_measures.txt')
ica_sms = strsplit(ica_sms_0)

% Drop subject col and device serial number col (they are strings)
egid_col    = find(strcmpi(VARS0(1,:),'subjectid'));
serial_col  = find(strcmpi(VARS0(1,:),'mri_info_device.serial.number'));
VARS0(:,[egid_col serial_col])=[]

site_col        = find(strcmpi(VARS0(1,:),'abcd_site'));
mri_man_col     = find(strcmpi(VARS0(1,:),'mri_info_manufacturer'));
mean_fd_col     = find(strcmpi(VARS0(1,:),'mean_fd'));
bmi_col         = find(strcmpi(VARS0(1,:),'anthro_bmi_calc'));
weight_col      = find(strcmpi(VARS0(1,:),'anthro_weight_calc'));
wholebrain_col  = find(strcmpi(VARS0(1,:),'smri_vol_subcort.aseg_wholebrain'));
intracran_col   = find(strcmpi(VARS0(1,:),'smri_vol_subcort.aseg_intracranialvolume'));

[sharedvals,idx]=intersect(VARS0(1,:),ica_sms)
sms_original_order = VARS0(1,:)

VARS=cell2mat(VARS0(2:end,:));

% --- GENERATE PERMUTATIONS ---
% Generate permutations using the hcp2blocks package
% EB=hcp2blocks_abcd(tmp, [ ], false, VARS(:,1));
% blocksfile='./data/blocksfile.csv';
% [EB,tab] = abcd2blocks('./data/VARS.txt',blocksfile)
% PAPset=palm_quickperms([ ], EB, N_perm); % the final matrix of permuations

% Now, change subject ids to just be numbers 0001 to 7810 (needed for hcp2blocks)
% Create the lookup table
% sub_lookup_tab = horzcat(VARS(2:end,1),num2cell([1:7810]'))
% tmp=horzcat(["subjectid",1:7810]',VARS(:,2:end));
% VARS=VARS(2:end,:);


% --- CREATE CONFOUND MATRIX ---
% Set up confounds matrix. Confounds are demeaned, any missing data is set to 0
% Confounds are:
% 1. abcd_site
% 2. mri_info_manufacturer
% 3. mean_fd
% 4. anthro_bmi_calc
% 5. anthro_weight_calc
% 6. smri_vol_subcort.aseg_wholebrain
% 7. smri_vol_subcort.aseg_intracranialvolume 
% Additional confounds from demeaning and squaring all confounds 3-7
% [site_col mri_man_col mean_fd_col bmi_col weight_col]
% [wholebrain_col intracran_col]
conf=palm_inormal([ VARS(:,[site_col mri_man_col mean_fd_col bmi_col weight_col]) VARS(:,[wholebrain_col intracran_col]).^(1/3) ]);   % Gaussianise
conf(isnan(conf)|isinf(conf))=0;                % impute missing data as zeros
conf=nets_normalise([conf conf(:,3:end).^2]);   % add on squared terms and renormalise (additional SMs made from 3-7)
conf(isnan(conf)|isinf(conf))=0;                % again convert NaN/inf to 0 (above line makes them reappear for some reason)


% --- SM PROCESSING ---
% Matrix S1 (only ICA sms)
S1=[VARS(:,idx)];

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

% Next, we need to generate S4
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

% Generate S5, the top eigenvectors for SMs, to avoid overfitting and reduce dimensionality
[uu,dd]=eigs(S4,N_dim);       % SVD (eigs actually)
S5=uu-conf*(pinv(conf)*uu);   % deconfound again just to be safe



% --- NETMAT PROCESSING ---
fprintf("Calculating netmat matrices N1 through N5\n")
% N1, formed by 1. demean, 2. globally variance normalize
N1=nets_demean(N0);   % 1. Demean
N1=N1/std(N1(:));     % 2. variance normalize
% N2, formed by 1. Demean, 2. remove columns that are badly conditions due to low z (z<0.1) mean value, 3. global variance normalize the matrix
abs_mean_NET=abs(mean(N0));                             % get mean, take abs val
N2=nets_demean(N0./repmat(abs_mean_NET,size(N0,1),1));  % 1. demean
N2(:,abs_mean_NET<0.1)=[];                              % 2. remove columns with mean value <0.1                          
N2=N2/std(N2(:));                                       % 3. variance normalize
% N3, formed by horizontally concat N1 and N2
N3=[N1 N2]; % Concat horizontally
% N4, formed by regressing the confounds matrix out of N3
N4=nets_demean(N3-conf*(pinv(conf)*N3));
% N5
[N5,ss1,vv1]=nets_svds(N4,N_dim); % PCA of netmat via SVD reduction



% --- CCA ---
fprintf("Running CCA on matrices S5 and N5\n")
[grotA,grotB,grotR,grotU,grotV,grotstats]=canoncorr(N5,S5);

%% Calculate CCA Mode 1 weights for netmats and SMs
% Netmat weights for CCA mode 1
grotAA = corr(grotU(:,1),N0)';
 % or
grotAAd = corr(grotU(:,1),N4(:,1:size(N0,2)))'; % weights after deconfounding

%%% SM weights for CCA mode 1
grotBB = corr(grotV(:,1),palm_inormal(S1),'rows','pairwise');
 % or 
varsgrot=palm_inormal(S1);
for i=1:size(varsgrot,2)
  grot=(isnan(varsgrot(:,i))==0); grotconf=nets_demean(conf(grot,:)); varsgrot(grot,i)=nets_normalise(varsgrot(grot,i)-grotconf*(pinv(grotconf)*varsgrot(grot,i)));
end
grotBBd = corr(grotV(:,1),varsgrot,'rows','pairwise')'; % weights after deconfounding

scatter(grotU(:,1),grotV(:,1))



% --- PositiveNegative Axis ---

%%% actually this is the CORRECT thing to do (instead of CorCCA below) - but makes almost no difference
%varsgrot=inormal(vars);
%for i=1:size(varsgrot,2)
%  grot=(isnan(varsgrot(:,i))==0); grotconf=demean(conf(grot,:)); varsgrot(grot,i)=normalise(varsgrot(grot,i)-grotconf*(pinv(grotconf)*varsgrot(grot,i)));
%end
%CorCCAd = corr(grotV(:,I),varsgrot)';

I=1;

CorCCA=corr(grotV(:,I), palm_inormal(VARS), 'rows','pairwise');
figure; plot(CorCCA);   % correlate CCA component 1 with original set of SMs

ZCCA=12*0.5*log((1+CorCCA)./(1-CorCCA));    % r2z  -  factor x12 gets close to "real" zstats. Bonferroni gives significance at abs(Z)>3.9
[grotY,grotI]=sort(CorCCA,'ascend'); 
toplist=[];
strlist={};

% Iterate over the SMs
for i=1:length(grotI)

  % Since we sort the values, we use ii to index into the unsorted list and get the proper index of the column from VARS
  ii=grotI(i);

  % Pull the values for the column associated with the SM being looked at
  Y=VARS(:,ii);
  grotKEEP=~isnan(Y);
  Y=nets_demean(Y(grotKEEP));
  X=nets_demean(grotV(grotKEEP,I));
  VarExplained(ii)=var(X*(pinv(X)*Y)) / var(Y);


  if abs(grotY(i))>0.1
    BVname = string(sms_original_order(ii))
    toplist=[toplist ii];
    str=sprintf('%.2f %.2f %.2f %s %s',CorCCA(ii),ZCCA(ii),VarExplained(ii),BVname);
    strlist{end+1} = str;
    disp(str);
  end
  
end

x=ones([length(toplist),1]);
dx=0.1;
y=1:length(toplist);
dy=0.1;
set(0,'DefaultTextInterpreter','none')
scatter(x,y);
text(x+dx, y+dy, strlist);