% NOTE: need the following loaded on path
%       fsl, connectome-workbench

perms_per_batch_in = 2000
N_perm_in = 100000
N_dim_in = 70
n_subs_in = 5013
abcd_cca_dir    =   '/data/NIMH_scratch/abcd_cca/abcd_cca_replication/';

if ~isdeployed
    addpath(genpath(sprintf('%s/dependencies/', abcd_cca_dir)));
    addpath(genpath(sprintf('%s/data/', abcd_cca_dir)));
    perms_per_batch =   perms_per_batch_in;
    N_perm          =   N_perm_in;
    N_dim           =   N_dim_in;
    n_subs          =   n_subs_in;
elseif isdeployed
    % When compiled matlab, it reads the command line args all as strings so we need to convert
    perms_per_batch =   str2num(perms_per_batch_in);
    N_perm          =   str2num(N_perm_in);
    N_dim           =   str2num(N_dim_in);
    n_subs          =   str2num(n_subs_in);
end

melodic_folder  =   sprintf('%s/data_prep/data/stage_3/%d.gica', abcd_cca_dir, n_subs);
SUMPICS         =   sprintf('%s/melodic_IC_thin.sum', melodic_folder);
SUMPICS_THICK   =   sprintf('%s/melodic_IC_thick.sum', melodic_folder);

%% --- Read in data, set some variables, create confounds matrix ---
% load in data from FSLNets calculations
fslnets_mat     =   load(sprintf('%s/data_prep/data/stage_4/%d/fslnets.mat', abcd_cca_dir, n_subs));

% Load the Subjects X Nodes matrix (should be size Nx19900)
N0 = load(sprintf('%s/data/%d/NET.txt', abcd_cca_dir, n_subs));

% VARS_0 = Subjects X SMs text file
VARS_0 = strcsvread(sprintf('%s/data/%d/VARS.txt', abcd_cca_dir, n_subs));

% Load list of SMs to be used in ICA (this list is made manually)
ica_sms_0=fileread(sprintf('%s/data/ica_subject_measures.txt', abcd_cca_dir));
ica_sms = strsplit(ica_sms_0);

% Load list of names of colums used to encode scanner ID
scanner_col_names_0=fileread(sprintf('%s/data/%d/scanner_confounds.txt', abcd_cca_dir, n_subs));
scanner_col_names = strsplit(scanner_col_names_0);

% Drop subject col and device serial number col (they are strings)
egid_col    = find(strcmpi(VARS_0(1,:),'subjectid'));
serial_col  = find(strcmpi(VARS_0(1,:),'mri_info_device.serial.number'));
VARS_0(:,[egid_col serial_col])=[];

% Get column indices of our confound variables
[sharedvals,scanner_cols_idx]=intersect(VARS_0(1,:),scanner_col_names);
site_col        = find(strcmpi(VARS_0(1,:),'abcd_site'));
mri_man_col     = find(strcmpi(VARS_0(1,:),'mri_info_manufacturer'));
mean_fd_col     = find(strcmpi(VARS_0(1,:),'mean_fd'));
bmi_col         = find(strcmpi(VARS_0(1,:),'anthro_bmi_calc'));
weight_col      = find(strcmpi(VARS_0(1,:),'anthro_weight_calc'));
wholebrain_col  = find(strcmpi(VARS_0(1,:),'smri_vol_subcort.aseg_wholebrain'));
intracran_col   = find(strcmpi(VARS_0(1,:),'smri_vol_subcort.aseg_intracranialvolume'));

% Now get column indices of the ICA SMs
[sharedvals,ica_sms_idx]=intersect(VARS_0(1,:),ica_sms);

% Store the original order of the ICA SMs, used later to make our pos-neg axis
sms_original_order = VARS_0(1,:);

% VARS without column names
VARS=cell2mat(VARS_0(2:end,:));

% Create confounds matrix
% NOTE, since we use the same nuisance variable matrix conf (aka Z), this is a PARTIAL CCA where the same nuisance variable matrix (Z) is used for both the SM and connectome matrices
% (see Winkler Et al. Permutation inference in CCA, Neuroimage 2020)

% Per conversation with Anderson, we might want to consider NOT doing this double normalization thing, instead just add an intercept column to our confounds matrix
conf  = palm_inormal([ VARS(:,scanner_cols_idx) VARS(:,[mean_fd_col bmi_col weight_col]) VARS(:,[wholebrain_col intracran_col]).^(1/3) ]);  % Gaussianise
conf(isnan(conf)|isinf(conf)) = 0;                % impute missing data as zeros
conf  = nets_normalise([conf conf(:,length(scanner_cols_idx):end).^2]);  % add on squared terms and renormalise (all cols other than those for scanner IDs)
conf(isnan(conf)|isinf(conf)) = 0;                % again convert NaN/inf to 0 (above line makes them reappear for some reason)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% --- SM PROCESSING ---
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Matrix S1 (only ICA sms)
S1=[VARS(:,ica_sms_idx)];

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
corrcoef(S4,S3Cov)  %0.9999 for the 5013 subject sample

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

%% --- CCA with Qz---
fprintf("Running CCA on matrices S5 and N5\n")
[A, B, R, U, V, initial_stats] = canoncorr(N5,S5);

