% abcd_perm_agg.m
% Written by Nikhil Goyal, National Institute of Mental Health, 2019-2020
% Created: 7/1/2020
% Modified: 7/10/20 (modified to accomodate the outputs of the updated abcd_cca_batch.m which reduces the amount of data in each .mat file)

% Script is used in batch processing to calculate CCA for each of the 100,000 permutations we generate

function abcd_perm_agg(perms_per_batch_in, N_perm_in, N_dim_in, abcd_cca_dir, n_subs_in)
    if nargin<5
        sprintf("ERROR, not enough arguments.")
        sprintf("Example: abcd_perm_agg(2000, 100000, 70, '/data/ABCD_MBDU/goyaln2/abcd_cca_replication/', 5013)")
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

    % s_agg = struct('perms',{},'r',{},'nullNETr',{},'nullNETv',{},'nullSMr',{},'nullSMv',{});

    r_agg                       =   [];
    
    nullNETv_prctile_95_agg     =   [];
    nullNETv_prctile_5_agg      =   [];
    nullNETv_mean_agg           =   [];

    nullSMv_prctile_95_agg      =   [];
    nullSMv_prctile_5_agg       =   [];
    nullSMv_mean_agg            =   [];

    nullNETr_prctile_95_agg     =   [];
    nullSMr_prctile_95_agg      =   [];

    for perm = 1:perms_per_batch:N_perm
        % Iterate over 1 = 1, 1001, 2001, .... 99001
        % filename of .mat files we need to load are of form permutations_<#>.mat

        f_name = sprintf('%s/data/%d/permutations/permutations_%d.mat',abcd_cca_dir, n_subs, perm);

        % Load the .mat file
        mat_file = load(f_name);

        r_agg                       =   [r_agg;                     mat_file.s(1).r                     ];

        nullNETv_prctile_95_agg     =   [nullNETv_prctile_95_agg;   mat_file.s(1).nullNETv_prctile_95   ];
        nullNETv_prctile_5_agg      =   [nullNETv_prctile_5_agg;    mat_file.s(1).nullNETv_prctile_5    ];
        nullNETv_mean_agg           =   [nullNETv_mean_agg;         mat_file.s(1).nullNETv_mean         ];
        
        nullSMv_prctile_95_agg      =   [nullSMv_prctile_95_agg;    mat_file.s(1).nullSMv_prctile_95    ];
        nullSMv_prctile_5_agg       =   [nullSMv_prctile_5_agg;     mat_file.s(1).nullSMv_prctile_5     ];
        nullSMv_mean_agg            =   [nullSMv_mean_agg;          mat_file.s(1).nullSMv_mean          ];
        
        nullNETr_prctile_95_agg     =   [nullNETr_prctile_95_agg;   mat_file.s(1).nullNETr_prctile_95   ];
        nullSMr_prctile_95_agg      =   [nullSMr_prctile_95_agg;    mat_file.s(1).nullSMr_prctile_95    ];

    end

    s_agg = struct( 'perms_per_batch',          {}, ...
                    'tot_perms',                {}, ...
                    'nullNETv_prctile_95',      {}, ...
                    'nullNETv_prctile_5',       {}, ...
                    'nullNETv_mean',            {}, ...
                    'nullSMv_prctile_95',       {}, ...
                    'nullSMv_prctile_5',        {}, ...
                    'nullSMv_mean',             {}, ...
                    'nullNETr_prctile_95',      {}, ...
                    'nullSMr_prctile_95',       {}, ...
                    'r',                        {}  );

    s_agg(1).perms_per_batch        =   perms_per_batch;
    s_agg(1).tot_perms              =   N_perm;

    s_agg(1).nullNETv_prctile_95    =   prctile(    nullNETv_prctile_95_agg,    95,1);
    s_agg(1).nullNETv_prctile_5     =   prctile(    nullNETv_prctile_5_agg,     5,1);
    s_agg(1).nullNETv_mean          =   mean(       nullNETv_mean_agg,          1);

    s_agg(1).nullSMv_prctile_95     =   prctile(    nullSMv_prctile_95_agg,     95, 1);
    s_agg(1).nullSMv_prctile_5      =   prctile(    nullSMv_prctile_5_agg,      5, 1);
    s_agg(1).nullSMv_mean           =   mean(       nullSMv_mean_agg,           1);

    s_agg(1).nullNETr_prctile_95    =   prctile( max(abs(nullNETr_prctile_95_agg)), 95);
    s_agg(1).nullSMr_prctile_95     =   prctile( max(abs(nullSMr_prctile_95_agg)),  95);
    s_agg(1).r                      =   r_agg;


    % Now save
    save(sprintf('%s/data/%d/permutation_data.mat', abcd_cca_dir, n_subs), 's_agg');

end