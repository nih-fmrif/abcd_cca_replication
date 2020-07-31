% NOTE: need the following loaded on path
%       fsl, connectome-workbench

perms_per_batch_in = 2000
N_perm_in = 100000
N_dim_in = 70
n_subs_in = 5013
abcd_cca_dir    =   '/data/ABCD_MBDU/goyaln2/abcd_cca_replication/';


% subs_folder    =  '/data/ABCD_MBDU/goyaln2/abcd_cca_replication/data_prep/ica_500_test/'
% melodic_folder      =  '/data/ABCD_MBDU/goyaln2/abcd_cca_replication/data_prep/ica_500_test/groupICA200_50subs.gica/';
% SUMPICS =  '/data/ABCD_MBDU/goyaln2/abcd_cca_replication/data_prep/ica_500_test/groupICA200_50subs.gica/melodic_IC.sum';

% SUMPICS_THICK   =   sprintf('%s/data_prep/1000_subjects_masked.gica/melodic_IC_thick.sum', abcd_cca_dir);

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
% SUMPICS         =   sprintf('%s/data_prep/1000_subjects_masked.gica/melodic_IC.sum', abcd_cca_dir);
SUMPICS         =   sprintf('%s/melodic_IC.sum', melodic_folder);

%% --- Read in data, set some variables, create confounds matrix ---
% load in data from FSLNets calculations
fslnets_mat     =   load(sprintf('%s/data/%d/fslnets.mat', abcd_cca_dir, n_subs));

% VARS_0 = Subjects X SMs text file
VARS_0 = strcsvread(sprintf('%s/data/%d/VARS.txt', abcd_cca_dir, n_subs));

% Load the Subjects X Nodes matrix (should be size Nx19900)
N0 = load(sprintf('%s/data/%d/NET.txt', abcd_cca_dir, n_subs));   

ica_sms_0   =   fileread(sprintf('%s/data/ica_subject_measures.txt', abcd_cca_dir));
ica_sms     =   strsplit(ica_sms_0);

% Drop subject col and device serial number col (they are strings)
egid_col    = find(strcmpi(VARS_0(1,:),'subjectid'));
serial_col  = find(strcmpi(VARS_0(1,:),'mri_info_device.serial.number'));
VARS_0(:,[egid_col serial_col])=[];

% Get column indices of our confound variables
site_col        = find(strcmpi(VARS_0(1,:),'abcd_site'));
mri_man_col     = find(strcmpi(VARS_0(1,:),'mri_info_manufacturer'));
mean_fd_col     = find(strcmpi(VARS_0(1,:),'mean_fd'));
bmi_col         = find(strcmpi(VARS_0(1,:),'anthro_bmi_calc'));
weight_col      = find(strcmpi(VARS_0(1,:),'anthro_weight_calc'));
wholebrain_col  = find(strcmpi(VARS_0(1,:),'smri_vol_subcort.aseg_wholebrain'));
intracran_col   = find(strcmpi(VARS_0(1,:),'smri_vol_subcort.aseg_intracranialvolume'));

[sharedvals,idx]=intersect(VARS_0(1,:),ica_sms);
sms_original_order = VARS_0(1,:);

VARS=cell2mat(VARS_0(2:end,:));

conf  = palm_inormal([ VARS(:,[site_col mri_man_col mean_fd_col bmi_col weight_col]) VARS(:,[wholebrain_col intracran_col]).^(1/3) ]);  % Gaussianise
conf(isnan(conf)|isinf(conf)) = 0;                % impute missing data as zeros
conf  = nets_normalise([conf conf(:,3:end).^2]);  % add on squared terms and renormalise (additional SMs made from 3-7)
conf(isnan(conf)|isinf(conf)) = 0;                % again convert NaN/inf to 0 (above line makes them reappear for some reason)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% --- SM PROCESSING ---
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Matrix S1 (only ICA sms)
S1=[VARS(:,idx)];

% Now, prepare the final SM matrix and run the PCA
% S2, formed by gaussianizing the SMs we keep
S2=palm_inormal(S1); % Gaussianise

