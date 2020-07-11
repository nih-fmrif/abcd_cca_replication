%% Add the dependencies folders to the PATH, and read in necessary data
addpath(genpath('../dependencies/'));
addpath(genpath('./data/'));

abcd_cca_dir="/data/ABCD_MBDU/goyaln2/abcd_cca_replication/"
hcp_cca_dir="/data/ABCD_MBDU/goyaln2/abcd_cca_replication/hcp_cca_testing/"

N_dim=100;
N_perm=100000;
n_subs=461;

if ~isdeployed
  addpath(genpath(sprintf('%s/dependencies/', abcd_cca_dir)));
  addpath(genpath(sprintf('%s/data/', hcp_cca_dir)));
end

% Read in data, set some variables, create confounds matrix
VARS=readmatrix(sprintf('%s/data/%d/VARS.txt', hcp_cca_dir, n_subs));  % Subjects X SMs text file
VARS(:,sum(isnan(VARS)==0)<60)=NaN;             % Pre-delete any variables in VARS that have lots of missing data (fewer than 60 subjects have measurements)
varsQconf=load(sprintf('%s/data/%d/varsQconf.txt', hcp_cca_dir, n_subs));        % Load the previously-imputed acquisition period (recon method) (avail at https://www.fmrib.ox.ac.uk/datasets/HCP-CCA/, or in our code repo.)
NET=load(sprintf('%s/data/%d/NET.txt', hcp_cca_dir, n_subs));          % Load the Subjects X Nodes matrix (should be size 461x19900)

% Number of PCA and CCA components
N_dim=100;
% Number of permutations
N_perm=1000;

% Set up confounds matrix (this is based on variables selected by Smith et al. in the original study). Confounds are demeaned, any missing data is set to 0
conf=palm_inormal([ varsQconf VARS(:,[7 14 15 22 23 25]) VARS(:,[265 266]).^(1/3) ]);   % Gaussianise
conf(isnan(conf)|isinf(conf))=0;                % impute missing data as zeros
conf=nets_normalise([conf conf(:,2:end).^2]);   % add on squared terms and renormalise
conf(isnan(conf)|isinf(conf))=0;                % again convert NaN/inf to 0 (above line makes them reappear for some reason)

% --- GENERATE PERMUTATIONS ---
EB=hcp2blocks(sprintf('%s/data/%d/r500_m.csv', hcp_cca_dir, n_subs), [ ], false, VARS(:,1)); % Input is the raw restricted file downloaded from Connectome DB

% Since subjects are dropped by hcp2blocks, we need to drop them from the other matrices (VARS, NET, varsQconf) to avoid errors
subs = EB(:,5);             % Pull list of subject IDs in EB from column 5 (EB is what returned from hcp2blocks), these are the subjects we KEEP
LIA = ismember(VARS,subs);  % LIA = Logical Index Array, an array with logical true (1) where data in VARS is found in subs
rows_keep = LIA(:,1);       % Row #'s to keep (1=keep, 0=drop)

% Now drop all but (rows) of subjects we want to keep
S1 = VARS(rows_keep,:);
N0 = NET(rows_keep,:);
varsQconf= varsQconf(rows_keep,:);
conf = conf(rows_keep,:);

%% Prepare the netmat matrix for the CCA (N1, N2, N3, N4, N5), following steps outlined in Smith et al.
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
[N5,ss1,vv1]=nets_svds(N4,N_dim); % 100-dim PCA of netmat via SVD reduction

%% Prepare the SM matrix - apply quantitative exclusion criteria
fprintf("Calculating SM matrices S2 through S5\n")

% Remove "bad" SMs, which are defined as:
  % 1. large outlier
  % 2. too many missing (more than 250 subjects missing measurement for an SM)
  % 3. or not enough distinct values (defined as >95% of subjects having the same SM value)
badvars=[];
for i=1:size(S1,2)                          % Iterate over the SMs of S1 (i.e. the columns)
  Xs=S1(:,i);                               % Vector of the values for this SM
  measure_present=~isnan(Xs);                 % How many are elements present? >250 needed (this is a vector where 1=present for a subject)
  Ys=(Xs(measure_present)-median(Xs(measure_present))).^2;  % Of the values present, calculate vector Ys = (Xs -median(Xs))^2, extreme outlier if max(Ys) > 100*mean(Ys) (or max(Ys/mean(Ys)) > 100 is extreme)
  ratio=max(Ys/mean(Ys));
  if (sum(measure_present)>250) & (std(Xs(measure_present))>0) & (max(sum(nets_class_vectomat(Xs(measure_present))))/length(Xs(measure_present))<0.95) & (ratio<100)
      % First criteria: >250 values?
      % Second criteria: std dev of the values > 0?
      % Third criteria: is the size of largest equal-values-group too large? (i.e. > 95% of subjects)
      % Fourth criteria: is there an extreme value?
      % if (1 & 2 & 3 & 4)=True, then keep the SM
    i=i; % do nothing
  else
    % A criteria for drop is met, so add the SM to badvars (i = index of the column for an SM)
    [i sum(measure_present) std(Xs(measure_present)) max(sum(nets_class_vectomat(Xs(measure_present))))/length(Xs(measure_present)) ratio];
    badvars=[badvars i];
  end
end

% Get list of the SMs we want to feed into the CCA.
% Found by comparing a list of 1,2,3...478 w/ the indices of the SMs to drop (using setdiff()) to get the indices of SMs to keep
varskeep=setdiff([1:size(S1,2)],[1 6 267:457 ...                              % SMs we generally ignore (ID, race, FreeSurfer)
 2 7 14 15 22 23 25 265 266  ...                                              % confound SMs
 11 12 13 17 19 27 29 31 34 40 204 205 212:223 229:233 236 238 242 477 ...    % some more SMs to ignore for the CCA
 3 4 5 8 9 10 16 18 20 21 24 26 28 30 32 33 35:39 458 459 460 463 464 ...     % some more SMs to ignore for the CCA
 badvars]);                                                                   % the "bad" SMs auto-detected above

% Now, prepare the final SM matrix and run the PCA
% S2, formed by gaussianizing the SMs we keep
S2=palm_inormal(S1(:,varskeep)); % Gaussianise

% Now generate S3 (aka varsd), formed by deconfounding the 17 confounds out of S2
S3=S2;
for i=1:size(S3,2) % deconfound ignoring missing data
  grot=(isnan(S3(:,i))==0);
  grotconf=nets_demean(conf(grot,:));
  S3(grot,i)=normalize(S3(grot,i)-grotconf*(pinv(grotconf)*S3(grot,i)));
end

% Next, we need to generate S4 (461x158 matrix)
% First, estimate the SubjectsXSubjects covariance matrix (where for any two subjects, SMs missing for either subject are ignored)
% The approximate covariance matrix (varsdCOV) is then projected onto the nearest valid covariance matrix using nearestSPD toolbox.
% This method avoids imputation, and S4 can be fed into PCA.
varsdCOV=zeros(size(S3,1));
for i=1:size(S3,1) % estimate "pairwise" covariance, ignoring missing data
  for j=1:size(S3,1)
    grot=S3([i j],:);
    grot=cov(grot(:,sum(isnan(grot))==0)');
    varsdCOV(i,j)=grot(1,2);
  end
end
S4=nearestSPD(varsdCOV); % project onto the nearest valid covariance matrix. This method avoids imputation (we can't have any missing values before running the PCA)

% Generate S5, the top 100 eigenvectors for SMs, to avoid overfitting and reduce dimensionality
[uu,dd]=eigs(S4,N_dim);       % SVD (eigs actually)
S5=uu-conf*(pinv(conf)*uu);   % deconfound again just to be safe

%% CCA
fprintf("Running CCA on matrices S5 and N5\n")
[A,B,R,U,V,grotstats]=canoncorr(N5,S5);

perm_data  = load(sprintf('%s/data/%d/permutation_data.mat', hcp_cca_dir, n_subs)); 

tmp_VARS                                = palm_inormal(S1);
tmp_VARS(:,std(tmp_VARS)<1e-10)         = [];
tmp_VARS(:,sum(isnan(tmp_VARS)==0)<20)  = [];

for i = 1:N_dim;  % show corrected pvalues
  Rpval(i) = (1 + sum(perm_data.s_agg(1).r(2:end,1) >= R(i))) / N_perm;
end
Rpval;
Ncca=sum(Rpval<0.05)  % number of significant CCA components
Rpval(1:Ncca)

% variance_data_NET   = [ sum(corr(U,N0).^2,2) prctile(nullNETv,5,2) mean(nullNETv,2) prctile(nullNETv,95,2) sum(corr(N5,N0).^2,2) ] * 100 / size(N0,2);
variance_data_NET   = [ sum(corr(U, N0).^2,2)'; perm_data.s_agg(1).nullNETv_prctile_5; perm_data.s_agg(1).nullNETv_mean; perm_data.s_agg(1).nullNETv_prctile_95; sum(corr(N5,N0).^2,2)' ] * 100 / size(N0,2);
variance_data_VARS  = [ sum(corr(V,tmp_VARS,'rows','pairwise').^2,2)'; perm_data.s_agg(1).nullSMv_prctile_5; perm_data.s_agg(1).nullSMv_mean; perm_data.s_agg(1).nullSMv_prctile_95; sum(corr(S5,tmp_VARS,'rows','pairwise').^2,2)' ] * 100 / size(tmp_VARS,2);

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
% plot(variance_data_NET(5,I),'g');  % turned off showing the PCA equivalent plots

% th1 = title({'Connectome total % variance explained by CCA modes';''});
% ylabel('%% variance (connectomes)')
% xlabel('CCA Mode')
% xlim([1 20])
% ylim([0.3 0.55])
% yticks([0.3 0.35 0.4 0.45 0.5 0.55])
% set(gca,'FontSize',15)

% Subject measures variance
subplot(2,1,2); 
hold on;
for i=1:length(I)
    rectangle('Position',[i-0.5 variance_data_VARS(2,i) 1 variance_data_VARS(4,i)-variance_data_VARS(2,i)],'FaceColor',[0.8 0.8 0.8],'EdgeColor',[0.8 0.8 0.8]);
end
plot(variance_data_VARS(3,I),'k');
plot(variance_data_VARS(1,I),'b');
plot(variance_data_VARS(1,I),'b.');