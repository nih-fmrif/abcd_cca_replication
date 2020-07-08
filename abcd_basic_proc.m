% abcd_basic_proc.m
% Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
% Created: June 2020
% Modified: 7/1/2020

% CCA processing script for the ABCD connectome and SM data
% Required inputs are the NET.txt and VARS.txt files.

function abcd_basic_proc(N_perm, N_dim, abcd_cca_dir, n_subs)
    if nargin<4
        sprintf("ERROR, not enough arguments.")
        sprintf("Example: abcd_basic_proc(100000, 70, '/data/ABCD_MBDU/goyaln2/abcd_cca_replication/', 5013)")
        return
	end
	
	%% Add the dependencies folders to the PATH, and read in necessary data
	if ~isdeployed
		addpath(genpath(sprintf('%s/dependencies/', abcd_cca_dir)));
		addpath(genpath(sprintf('%s/data/', abcd_cca_dir)));
	end

	% Read in data, set some variables, create confounds matrix
	% VARS_0 = Subjects X SMs text file
	VARS_0=strcsvread(sprintf('%s/data/%d/VARS.txt', abcd_cca_dir, n_subs));

	% Load the Subjects X Nodes matrix (should be size Nx19900)
	N0=load(sprintf('%s/data/%d/NET.txt', abcd_cca_dir, n_subs));   
	
	ica_sms_0=fileread(sprintf('%s/data/ica_subject_measures.txt', abcd_cca_dir))
	ica_sms = strsplit(ica_sms_0)

	% Drop subject col and device serial number col (they are strings)
	egid_col    = find(strcmpi(VARS_0(1,:),'subjectid'));
	serial_col  = find(strcmpi(VARS_0(1,:),'mri_info_device.serial.number'));
	VARS_0(:,[egid_col serial_col])=[]

	site_col        = find(strcmpi(VARS_0(1,:),'abcd_site'));
	mri_man_col     = find(strcmpi(VARS_0(1,:),'mri_info_manufacturer'));
	mean_fd_col     = find(strcmpi(VARS_0(1,:),'mean_fd'));
	bmi_col         = find(strcmpi(VARS_0(1,:),'anthro_bmi_calc'));
	weight_col      = find(strcmpi(VARS_0(1,:),'anthro_weight_calc'));
	wholebrain_col  = find(strcmpi(VARS_0(1,:),'smri_vol_subcort.aseg_wholebrain'));
	intracran_col   = find(strcmpi(VARS_0(1,:),'smri_vol_subcort.aseg_intracranialvolume'));

	[sharedvals,idx]=intersect(VARS_0(1,:),ica_sms)

	VARS=cell2mat(VARS_0(2:end,:));

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


	% --- Save matrices ---
	writematrix(conf, sprintf('%s/data/%d/conf.txt', abcd_cca_dir, n_subs));
	writematrix(N0, sprintf('%s/data/%d/N0.txt', abcd_cca_dir, n_subs));
	writematrix(N5, sprintf('%s/data/%d/N5.txt', abcd_cca_dir, n_subs));
	writematrix(S1, sprintf('%s/data/%d/S1.txt', abcd_cca_dir, n_subs));
	writematrix(S5, sprintf('%s/data/%d/S5.txt', abcd_cca_dir, n_subs));

end