% Now generate S3, formed by deconfounding the 17 confounds out of S2
S3=S2;
for i=1:size(S3,2) % deconfound ignoring missing data
    tmp=(isnan(S3(:,i))==0);
    tmpconf=nets_demean(conf(tmp,:));
    S3(tmp,i)=normalize(S3(tmp,i)-tmpconf*(pinv(tmpconf)*S3(tmp,i)));
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
        tmp=S3([i j],:);
        tmp=cov(tmp(:,sum(isnan(tmp))==0)');
        S3Cov(i,j)=tmp(1,2);
    end
end
S4=nearestSPD(S3Cov); % project onto the nearest valid covariance matrix. This method avoids imputation (we can't have any missing values before running the PCA)

% Check the before and after correlation:
corrcoef(S4, S3Cov)  %0.9999

% Generate S5, the top eigenvectors for SMs, to avoid overfitting and reduce dimensionality
[uu,dd] = eigs(S4,N_dim);       % SVD (eigs actually)
S5 = uu-conf*(pinv(conf)*uu);   % deconfound again just to be safe

%% --- NETMAT PROCESSING ---
fprintf("Calculating netmat matrices N1 through N5\n")
% N1, formed by 1. demean, 2. globally variance normalize
N1 = nets_demean(N0);   % 1. Demean
N1 = N1/std(N1(:));     % 2. variance normalize
% N2, formed by 1. Demean, 2. remove columns that are badly conditions due to low z (z<0.1) mean value, 3. global variance normalize the matrix
abs_mean_NET = abs(mean(N0));                             % get mean, take abs val
N2 = nets_demean(N0./repmat(abs_mean_NET,size(N0,1),1));  % 1. demean
N2(:,abs_mean_NET<0.1) = [];                              % 2. remove columns with mean value <0.1                       
N2 = N2/std(N2(:));                                       % 3. variance normalize
% N3, formed by horizontally concat N1 and N2
N3 = [N1 N2]; % Concat horizontally
% N4, formed by regressing the confounds matrix out of N3
N4 = nets_demean(N3-conf*(pinv(conf)*N3));

% --- Notes from call with Anderson (7/16/20) ---
% I = identity matrix (NxN)
% Z = conf
% Rz = I-Z*pinv(Z)
% [Q, D, ~] = svd(null(Z'))
% Qz = Q*D
% N4 = (I-Z*pinv(Z))*N3;
% N4q = Qz'*N3    % N - ncols(Z) rows
% Rz = Qz*Qz'
% I = Qz'*Qz  (dimensions N-ncols(Z) x N-ncols(Z))

% Qz and Rz will lead to same CCA results, but Qz is the smallest space to represent the information
% N4 vs. N4q, N4q have no dependency between rows (assuming original observations are independent, or select only subjects that are independent)
% N4q is smaller than N4 because each point in the plot is an 'effective' subject (each point independent of eachother) --> cannot be traced back to original subjects (a number of subjects get deleted)
% When using N4, we know exactly which subject each point corresponds to
% Making scatter plot with N4, will have artifacts, but N4q will show the data properly

% N5
[N5,ss1,vv1] = nets_svds(N4, N_dim); % PCA of netmat via SVD reduction

%% --- CCA ---
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
I = 1;
CorCCA = corr(V(:,I), palm_inormal(VARS), 'rows','pairwise');
figure;
plot(CorCCA);   % correlate CCA component 1 with original set of SMs

ZCCA          = 12*0.5*log((1+CorCCA)./(1-CorCCA));    % r2z  -  factor x12 gets close to "real" zstats. Bonferroni gives significance at abs(Z)>3.9
[tmp_B,tmp_I] = sort(CorCCA,'ascend'); 
toplist       = [];
strlist       = {};

% Iterate over the SMs
for i = 1:length(tmp_I)
    % Since we sort the values, we use ii to index into the unsorted list and get the proper index of the column from VARS
    ii = tmp_I(i);
    % Pull the values for the column associated with the SM being looked at
    Y                 = VARS(:,ii);
    Y_no_nan_idx      = ~isnan(Y);
    Y                 = nets_demean(Y(Y_no_nan_idx));
    X                 = nets_demean(V(Y_no_nan_idx,I));
    VarExplained(ii)  = var(X*(pinv(X)*Y)) / var(Y);

    if abs(tmp_B(i))>0.1
        BVname = string(sms_original_order(ii))
        toplist=[toplist ii];
        str=sprintf('%.2f %.2f %.2f %s %s',CorCCA(ii),ZCCA(ii),VarExplained(ii),BVname);
        strlist{end+1} = str;
        % disp(str);
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



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% --- VISUALIZE CCA COMPONENTS ---
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

I=1;  % process first CCA mode below
grotAA = corr(U, N0)';

% display top edges and create weights matrix ZnetMOD
grot=zeros(fslnets_mat.ts.Nnodes);
grot(triu(ones(fslnets_mat.ts.Nnodes),1)>0)=grotAA(:,I);  %%/max(abs(grotAA(:,I)));
  % grot=grot.* exp(-Mnet2.^2);            % which weak-mean edges are strongly involved in the CCA?
  % grot=abs(Mnet2) .* (1-abs(grot)).^2;   % which strong edges are not involved?
ZnetMOD=grot+grot';   % warning - despite its name this has NOT been z-score transformed !
nets_edgepics(fslnets_mat.ts, SUMPICS, fslnets_mat.Mnet2, grot, 24, 2);
set(gcf,'PaperPositionMode','auto','Position',[10 10 1800 900]);
% set(0,'DefaultTextInterpreter','latex')
%print('-dpng',sprintf('%s/edgemod.png','/home/fs0/steve'));

%%% relationship between mean(NET) and modulation
figure;
scatter(fslnets_mat.Mnet2(:),ZnetMOD(:))
corr(fslnets_mat.Mnet2(:),ZnetMOD(:))          %     0.1975
grot=sign(fslnets_mat.Mnet2(:)).*ZnetMOD(:);
hist([grot -grot],100);


%% ---- COME BACK TO THIS ----
% now do it to display grotDD node numbers instead of 1:200 range numbers (see bottom of script to get grotDD)
% poopy.DD=1:length(grotDD);
% nets_edgepics(poopy,'/home/fs0/steve/www/HCP_GigaTrawl/netjs/data/dataset1/melodic_IC_sum.sum',fslnets_mat.Mnet2(grotDD,grotDD),grot(grotDD,grotDD),24,2);
% set(gcf,'PaperPositionMode','auto','Position',[10 10 1800 900]);
%print('-dpng',sprintf('%s/edgemod.png','/home/fs0/steve'));
%% ---- COME BACK TO THIS ----


%%% which are the strongest modulated nodes?
% note WBC = workbench_command, must have connectome workbench loaded on path
% BO  =   ciftiopen(sprintf('%s/melodic_IC.dtseries.nii', melodic_folder), WBC);

% GM  =   BO.cdata;
% GM  =   GM.*repmat(sign(max(GM)+min(GM)),size(GM,1),1)./repmat(max(abs(GM)),size(GM,1),1);  % make all individual group maps have a positive peak, and of peak height=1
% GM(GM<0)=0;

%BO.cdata=log(mean(GM * sum(abs(ZnetMOD))',2) ./ mean(GM,2));
% ciftisave(BO,'~/sumCCAnodes.dtseries.nii',WBC); % old method from paper submission 1

% reallyZnetMOD=12*0.5*log((1+ZnetMOD)./(1-ZnetMOD));    % r2z  -  factor x12 gets close to "real" zstats. Bonferroni gives significance at abs(Z)>3.9
% grot=reallyZnetMOD.*sign(oldPTN.Mnet2); grot=sort(grot);
% BO.cdata=log(mean(-GM * sum(grot(1:50,:))',2)    ./ mean(GM,2));
% ciftisave(BO,'~/sumCCAnodesNEG.dtseries.nii',WBC);
% [prctile(BO.cdata,80) corr(BO.cdata(1:59000,1),clus2(1:59000,1))]
% BO.cdata=log(mean( GM * sum(grot(151:end,:))',2) ./ mean(GM,2));
% ciftisave(BO,'~/sumCCAnodesPOS.dtseries.nii',WBC);
% [prctile(BO.cdata,80) corr(BO.cdata(1:59000,1),clus2(1:59000,1))]
% BO.cdata=log(mean( GM * sum(grot)',2)            ./ mean(GM,2));
% ciftisave(BO,'~/sumCCAnodesPOSNEG.dtseries.nii',WBC);




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% --- HEIRARCHICAL MAP ---
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Znet1   =   fslnets_mat.Znet1;
Mnet1   =   fslnets_mat.Mnet1;
Znet2   =   fslnets_mat.Znet2;
Mnet2   =   fslnets_mat.Mnet2;

%%% all-200-nodes hierarchical plot
% [hierALL, linkagesALL]  =   nets_hierarchy( Znet1, ...
%                                             Znet2, ...
%                                             fslnets_mat.ts.DD, ...
%                                             SUMPICS_THICK, ...
%                                             1.5);

[hierALL, linkagesALL]  =   nets_hierarchy( Znet1, ...
                                            Znet2, ...
                                            fslnets_mat.ts.DD, ...
                                            SUMPICS, ...
                                            1.5);

clustersALL =   cluster(linkagesALL, 'maxclust', 4)';

%%% select top-30 CCA-edges (list of nodes goes into grotDD)
grot=ZnetMOD;
grotTHRESH=prctile(abs(grot(:)),99.85);
grot(abs(grot)<grotTHRESH)=0;
grotDD=find(sum(grot~=0)>0);
grot=grot(grotDD,grotDD); grotTHRESH
grot1=Znet1;
grot1=grot1(grotDD,grotDD);
grot1=grot1/max(abs(grot1(:)));
for i=1:size(grot1,1)
  for j=1:size(grot1,1)
    if clustersALL(grotDD(i)) == clustersALL(grotDD(j))
      grot1(i,j)=grot1(i,j)+1;
    end
  end
end

%%grot=ZnetMOD; grotTHRESH=prctile(abs(grot(:)),99.85); grot(abs(grot)<grotTHRESH)=0;  grotDD=find(sum(grot~=0)>0);  grot=grot(grotDD,grotDD); grotTHRESH
%%grot1=Znet1; grot1=grot1(grotDD,grotDD); grot1=grot1/max(abs(grot1(:)));

[hier,linkages] = nets_hierarchy(grot1,grot*3,grotDD,SUMPICS,0.75); 
% set(gcf,'PaperPositionMode','auto','Position',[10 10 2800 2000]);   %print('-dpng',sprintf('%s/edgemodhier.png','/home/fs0/steve'));
clusters=cluster(linkages,'maxclust',4)';

% system(sprintf('/bin/rm -rf %s/netjs',NM));
% system(sprintf('cp -r %s/netjs %s',FMRIB,NM));
% NP=sprintf('%s/netjs/data/dataset1',NM);
% save(sprintf('%s/Znet3.txt',NP),'grot','-ascii');
% grot=grot.*sign(Mnet2(grotDD,grotDD));
% save(sprintf('%s/Znet4.txt',NP),'grot','-ascii');
% grot=Mnet1(grotDD,grotDD);   save(sprintf('%s/Znet1.txt',NP),'grot','-ascii');
% grot=Mnet2(grotDD,grotDD);   save(sprintf('%s/Znet2.txt',NP),'grot','-ascii');
% save(sprintf('%s/hier.txt',NP),'hier','-ascii');
% save(sprintf('%s/linkages.txt',NP),'linkages','-ascii');
% save(sprintf('%s/clusters.txt',NP),'clusters','-ascii');
% system(sprintf('/bin/mkdir %s/melodic_IC_sum.sum',NP));
% for i=1:length(grotDD)
%   system(sprintf('/bin/cp %s/%.4d.png %s/melodic_IC_sum.sum/%.4d.png',SUMPICSDIL,grotDD(i)-1,NP,i-1));
% end
% ! cp ~/main.js ~/netvis.js ~/www/HCP_GigaTrawl/netjs/js

%%% old (paper v1 30-edge-based cluster outputs - not used any more
%BO=ciftiopen('/vols/Data/HCP/Phase2/groupE/groupICA/groupICA_3T_Q1-Q6related468_MSMsulc_d200.ica/melodic_IC.dtseries.nii',WBC); GM=BO.cdata;
%GM(GM<0)=0; [~,GM]=sort(GM,2,'descend'); GM=GM(:,1); BO.cdata=0*GM;
%for i=1:size(GM,1)
%  grot = find(grotDD==GM(i,1));
%  if length(grot)>0
%    BO.cdata(i,1)=clustersALL(grot);
%  end
%end
%ciftisave(BO,'~/CCAclusters.dtseries.nii',WBC);

%%% all-200-based cluster outputs for paper v2
% BO=ciftiopen('/vols/Data/HCP/Phase2/groupE/groupICA/groupICA_3T_Q1-Q6related468_MSMsulc_d200.ica/melodic_IC.dtseries.nii',WBC); GM=BO.cdata;
% GM(GM<0)=0; [~,GM]=sort(GM,2,'descend'); GM=GM(:,1); BO.cdata=0*GM;
% for i=1:size(GM,1)
%   BO.cdata(i,1)=clustersALL(GM(i,1));
% end
% BO.cdata(BO.cdata==4)=-3; % make cluster 4 go negative to match colourmap needs
% ciftisave(BO,'~/CCAclusters200_4.dtseries.nii',WBC);

% %%% save MNI-soace versions of the clusters for mapping against Neurosynth, Juelich, etc.
% grot=read_avw('/vols/Data/HCP/Phase2/groupE/groupICA/groupICA_3T_Q1-Q6related468_MSMsulc_d200.ica/melodic_IC_sum_dil');
% for i=1:4
%   grotc=sum(grot(:,:,:,find(clustersALL==i)),4);
%   save_avw(grotc,sprintf('/home/fs0/steve/CCAclus%d',i),'f',[2 2 2 1]);
% end