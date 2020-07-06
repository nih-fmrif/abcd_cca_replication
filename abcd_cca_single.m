% abcd_cca_single.m
% Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
% Created: 7/1/2020
% Modified:

% Script is used in batch processing to calculate CCA for each of the 100,000 permutations we generate
% Each CCA result is saved out to a text file for use in abcd_cca_analysis.m

function abcd_cca_single(perm, N_perm, N_dim)
    if nargin<3
        % Number of permutations, default 100,000
        N_perm=100000;
        N_dim=70;
    end

    addpath(genpath('./dependencies/'));
    addpath(genpath('./data/'));
    
    % Load data
    % Matrix S1 (only ICA sms)
    S1=load('./data/S1.txt'); 
    % Matrix S5
    S5=load('./data/S5.txt');

    % Matrix N0 (raw connectome data)
    N0=load('./data/N0.txt'); 
    % Matrix N5 (post-PCA connectome matrix)
    N5=load('./data/N5.txt'); 
  
    % Permutation matrix
    PAPset=load('./data/PAPset.txt');

    grotvars=palm_inormal(S1);
    grotvars(:,std(grotvars)<1e-10)=[];
    grotvars(:,sum(isnan(grotvars)==0)<20)=[];

    % permutation calculation
    r=zeros(N_dim+1);

    [A, B, r, U, V, stats] = canoncorr(N5,S5(PAPset(:,perm),:));
    r(end)=mean(r(1:end-1));

    nullNETr=corr(U(:,1),N0)';
    nullSMr=corr(V(:,1),grotvars(PAPset(:,perm),:),'rows','pairwise')';
    nullNETv=sum(corr(U,N0).^2,2);
    nullSMv=sum(corr(V,grotvars(PAPset(:,perm),:),'rows','pairwise').^2,2);
    
    % Now save
    writematrix(r, sprintf('./data/permutations/grotRp_%d',perm));
    writematrix(nullNETr, sprintf('./data/permutations/nullNETr_%d',perm));
    writematrix(nullSMr, sprintf('./data/permutations/nullSMr_%d',perm));
    writematrix(nullNETv, sprintf('./data/permutations/nullNETv_%d',perm));
    writematrix(nullSMv, sprintf('./data/permutations/nullSMv_%d',perm));

end
