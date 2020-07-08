% abcd_cca_single.m
% Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
% Created: 7/1/2020
% Modified:

% Script is used in batch processing to calculate CCA for each of the 100,000 permutations we generate
% Each CCA result is saved out to a text file for use in abcd_cca_analysis.m
% NOTE: this script is COMPILED, and it expects input args to be strings (from cmd line), so we type cast the args

function abcd_cca_single(perm_str, N_perm_str, N_dim_str, abcd_cca_dir, n_subs_str)
    if nargin<5
        sprintf("ERROR, not enough arguments.")
        sprintf("Example: abcd_perm_agg(1, 100000, 70, '/data/ABCD_MBDU/goyaln2/abcd_cca_replication/', 5013)")
        return
	end

    if ~isdeployed
        addpath(genpath(sprintf('%s/dependencies/', abcd_cca_dir)));
        addpath(genpath(sprintf('%s/data/', abcd_cca_dir)));
    end
    
    perm=int32(perm_str)
    N_perm=int32(N_perm_str)
    N_dim=int32(N_dim_str)
    n_subs=int32(n_subs_str)
    
    % Load data
    % Matrix S1 (only ICA sms)
    s1=sprintf('%s/data/%d/S1.txt', abcd_cca_dir, n_subs)
    % Matrix S5 (post-PCA SM matrix)
    s5=sprintf('%s/data/%d/S5.txt', abcd_cca_dir, n_subs)
    % Matrix N0 (raw connectome data)
    n0=sprintf('%s/data/%d/N0.txt', abcd_cca_dir, n_subs)
    % Matrix N5 (post-PCA connectome matrix)
    n5=sprintf('%s/data/%d/N5.txt', abcd_cca_dir, n_subs)

    S1=load(s1); 
    S5=load(s5);
    N0=load(n0);
    N5=load(n5);
  
    % Permutation matrix
    pset=sprintf('%s/data/%d/Pset.txt', abcd_cca_dir, n_subs);
    Pset=load(pset);

    grotvars=palm_inormal(S1);
    grotvars(:,std(grotvars)<1e-10)=[];
    grotvars(:,sum(isnan(grotvars)==0)<20)=[];

    % permutation calculation
    r=zeros(N_dim+1, 1);

    [A, B, r(1:end-1), U, V, stats] = canoncorr(N5,S5(Pset(:,perm),:));
    r(end)=mean(r(1:end-1));

    nullNETr=corr(U(:,1),N0)';
    nullSMr=corr(V(:,1),grotvars(Pset(:,perm),:),'rows','pairwise')';
    nullNETv=sum(corr(U,N0).^2,2);
    nullSMv=sum(corr(V,grotvars(Pset(:,perm),:),'rows','pairwise').^2,2);
    
    % Now save
    writematrix(r, sprintf('%s/data/%d/permutations/grotRp_%d', abcd_cca_dir, n_subs, perm));
    writematrix(nullNETr, sprintf('%s/data/%d/permutations/nullNETr_%d', abcd_cca_dir, n_subs, perm));
    writematrix(nullSMr, sprintf('%s/data/%d/permutations/nullSMr_%d', abcd_cca_dir, n_subs, perm));
    writematrix(nullNETv, sprintf('%s/data/%d/permutations/nullNETv_%d', abcd_cca_dir, n_subs, perm));
    writematrix(nullSMv, sprintf('%s/data/%d/permutations/nullSMv_%d', abcd_cca_dir, n_subs, perm));

end