% Plot
figure;
scatter(U(:,1), V(:,1))
% Plot with regression line
figure;
plotregression(U(:,1), V(:,1))



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% --- POSITIVE NEGATIVE AXIS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% post hoc columns not included in CCA
bmi_col         = find(strcmpi(VARS_0(1,:),'anthro_bmi_calc'));
educ_col         = find(strcmpi(VARS_0(1,:),'high.educ'));
age_col         = find(strcmpi(VARS_0(1,:),'age'));
income_col         = find(strcmpi(VARS_0(1,:),'household.income.bl'));

% SM indices
pneg_idx = [ica_sms_idx' bmi_col educ_col age_col income_col];
% include / exclude vector
inc_exc = [ones(1,length(ica_sms_idx)) zeros(1,4)]
% SM names
pneg_names = VARS_0(1,pneg_idx)
% SM measures
pneg_vars = [VARS(:,ica_sms_idx) VARS(:,bmi_col) VARS(:,educ_col) VARS(:,age_col) VARS(:,income_col)];

% specify CCA mode
I = 2;
CorCCA = corr(V(:,I), palm_inormal(pneg_vars), 'rows','pairwise');

% open the figure
figure;
plot(CorCCA);   % correlate CCA component 1 with original set of SMs
% Z scores
ZCCA          = 12*0.5*log((1+CorCCA)./(1-CorCCA));    % r2z  -  factor x12 gets close to "real" zstats.
[tmp_B,tmp_I] = sort(CorCCA,'ascend'); % sort by corralation value
toplist       = [];
strlist       = {};

% Iterate over the SMs
for i = 1:length(tmp_I)
    % Since we sort the values, we use ii to index into the unsorted list and get the proper index of the column from VARS
    ii = tmp_I(i);
    % Pull the values for the column associated with the SM being looked at
    Y                 = pneg_vars(:,ii);
    Y_no_nan_idx      = ~isnan(Y);
    Y                 = nets_demean(Y(Y_no_nan_idx));
    X                 = nets_demean(V(Y_no_nan_idx,I));
    VarExplained(ii)  = var(X*(pinv(X)*Y)) / var(Y);

    if abs(tmp_B(i))>0.2
        BVname = string(pneg_names(ii));
        toplist=[toplist ii];
        str=sprintf('%.2f %.2f %.2f %s %s',CorCCA(ii),ZCCA(ii),VarExplained(ii),BVname);
        strlist{end+1} = str;
    end
end

x   = ones([length(toplist),1]);
dx  = 0.1;
y   = 1:length(toplist);
dy  = 0.1;
set(0,'DefaultTextInterpreter','none')
scatter(x,y);
text(x+dx, y+dy, strlist);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% --- VARIANCE/PERMUTATION ANALYSIS ---
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
perm_data  = load(sprintf('%s/data/%d/permutation_data.mat', abcd_cca_dir, n_subs)); 
tmp_VARS                                = palm_inormal(S1);
tmp_VARS(:,std(tmp_VARS)<1e-10)         = [];
tmp_VARS(:,sum(isnan(tmp_VARS)==0)<20)  = [];

for i = 1:N_dim;  % show corrected pvalues
  Rpval(i) = (1 + sum(perm_data.s_agg(1).r(2:end,1) >= R(i))) / N_perm;
end
Rpval;
Ncca=sum(Rpval<0.05)  % number of significant CCA components
Rpval(1:Ncca)

variance_data_NET   = [ sum(corr(U, N0).^2,2)'; perm_data.s_agg(1).nullNETv_prctile_5; perm_data.s_agg(1).nullNETv_mean; perm_data.s_agg(1).nullNETv_prctile_95; sum(corr(N5,N0).^2,2)' ] * 100 / size(N0,2);
variance_data_VARS  = [ sum(corr(V,tmp_VARS,'rows','pairwise').^2,2)'; perm_data.s_agg(1).nullSMv_prctile_5; perm_data.s_agg(1).nullSMv_mean; perm_data.s_agg(1).nullSMv_prctile_95; sum(corr(S5,tmp_VARS,'rows','pairwise').^2,2)' ] * 100 / size(tmp_VARS,2);

z_scores_NET = [ (sum(corr(U,N0).^2,2)-  perm_data.s_agg(1).nullNETv_mean') ./ perm_data.s_agg(1).nullNETv_std' ] ;
z_scores_SM = [ (sum(corr(V,tmp_VARS,'rows','pairwise').^2,2)- perm_data.s_agg(1).nullSMv_mean') ./ perm_data.s_agg(1).nullSMv_std' ];

% Look at first 20 modes
I=1:20;

% Connectomes variance
figure;
subplot(2,1,1); 
hold on;
% Draw the rectangles for null distributions per mode
for i=1:length(I)
    rectangle('Position',[i-0.5 variance_data_NET(2,i) 1 variance_data_NET(4,i)-variance_data_NET(2,i)],'FaceColor',[0.8 0.8 0.8],'EdgeColor',[0.8 0.8 0.8]);
end
plot(variance_data_NET(3,I),'k');
plot(variance_data_NET(1,I),'b');
plot(variance_data_NET(1,I),'b.');


% Subject measures variance
subplot(2,1,2); 
hold on;
for i=1:length(I)
    rectangle('Position',[i-0.5 variance_data_VARS(2,i) 1 variance_data_VARS(4,i)-variance_data_VARS(2,i)],'FaceColor',[0.8 0.8 0.8],'EdgeColor',[0.8 0.8 0.8]);
end
plot(variance_data_VARS(3,I),'k');
plot(variance_data_VARS(1,I),'b');
plot(variance_data_VARS(1,I),'b.');
