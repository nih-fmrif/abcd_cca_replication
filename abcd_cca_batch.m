% abcd_cca_batch.m
% Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
% Created: 7/9/20
% Modified:

% Script is used in batch processing to calculate CCA for each of the 100,000 permutations we generate
% This script is given a start index and the number of permutations to calculate
% NOTE: this script is COMPILED, and it expects input args to be strings (from cmd line), so we type cast the args

% The result of the script is a .mat file with a structure of the following format:
% .mat file
% {
%     1: {
%         perm
%         r
%         nullNETr
%         nullSMr
%         nullNETv
%         nullSMv
%     }
%     2: {}...
% }

function abcd_cca_batch(start_idx_in, num_perms_in, N_dim_in, abcd_cca_dir, n_subs_in)
    if nargin<5
        sprintf("ERROR, not enough arguments.")
        sprintf("Example: abcd_cca_batch(1, 100, 70, '/data/ABCD_MBDU/goyaln2/abcd_cca_replication/', 1000)")
        return
	end

    if ~isdeployed
        addpath(genpath(sprintf('%s/dependencies/', abcd_cca_dir)));
        addpath(genpath(sprintf('%s/data/', abcd_cca_dir)));
        start_idx   =   start_idx_in;
        num_perms   =   num_perms_in;
        N_dim   =   N_dim_in;
        n_subs  =   n_subs_in;
    elseif isdeployed
        % When compiled matlab, it reads the command line args all as strings so we need to convert
        start_idx   =   str2num(start_idx_in);
        num_perms   =   str2num(num_perms_in);
        N_dim   =   str2num(N_dim_in);
        n_subs  =   str2num(n_subs_in);
    end
        
    % Load data
    % Matrix S1 (only ICA sms)
    s1  =   sprintf('%s/data/%d/S1.txt', abcd_cca_dir, n_subs);
    % Matrix S5 (post-PCA SM matrix)
    s5  =   sprintf('%s/data/%d/S5.txt', abcd_cca_dir, n_subs);
    % Matrix N0 (raw connectome data)
    n0  =   sprintf('%s/data/%d/N0.txt', abcd_cca_dir, n_subs);
    % Matrix N5 (post-PCA connectome matrix)
    n5  =   sprintf('%s/data/%d/N5.txt', abcd_cca_dir, n_subs);

    S1  =   load(s1); 
    S5  =   load(s5);
    N0  =   load(n0);
    N5  =   load(n5);
  
    % Permutation matrix
    pset=sprintf('%s/data/%d/Pset.txt', abcd_cca_dir, n_subs);
    Pset=load(pset);

    % Temporary version of VARS used for permutation calcs
    grotvars=palm_inormal(S1);
    grotvars(:,std(grotvars)<1e-10)=[];
    grotvars(:,sum(isnan(grotvars)==0)<20)=[];

    % struct for storing the result of the CCAs for each permutation
    % Each structure entry (i.e. s(1), s(2)..) is a permutation.
    % The structure fields are:
    % perm = the permutation number (between 1 to 100,000)
    % r = the vector r for the permutation
    % nullNETr  =   the permutation's mode 1 connectome weights correlation to the RAW connectome matrix
    % nullNETv  =   for this permutation, the summation of the correlation values between each mode's connectome weights and the RAW connectome matrix
    % nullSMr   =   for this permutation, CCA mode 1 SM weights correalated against the S1 matrix
    % nullSMv   =   for this permutation, the summation of the correlation values between each mode's SM weights and the S1 matrix
    s = struct('perm',{},'r',{},'nullNETr',{},'nullNETv',{},'nullSMr',{},'nullSMv',{});
    
    r=zeros(N_dim+1, 1);
    count=1;
    for perm = start_idx:(start_idx+num_perms)
        [A, B, r(1:end-1), U, V, stats] = canoncorr(N5,S5(Pset(:,perm),:));
        r(end)=mean(r(1:end-1));
    
        nullNETr=corr(U(:,1),N0)';
        nullNETv=sum(corr(U,N0).^2,2);

        nullSMr=corr(V(:,1),grotvars(Pset(:,perm),:),'rows','pairwise')';
        nullSMv=sum(corr(V,grotvars(Pset(:,perm),:),'rows','pairwise').^2,2);

        s(count).perm=perm;
        s(count).r=r;
        s(count).nullNETr=nullNETr;
        s(count).nullNETv=nullNETv;
        s(count).nullSMr=nullSMr;
        s(count).nullSMv=nullSMv;
        
        count = count + 1;
    end

    % Save .mat file with the permutations
    save(sprintf('%s/data/%d/perms_%d.mat', abcd_cca_dir, n_subs, start_idx), s);

end