% train_test_split.m
% Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
% Created: 8/8/20
% Modified:

% Script for 80-20 train-test split testing
% This function operates on ONE iteration (we do 10 total), and is called by a swarm job

function train_test_split(itrs_in, N_dim_in, abcd_cca_dir, n_subs_in)
    if nargin<4
        sprintf("ERROR, not enough arguments.")
        sprintf("Example: abcd_cca_batch(1, 70, '/data/ABCD_MBDU/goyaln2/abcd_cca_replication/', 5013)")
        return
	end

    if ~isdeployed
        addpath(genpath(sprintf('%s/dependencies/', abcd_cca_dir)));
        addpath(genpath(sprintf('%s/data/', abcd_cca_dir)));
        itrs   =   itrs_in;
        N_dim   =   N_dim_in;
        n_subs  =   n_subs_in;
    elseif isdeployed
        % When compiled matlab, it reads the command line args all as strings so we need to convert
        itrs    =   str2num(itrs_in);
        N_dim   =   str2num(N_dim_in);
        n_subs  =   str2num(n_subs_in);
    end

    % Load the iteration file (it is a list of subject IDs for subjects in the 80% train set)
	itrs_0              =   fileread(sprintf('%s/data/%d/iterations/%d.txt', abcd_cca_dir, n_subs, iteration));
	iteration_subjects  =   strsplit(itrs_0);

    % Create subject subsets
    % G1 = train
    % G2 = test
    % iSTART=1;
    % G1=[];
    % G2=[];
    % grot=oldPTN.twinssorted;
    % grot(eye(length(grot))==1)=1;
    % for i=2:length(oldPTN.twinlist)+1
    %     if (i==length(oldPTN.twinlist)+1) | ( grot(:,iSTART)' * grot(:,i) == 0 ) % then we have started a new family
    %         j=oldPTN.twinlist(iSTART:i-1);
    %         if (rand<0.8)
    %             G1=[G1 j];
    %         else
    %             G2=[G2 j];
    %         end
    %         iSTART=i;
    %     end;  
    % end;

    % Nkeep1=100; Nkeep2=100;
    % N_dim_NET=100;
    % N_dim_VARS=100;

    %%% TRAIN DATASET STUFF

    % Conf matrix
    tmpconf=conf(G1,:);

    % Generate N1_TRAIN --> N5_TRAIN
    N0_TRAIN                =   N0(G1,:);
    N1_TRAIN                =   nets_demean(N0_TRAIN);
    N1_TRAIN                =   N1_TRAIN/std(N1_TRAIN(:));
    am_NET                  =   abs(mean(N0_TRAIN));
    N2_TRAIN                =   nets_demean(N0_TRAIN./repmat(am_NET,size(N0_TRAIN,1),1));
    N2_TRAIN(:,am_NET<0.1)  =   [];          
    N2_TRAIN                =   N2_TRAIN/std(N2_TRAIN(:));                          
    N3_TRAIN                =   [N1_TRAIN N2_TRAIN];
    % N4, formed by regressing the confounds matrix out of N3
    N4_TRAIN                =   nets_demean(N3-tmpconf*(pinv(tmpconf)*N3));
    % PCA after residualization (purpose here is dimensionality reduction)
    [N5_TRAIN,ss1,vv1]      =   nets_svds(N4_TRAIN, N_dim);

    % ORIGINAL SMITH CODE (N1 --> N5)
    % tmpNET=NET(G1,:);
    % NET1=demean(tmpNET);
    % NET1=NET1/std(NET1(:));
    % amNET=abs(mean(NET));
    % NET3=demean(tmpNET./repmat(amNET,size(tmpNET,1),1));
    % NET3(:,amNET<0.1)=[];
    % NET3=NET3/std(NET3(:));
    % grot=[NET1 NET3]; 
    % NETd=demean(grot-tmpconf*(pinv(tmpconf)*grot));
    % % uu1G1 == N5
    % [uu1G1,ss1G1,vv1G1]=nets_svds(NETd,Nkeep1);

    % Generate S1_TRAIN --> S5_TRAIN
    S1_TRAIN=[VARS(G1,ica_sms_idx)];
    S2_TRAIN=palm_inormal(S1_TRAIN); % Gaussianise
    S3_TRAIN=S2_TRAIN;
    for i=1:size(S3_TRAIN,2) % deconfound ignoring missing data
        grot=(isnan(S3_TRAIN(:,i))==0);
        grotconf=nets_demean(tmpconf(grot,:));
        S3_TRAIN(grot,i)=normalize(S3_TRAIN(grot,i)-grotconf*(pinv(grotconf)*S3_TRAIN(grot,i)));
    end
    S3Cov_TRAIN =   zeros(size(S3_TRAIN,1));
    for i=1:size(S3_TRAIN,1) % estimate "pairwise" covariance, ignoring missing data
        for j=1:size(S3_TRAIN,1)
            grot=S3_TRAIN([i j],:);
            grot=cov(grot(:,sum(isnan(grot))==0)');
            S3Cov_TRAIN(i,j)=grot(1,2);
        end
    end
    S4_TRAIN    =   nearestSPD(S3Cov_TRAIN); % project onto the nearest valid covariance matrix. This method avoids imputation (we can't have any missing values before running the PCA)
    % Generate S5, the top eigenvectors for SMs, to avoid overfitting and reduce dimensionality
    [uu,dd]     =   eigs(S4_TRAIN, N_dim);       % SVD (eigs actually)
    S5_TRAIN    =   uu-tmpconf*(pinv(tmpconf)*uu);   % deconfound again just to be safe 
    
    % this is S1 --> S5 (Smith code)
    % varsd=inormal(vars(G1,varskeep));
    % for i=1:size(varsd,2)
    %     grot=(isnan(varsd(:,i))==0);
    %     grotconf=demean(tmpconf(grot,:));
    %     varsd(grot,i)=normalise(varsd(grot,i)-grotconf*(pinv(grotconf)*varsd(grot,i)));
    % end
    % varsdCOV=zeros(size(varsd,1));
    % for i=1:size(varsd,1)
    %     for j=1:size(varsd,1)
    %         grot=varsd([i j],:);
    %         grot=cov(grot(:,sum(isnan(grot))==0)');
    %         varsdCOV(i,j)=grot(1,2);
    %     end
    % end
    % varsdCOV2=nearestSPD(varsdCOV); % scatter(varsdCOV(:),varsdCOV2(:));
    % [uu,dd]=eigs(varsdCOV2,Nkeep2);
    % uu2G1=uu-tmpconf*(pinv(tmpconf)*uu);   % deconfound again just to be safe


    % NOT SURE WHAT THIS DOES, CALCUALTES VV2G1?
    ss2G1=sqrt(dd);
    grot=uu2G1 * inv(ss2G1);
    vv2G1=zeros(size(varsd',1),size(grot,2));    %  vv2G1 = varsd' * grot; % try to get the other eigenvectors
    for i=1:size(varsd',1)
        for j=1:size(grot,2)
            groti=isnan(varsd(:,i))==0;
            vv2G1(i,j) = varsd(groti,i)' * grot(groti,j) * length(groti) / sum(groti);
        end
    end

    % TRAINING CCA
    [A_TRAIN, B_TRAIN, R_TRAIN, U_TRAIN, V_TRAIN ,STATS_TRAIN]=canoncorr(N5_TRAIN, S5_TRAIN);
    % [grotAG1,grotBG1,grotRG1,grotUG1,grotVG1,grotstatsG1]=canoncorr(uu1G1,uu2G1);
    % Code below appears to just check how similar the training CCA model is to the original (I think?)
    % grotRG1
    % grotAA1=corr(grotUG1(:,1:5),oldCCA.NETd(G1,:))';
    % grotAA=corr(oldCCA.grotU(:,1),oldCCA.NETd)';
    % corr(grotAA,grotAA1)                                       % check it agrees with original
    % grotBB1=corr(grotVG1(:,1:5),oldCCA.varsd(G1,:),'rows','pairwise')';
    % grotBB=corr(oldCCA.grotV(:,1),oldCCA.varsd,'rows','pairwise')';
    % corr(grotBB,grotBB1) % check it agrees with original





    %%%% TEST DATASET STUFF
    tmpconf=conf(G2,:);   % now multiply the CCA outputs into the test dataset

    N0_TEST                 =   NET(G2,:);
    N1_TEST                 =   nets_demean(N0_TEST);
    N1_TEST                 =   N1_TEST/std(N1_TEST(:));
    am_NET                  =   abs(mean(N0_TEST));
    N2_TEST                 =   nets_demean(N0_TEST./repmat(am_NET,size(N0_TEST,1),1));
    N2_TEST(:,am_NET<0.1)   =   [];          
    N2_TEST                 =   N2_TEST/std(N2_TEST(:));                          
    N3_TEST                 =   [N1_TEST N2_TEST];
    N4_TEST                 =   nets_demean(N3_TEST-tmpconf*(pinv(tmpconf)*N3_TEST));
    
    S1_TEST =   [VARS(G2,ica_sms_idx)];
    S2_TEST =   palm_inormal(S1_TEST); % Gaussianise
    S3_TEST =   S2_TEST;
    for i=1:size(S3_TEST,2) % deconfound ignoring missing data
        grot            =   (isnan(S3_TEST(:,i))==0);
        grotconf        =   nets_demean(tmpconf(grot,:));
        S3_TEST(grot,i) =   normalize(S3_TEST(grot,i)-grotconf*(pinv(grotconf)*S3_TEST(grot,i)));
    end


    % OPRIGINAL SMITH CODE
    % tmpconf=conf(G2,:);   % now multiply the CCA outputs into the test dataset
    % tmpNET=NET(G2,:);
    % NET1=demean(tmpNET);
    % NET1=NET1/std(NET1(:));
    % amNET=abs(mean(NET));
    % NET3=demean(tmpNET./repmat(amNET,size(tmpNET,1),1));
    % NET3(:,amNET<0.1)=[];
    % NET3=NET3/std(NET3(:));
    % grot=[NET1 NET3];
    % NETd=demean(grot-tmpconf*(pinv(tmpconf)*grot));

    % varsd=inormal(vars(G2,varskeep));
    % for i=1:size(varsd,2)
    %     grot=(isnan(varsd(:,i))==0)
    %     grotconf=demean(tmpconf(grot,:))
    %     varsd(grot,i)=normalise(varsd(grot,i)-grotconf*(pinv(grotconf)*varsd(grot,i))); 
    % end

    % grot_U2 = NETd  * vv1G1 * ss1G1 * grotAG1;
    % grot=vv2G1 * ss2G1 * grotBG1; 
    % grot_V2=zeros(size(varsd,1),size(grot,2));        % grot_V2 = varsd * vv2G1 * ss2G1 * grotBG1   =  varsd * grot
    % for i=1:size(varsd,1)
    %     for j=1:size(grot,2)
    %         groti=isnan(varsd(i,:))'==0;
    %         grot_V2(i,j) = varsd(i,groti) * grot(groti,j) * length(groti) / sum(groti);
    %     end; 
    % end
    


    % Estimate U_TEST and V_TEST
    grot_U2 = NETd  * vv1G1 * ss1G1 * grotAG1;
    grot=vv2G1 * ss2G1 * grotBG1; 
    grot_V2=zeros(size(varsd,1),size(grot,2));        % grot_V2 = varsd * vv2G1 * ss2G1 * grotBG1   =  varsd * grot
    for i=1:size(varsd,1)
        for j=1:size(grot,2)
            groti=isnan(varsd(i,:))'==0;
            grot_V2(i,j) = varsd(i,groti) * grot(groti,j) * length(groti) / sum(groti);
        end;
    end

    grotRRR(II)=corr(grot_U2(:,1),grot_V2(:,1))   % correlate the test-data U and V then permute to check p-values
    Nperm=1000;
    addpath(sprintf('%s/PALM/perms',FMRIB));
    ! echo "SubjectID,MotherID,FatherID,TwinStatus,Zygosity" > grotgrot.csv
    for i=1:length(G2)
        [i vars(i,1)]
        system(sprintf('cat /vols/Data/HCP/Phase2/scripts/NEW/scripts/vars/palm.csv | grep %d | sed ''s/%d/%d/g'' >> grotgrot.csv',vars(i,1),vars(i,1),i))
    end
    PAB = hcp2blocks('grotgrot.csv',false,[1:length(G2)]');
    PAnP0=Nperm;
    run_this_for_hcp;
    for j=1:Nperm
        grotRRRnull(j)=corr(grot_U2(:,1),grot_V2(PAPset(:,j),1));
    end
    grotRRRp(II)=(1+sum(grotRRRnull(2:end,1)>=grotRRR(II)))/Nperm
    grotRRRm(II)=mean(grotRRRnull); grotRRRs(II)=std(grotRRRnull); 

end;
[grotRRR' grotRRRp' grotRRRm' grotRRRs']
mean([grotRRR' grotRRRp' grotRRRm' grotRRRs'])
