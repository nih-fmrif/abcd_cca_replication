%% Set up

perms_per_batch_in = 2000;
N_perm_in = 100000;
N_dim_in = 70;
n_subs_in = 5013;
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

% read in VARS and NET and do some preprocessing

% Load the Subjects X Nodes matrix (should be size Nx19900)
NET = load(sprintf('%s/data/%d/NET.txt', abcd_cca_dir, n_subs));

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

%% 10 fold 80-20 validation
for II=1:10
    % Sort the sample into train and test groups
    % get the family IDs
    fam = VARS(:,37)';

    % G1 will have 80% G2 will have everyone not in G1
    G1 = [];
    % families without replacement so same subject isn't drawn twice
    fam_norepl = fam;
    idx = 1:5013;
    G1_logi = logical(zeros(1,length(fam)));
    G2_logi = logical(zeros(1,length(fam)));
    n_subs = length(fam);

    % 80% of sample size
    target_80 = round(n_subs*0.8);

    % while less than 80% of sample size in G1
    while (length(G1)<target_80)
        % randomly draw a family from the without replacement list
        rand = randsample(fam_norepl,1);
        % find the indicies of all siblings that match family ID
        sibs = find(fam==rand);
        % append to G1
        G1 = [G1 sibs];
        % create a logical for those 
        G1_logi(sibs) = 1;
        % remove family from further drawings
        fam_norepl(fam_norepl==rand) = [];
    end

    % G2 is everyone who hasn't been assigned to G1
    G2_logi(G1_logi==0) = 1;
    G2 = idx(G2_logi);

    % preprocess the new NET and VARS from G1
    % for svd
	Nkeep1=100; 
	Nkeep2=100;

	% conf for group 1
	tmpconf=conf(G1,:);

	% NET for group 1, standardize and take svd
	tmpNET=NET(G1,:);
	NET1=nets_demean(tmpNET);
	NET1=NET1/std(NET1(:));
	amNET=abs(mean(NET));
	NET3=nets_demean(tmpNET./repmat(amNET,size(tmpNET,1),1));
	NET3(:,amNET<0.1)=[];
	NET3=NET3/std(NET3(:));
	grot=[NET1 NET3]; 
	NETd=nets_demean(grot-tmpconf*(pinv(tmpconf)*grot)); 
	[uu1G1,ss1G1,vv1G1]=nets_svds(NETd,Nkeep1); 

	% VARS for group 1, standardize each column
	varsd=palm_inormal(VARS(G1,:));
	for i=1:size(varsd,2)
		grot=(isnan(varsd(:,i))==0); 
		grotconf=nets_demean(tmpconf(grot,:)); 
		varsd(grot,i)=normalize(varsd(grot,i)-grotconf*(pinv(grotconf)*varsd(grot,i))); 
	end
	varsdCOV=zeros(size(varsd,1));
	for i=1:size(varsd,1)
		for j=1:size(varsd,1)
			grot=varsd([i j],:); 
			grot=cov(grot(:,sum(isnan(grot))==0)'); 
			varsdCOV(i,j)=grot(1,2);  
		end; 
	end
	varsdCOV2=nearestSPD(varsdCOV); % scatter(varsdCOV(:),varsdCOV2(:));
	[uu,dd]=eigs(varsdCOV2,Nkeep2); 
	uu2G1=uu-tmpconf*(pinv(tmpconf)*uu);   % deconfound again just to be safe
	ss2G1=sqrt(dd); 
	grot=uu2G1 * inv(ss2G1); 
	vv2G1=zeros(size(varsd',1),size(grot,2));    %  vv2G1 = varsd' * grot; % try to get the other eigenvectors
	for i=1:size(varsd',1)
	    for j=1:size(grot,2)
	      groti=isnan(varsd(:,i))==0;
	      vv2G1(i,j) = varsd(groti,i)' * grot(groti,j) * length(groti) / sum(groti);
	    end
    end
      
    % Do the CCA on the 80%
    [grotAG1,grotBG1,grotRG1,grotUG1,grotVG1,grotstatsG1]=canoncorr(uu1G1,uu2G1); 

    % conf
	tmpconf=conf(G2,:);   % now multiply the CCA outputs into the test dataset

	% NET for group 2, standardize
	tmpNET=NET(G2,:);
	NET1=nets_demean(tmpNET);
	NET1=NET1/std(NET1(:));
	amNET=abs(mean(NET));
	NET3=nets_demean(tmpNET./repmat(amNET,size(tmpNET,1),1));
	NET3(:,amNET<0.1)=[];
	NET3=NET3/std(NET3(:));
	grot=[NET1 NET3]; 
	NETd=nets_demean(grot-tmpconf*(pinv(tmpconf)*grot));

	% VARS for group 2, standardize
	varsd=palm_inormal(VARS(G2,:));
	for i=1:size(varsd,2)
		grot=(isnan(varsd(:,i))==0); 
		grotconf=nets_demean(tmpconf(grot,:)); 
		varsd(grot,i)=normalize(varsd(grot,i)-grotconf*(pinv(grotconf)*varsd(grot,i))); 
    end

    % compare to previous CCA on 80%
	grot_U2 = NETd  * vv1G1 * ss1G1 * grotAG1;
	grot=vv2G1 * ss2G1 * grotBG1; 
	grot_V2=zeros(size(varsd,1),size(grot,2));        % grot_V2 = varsd * vv2G1 * ss2G1 * grotBG1   =  varsd * grot
	for i=1:size(varsd,1)
		for j=1:size(grot,2)
			groti=isnan(varsd(i,:))'==0; 
			grot_V2(i,j) = varsd(i,groti) * grot(groti,j) * length(groti) / sum(groti); 
		end; 
    end

    grotRRR(II) = corr(grot_U2(:,2),grot_V2(:,2))   % correlate the test-data U and V then permute to check p-values

    Nperm=1000;
    
    % read in unaltered VARS
    VARS_forG2 = strcsvread(sprintf('%s/data/%d/VARS.txt', abcd_cca_dir, n_subs));
   
    % subset VARS for G2, put header are write to csv
    G2_vars = VARS_forG2(2:end,:);
    G2_vars = G2_vars(G2,:);
    T = cell2table(G2_vars);
    T.Properties.VariableNames = VARS_forG2(1,:);
    writetable(T,'G2_vars.csv')
    
    % run abcd2blocks
    [EB,tab] = abcd2blocks('G2_vars.csv', 'G2_blocks.csv', [100 10]);
    
    % run palm
    Pset=palm_quickperms([ ], EB, Nperm, true, false, true, true);

    % run through the permutations
    for j=1:Nperm
        grotRRRnull(j)=corr(grot_U2(:,2),grot_V2(Pset(:,j),2)); 
    end
	
    
    grotRRRp(II)=(1+sum(grotRRRnull(2:end,1)>=grotRRR(II)))/Nperm
	grotRRRm(II)=mean(grotRRRnull); 
    grotRRRs(II)=std(grotRRRnull);
end

save('80-20-mode2.mat','grotRRR','grotRRRp','grotRRRm','grotRRRs') 

[grotRRR' grotRRRp' grotRRRm' grotRRRs']
mean([grotRRR' grotRRRp' grotRRRm' grotRRRs'])
    



