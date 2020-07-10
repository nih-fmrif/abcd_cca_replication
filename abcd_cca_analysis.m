% abcd_cca_analysis.m
% Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
% Created: June 2020
% Modified: 7/10/20

% CCA processing script for the ABCD connectome and SM data
% Required inputs are the NET.txt and VARS.txt files located in abcd_cca_replication/data/<num_subs>/

function abcd_cca_analysis(perms_per_batch_in, N_perm_in, N_dim_in, abcd_cca_dir, n_subs_in)
  mlock
  if nargin<5
    sprintf("ERROR, not enough arguments.")
    sprintf("Example: abcd_cca_analysis(2000, 100000, 70, '/data/ABCD_MBDU/goyaln2/abcd_cca_replication/', 500)")
    return
  end
  
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


  %% --- Read in data, set some variables, create confounds matrix ---
  % VARS_0 = Subjects X SMs text file
  VARS_0=strcsvread(sprintf('%s/data/%d/VARS.txt', abcd_cca_dir, n_subs));

  % Load the Subjects X Nodes matrix (should be size Nx19900)
  N0=load(sprintf('%s/data/%d/NET.txt', abcd_cca_dir, n_subs));   

  ica_sms_0=fileread(sprintf('%s/data/ica_subject_measures.txt', abcd_cca_dir));
  ica_sms = strsplit(ica_sms_0);

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
  sms_original_order = VARS_0(1,:)

  VARS=cell2mat(VARS_0(2:end,:));


  %% --- CREATE CONFOUND MATRIX ---
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
  conf  = palm_inormal([ VARS(:,[site_col mri_man_col mean_fd_col bmi_col weight_col]) VARS(:,[wholebrain_col intracran_col]).^(1/3) ]);  % Gaussianise
  conf(isnan(conf)|isinf(conf)) = 0;                % impute missing data as zeros
  conf  = nets_normalise([conf conf(:,3:end).^2]);  % add on squared terms and renormalise (additional SMs made from 3-7)
  conf(isnan(conf)|isinf(conf)) = 0;                % again convert NaN/inf to 0 (above line makes them reappear for some reason)


  %% --- SM PROCESSING ---
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
  corrcoef(S4,S3Cov)  %0.9999

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
  % N5
  [N5,ss1,vv1] = nets_svds(N4,N_dim); % PCA of netmat via SVD reduction


  %% --- CCA ---
  fprintf("Running CCA on matrices S5 and N5\n")
  [A, B, R, U, V, initial_stats] = canoncorr(N5,S5);

  % Plot
  figure;
  scatter(U(:,1), V(:,1))
  % Plot with regression line
  figure;
  plotregression(U(:,1), V(:,1))

  % %% Calculate CCA Mode 1 weights for netmats and SMs
  % % Netmat weights for CCA mode 1
  % grotAA = corr(grotU(:,1),N0)';
  % % or
  % grotAAd = corr(grotU(:,1),N4(:,1:size(N0,2)))'; % weights after deconfounding

  % %%% SM weights for CCA mode 1
  % grotBB = corr(grotV(:,1),palm_inormal(S1),'rows','pairwise');
  % % or 
  % varsgrot=palm_inormal(S1);
  % for i=1:size(varsgrot,2)
  %   grot=(isnan(varsgrot(:,i))==0); grotconf=nets_demean(conf(grot,:)); varsgrot(grot,i)=nets_normalise(varsgrot(grot,i)-grotconf*(pinv(grotconf)*varsgrot(grot,i)));
  % end
  % grotBBd = corr(grotV(:,1),varsgrot,'rows','pairwise')'; % weights after deconfounding


  %% --- POSITIVE-NEGATIVE AXIS ---
  %%% actually this is the CORRECT thing to do (instead of CorCCA below) - but makes almost no difference
  %varsgrot=inormal(vars);
  %for i=1:size(varsgrot,2)
  %  grot=(isnan(varsgrot(:,i))==0); grotconf=nets_demean(conf(grot,:)); varsgrot(grot,i)=nets_normalise(varsgrot(grot,i)-grotconf*(pinv(grotconf)*varsgrot(grot,i)));
  %end
  %CorCCAd = corr(grotV(:,I),varsgrot)';

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
      disp(str);
    end
  end

  x   = ones([length(toplist),1]);
  dx  = 0.1;
  y   = 1:length(toplist);
  dy  = 0.1;
  set(0,'DefaultTextInterpreter','none')
  scatter(x,y);
  text(x+dx, y+dy, strlist);


  %% --- VARIANCE ANALYSES ---
  % Load the summarized permutation data .mat file
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

  % variance_data_NET   = [ sum(corr(U,N0).^2,2) prctile(nullNETv,5,2) mean(nullNETv,2) prctile(nullNETv,95,2) sum(corr(N5,N0).^2,2) ] * 100 / size(N0,2);

  variance_data_NET   = [ sum(corr(U, N0).^2,2) perm_data.s_agg(1).nullNETv_prctile_5 perm_data.s_agg(1).nullNETv_mean perm_data.s_agg(1).nullNETv_prctile_95 sum(corr(N5,N0).^2,2) ] * 100 / size(N0,2);
  variance_data_VARS  = [ sum(corr(V,tmp_VARS,'rows','pairwise').^2,2) perm_data.s_agg(1).nullSMv_prctile_5 perm_data.s_agg(1).nullSMv_mean perm_data.s_agg(1).nullSMv_prctile_95 sum(corr(S5,tmp_VARS,'rows','pairwise').^2,2)  ] * 100 / size(tmp_VARS,2);

  % Look at first 20 modes
  I=1:20;

  % Connectomes variance
  figure;
  subplot(2,1,1); 
  hold on;
  % Draw the rectangles for null distributions per mode
  for i=1:length(I)
    rectangle('Position',[i-0.5 variance_data_NET(i,2) 1 variance_data_NET(i,4)-variance_data_NET(i,2)],'FaceColor',[0.8 0.8 0.8],'EdgeColor',[0.8 0.8 0.8]);
  end
  plot(variance_data_NET(I,3),'k');
  plot(variance_data_NET(I,1),'b');
  plot(variance_data_NET(I,1),'b.');
  % plot(variance_data_NET(I,5),'g');  % turned off showing the PCA equivalent plots

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
    rectangle('Position',[i-0.5 variance_data_VARS(i,2) 1 variance_data_VARS(i,4)-variance_data_VARS(i,2)],'FaceColor',[0.8 0.8 0.8],'EdgeColor',[0.8 0.8 0.8]);
  end
  plot(variance_data_VARS(I,3),'k');
  plot(variance_data_VARS(I,1),'b');
  plot(variance_data_VARS(I,1),'b.');
  % plot(variance_data_VARS(I,5),'g');
  % th2 = title({'';'Subject measures total % variance explained by CCA modes';''});
  % ylabel('%% variance (SMs)')
  % xlabel('CCA Mode')
  % xlim([1 20])
  % ylim([0 2])
  % yticks([0 0.5 1 1.5 2])
  % set(gca,'FontSize',15)

end