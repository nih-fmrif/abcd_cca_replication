% abcd_perm_agg.m
% Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
% Created: 7/1/2020
% Modified: 7/9/20 (modified to accomodate the outputs of abcd_cca_batch.m)

% Script is used in batch processing to calculate CCA for each of the 100,000 permutations we generate

function abcd_perm_agg(perms_per_batch_in, N_perm_in, N_dim_in, abcd_cca_dir, n_subs_in)
    if nargin<5
        sprintf("ERROR, not enough arguments.")
        sprintf("Example: abcd_perm_agg(1000, 100000, 70, '/data/ABCD_MBDU/goyaln2/abcd_cca_replication/', 500)")
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

    s_agg = struct('perms',{},'r',{},'nullNETr',{},'nullNETv',{},'nullSMr',{},'nullSMv',{});

    r_agg=zeros(N_perm, N_dim+1);
    nullNETr_agg=[];
    nullNETv_agg=[];
    nullSMr_agg=[];
    nullSMv_agg=[];

    for perm = 1:perms_per_batch:N_perm
        % Iterate over 1 = 1, 1001, 2001, .... 99001
        % filename of .mat files we need to load are of form permutations_<#>.mat

        f_name = sprintf('%s/data/%d/permutations/permutations_%d.mat',abcd_cca_dir, n_subs, perm);

        % Load the .mat file
        s = load(f_name);

        for j = 1:perms_per_batch
            % Now iterate over the entries in the loaded structure (there will be perms_per_batch entries)
            
            r           =   s(j).r;
            nullNETr    =   s(j).nullNETr;
            nullNETv    =   s(j).nullNETv;
            nullSMr     =   s(j).nullSMr;
            nullSMv     =   s(j).nullSMv;

            r_agg           =   [grotRp_agg;    r' ];
            nullNETr_agg    =   [nullNETr_agg;  nullNETr'];
            nullNETv_agg    =   [nullNETv_agg;  nullNETv'];
            nullSMr_agg     =   [nullSMr_agg;   nullSMr'];
            nullSMv_agg     =   [nullSMv_agg;   nullSMv'];
        end
    end


    s_agg(1).perm=N_perm;
    s_agg(1).r=r_agg;
    s_agg(1).nullNETr=nullNETr_agg;
    s_agg(1).nullNETv=nullNETv_agg;
    s_agg(1).nullSMr=nullSMr_agg;
    s_agg(1).nullSMv=nullSMv_agg;

    % Now save
    save(sprintf('%s/data/%d/permutations_agg.mat', abcd_cca_dir, n_subs), 's_agg');

end