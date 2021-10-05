% make sure cca_interactive has been run
% ABCD ICA-FIX 

load('pos-neg-lookup.mat');

% post hoc columns not included in CCA
bmi_col         = find(strcmpi(VARS_0(1,:),'anthro_bmi_calc'));
educ_col         = find(strcmpi(VARS_0(1,:),'high.educ'));
age_col         = find(strcmpi(VARS_0(1,:),'age'));
income_col         = find(strcmpi(VARS_0(1,:),'household.income.bl'));

% SM indices
pneg_idx = [ica_sms_idx' bmi_col educ_col age_col income_col];
% include / exclude vector
inc_exc = [ones(1,length(ica_sms_idx)) zeros(1,4)];
% SM names
pneg_names = VARS_0(1,pneg_idx);
% SM measures
pneg_vars = [VARS(:,ica_sms_idx) VARS(:,bmi_col) VARS(:,educ_col) VARS(:,age_col) VARS(:,income_col)];

%% Figure 4 (Mode 2 cut off at +- r=.2)

% specify CCA mode
I = 2;
CorCCA = corr(V(:,I), palm_inormal(pneg_vars), 'rows','pairwise');

% Z scores
ZCCA          = 12*0.5*log((1+CorCCA)./(1-CorCCA));    % r2z  -  factor x12 gets close to "real" zstats.
[tmp_B,tmp_I] = sort(CorCCA,'ascend'); % sort by corralation value

VarExplained = []; %variance explained only all SMs
cors = []; % correlations
varexpl = []; % variance explained only relevant SMs
smname = {}; % SM name
incexc = []; % was it included in the CCA?

% Iterate over the SMs
for i = 1:length(tmp_I)
    ii = tmp_I(i);
    Y                 = pneg_vars(:,ii);
    Y_no_nan_idx      = ~isnan(Y);
    Y                 = nets_demean(Y(Y_no_nan_idx));
    X                 = nets_demean(V(Y_no_nan_idx,I));
    VarExplained(ii)  = var(X*(pinv(X)*Y)) / var(Y);
    if abs(tmp_B(i))>0.2
        BVname = string(pneg_lut(ii,2));
        cors = [CorCCA(ii) cors];
        varexpl = [VarExplained(ii) varexpl];
        smname = [BVname smname];
        incexc = [categorical(inc_exc(ii)) incexc];
    end
end

t = table(cors', varexpl', smname', incexc','VariableNames',{'correlation','variance','name','include'});
save('./ABCD_ICA-FIX_Pneg_Mode2_thresh.mat', 't')

%% Mode 2 no thresh
% specify CCA mode
I = 2;
CorCCA = corr(V(:,I), palm_inormal(pneg_vars), 'rows','pairwise');

% Z scores
ZCCA          = 12*0.5*log((1+CorCCA)./(1-CorCCA));    % r2z  -  factor x12 gets close to "real" zstats.
[tmp_B,tmp_I] = sort(CorCCA,'ascend'); % sort by corralation value

VarExplained = []; %variance explained only all SMs
cors = []; % correlations
varexpl = []; % variance explained
smname = {}; % SM name
incexc = []; % was it included in the CCA?

% Iterate over the SMs
for i = 1:length(tmp_I)
    ii = tmp_I(i);
    Y                 = pneg_vars(:,ii);
    Y_no_nan_idx      = ~isnan(Y);
    Y                 = nets_demean(Y(Y_no_nan_idx));
    X                 = nets_demean(V(Y_no_nan_idx,I));
    VarExplained(ii)  = var(X*(pinv(X)*Y)) / var(Y);
    BVname = string(pneg_lut(ii,2));
    cors = [CorCCA(ii) cors];
    varexpl = [VarExplained(ii) varexpl];
    smname = [BVname smname];
    incexc = [categorical(inc_exc(ii)) incexc];
end

t = table(cors', varexpl', smname', incexc','VariableNames',{'correlation','variance','name','include'});
save('./ABCD_ICA-FIX_Pneg_Mode2_nothresh.mat', 't')

%% Mode 1 thresh
% specify CCA mode
I = 1;
% run the correlations, the sign is arbitrary, so lets flip it to be
% consistent with Smith
CorCCA = -1*corr(V(:,I), palm_inormal(pneg_vars), 'rows','pairwise');

% Z scores
ZCCA          = 12*0.5*log((1+CorCCA)./(1-CorCCA));    % r2z  -  factor x12 gets close to "real" zstats.
[tmp_B,tmp_I] = sort(CorCCA,'ascend'); % sort by corralation value

VarExplained = []; %variance explained only all SMs
cors = []; % correlations
varexpl = []; % variance explained only relevant SMs
smname = {}; % SM name
incexc = []; % was it included in the CCA?

% Iterate over the SMs
for i = 1:length(tmp_I)
    ii = tmp_I(i);
    Y                 = pneg_vars(:,ii);
    Y_no_nan_idx      = ~isnan(Y);
    Y                 = nets_demean(Y(Y_no_nan_idx));
    X                 = nets_demean(V(Y_no_nan_idx,I));
    VarExplained(ii)  = var(X*(pinv(X)*Y)) / var(Y);
    if abs(tmp_B(i))>0.2
        BVname = string(pneg_lut(ii,2));
        cors = [CorCCA(ii) cors];
        varexpl = [VarExplained(ii) varexpl];
        smname = [BVname smname];
        incexc = [categorical(inc_exc(ii)) incexc];
    end
end

t = table(cors', varexpl', smname', incexc','VariableNames',{'correlation','variance','name','include'});
save('./ABCD_ICA-FIX_Pneg_Mode1_thresh.mat', 't')

%% Mode 1 no thresh

% specify CCA mode
I = 1;
CorCCA = corr(V(:,I), palm_inormal(pneg_vars), 'rows','pairwise');

% Z scores
ZCCA          = 12*0.5*log((1+CorCCA)./(1-CorCCA));    % r2z  -  factor x12 gets close to "real" zstats.
[tmp_B,tmp_I] = sort(CorCCA,'ascend'); % sort by corralation value

VarExplained = []; %variance explained only all SMs
cors = []; % correlations
varexpl = []; % variance explained
smname = {}; % SM name
incexc = []; % was it included in the CCA?

% Iterate over the SMs
for i = 1:length(tmp_I)
    ii = tmp_I(i);
    Y                 = pneg_vars(:,ii);
    Y_no_nan_idx      = ~isnan(Y);
    Y                 = nets_demean(Y(Y_no_nan_idx));
    X                 = nets_demean(V(Y_no_nan_idx,I));
    VarExplained(ii)  = var(X*(pinv(X)*Y)) / var(Y);
    BVname = string(pneg_lut(ii,2));
    cors = [CorCCA(ii) cors];
    varexpl = [VarExplained(ii) varexpl];
    smname = [BVname smname];
    incexc = [categorical(inc_exc(ii)) incexc];
end

t = table(cors', varexpl', smname', incexc','VariableNames',{'correlation','variance','name','include'});
save('./ABCD_ICA-FIX_Pneg_Mode1_nothresh.mat', 't')

%% Mode 3 thresh
% specify CCA mode
I = 3;
CorCCA = corr(V(:,I), palm_inormal(pneg_vars), 'rows','pairwise');

% Z scores
ZCCA          = 12*0.5*log((1+CorCCA)./(1-CorCCA));    % r2z  -  factor x12 gets close to "real" zstats.
[tmp_B,tmp_I] = sort(CorCCA,'ascend'); % sort by corralation value

VarExplained = []; %variance explained only all SMs
cors = []; % correlations
varexpl = []; % variance explained only relevant SMs
smname = {}; % SM name
incexc = []; % was it included in the CCA?

% Iterate over the SMs
for i = 1:length(tmp_I)
    ii = tmp_I(i);
    Y                 = pneg_vars(:,ii);
    Y_no_nan_idx      = ~isnan(Y);
    Y                 = nets_demean(Y(Y_no_nan_idx));
    X                 = nets_demean(V(Y_no_nan_idx,I));
    VarExplained(ii)  = var(X*(pinv(X)*Y)) / var(Y);
    if abs(tmp_B(i))>0.2
        BVname = string(pneg_lut(ii,2));
        cors = [CorCCA(ii) cors];
        varexpl = [VarExplained(ii) varexpl];
        smname = [BVname smname];
        incexc = [categorical(inc_exc(ii)) incexc];
    end
end

t = table(cors', varexpl', smname', incexc','VariableNames',{'correlation','variance','name','include'});
save('./ABCD_ICA-FIX_Pneg_Mode3_thresh.mat', 't')

%% Mode 3 no thresh

% specify CCA mode
I = 3;
CorCCA = corr(V(:,I), palm_inormal(pneg_vars), 'rows','pairwise');

% Z scores
ZCCA          = 12*0.5*log((1+CorCCA)./(1-CorCCA));    % r2z  -  factor x12 gets close to "real" zstats.
[tmp_B,tmp_I] = sort(CorCCA,'ascend'); % sort by corralation value

VarExplained = []; %variance explained only all SMs
cors = []; % correlations
varexpl = []; % variance explained
smname = {}; % SM name
incexc = []; % was it included in the CCA?

% Iterate over the SMs
for i = 1:length(tmp_I)
    ii = tmp_I(i);
    Y                 = pneg_vars(:,ii);
    Y_no_nan_idx      = ~isnan(Y);
    Y                 = nets_demean(Y(Y_no_nan_idx));
    X                 = nets_demean(V(Y_no_nan_idx,I));
    VarExplained(ii)  = var(X*(pinv(X)*Y)) / var(Y);
    BVname = string(pneg_lut(ii,2));
    cors = [CorCCA(ii) cors];
    varexpl = [VarExplained(ii) varexpl];
    smname = [BVname smname];
    incexc = [categorical(inc_exc(ii)) incexc];
end

t = table(cors', varexpl', smname', incexc','VariableNames',{'correlation','variance','name','include'});
save('./ABCD_ICA-FIX_Pneg_Mode3_nothresh.mat', 't')

%% Mode 4 thresh
% specify CCA mode
I = 4;
CorCCA = corr(V(:,I), palm_inormal(pneg_vars), 'rows','pairwise');

% Z scores
ZCCA          = 12*0.5*log((1+CorCCA)./(1-CorCCA));    % r2z  -  factor x12 gets close to "real" zstats.
[tmp_B,tmp_I] = sort(CorCCA,'ascend'); % sort by corralation value

VarExplained = []; %variance explained only all SMs
cors = []; % correlations
varexpl = []; % variance explained only relevant SMs
smname = {}; % SM name
incexc = []; % was it included in the CCA?

% Iterate over the SMs
for i = 1:length(tmp_I)
    ii = tmp_I(i);
    Y                 = pneg_vars(:,ii);
    Y_no_nan_idx      = ~isnan(Y);
    Y                 = nets_demean(Y(Y_no_nan_idx));
    X                 = nets_demean(V(Y_no_nan_idx,I));
    VarExplained(ii)  = var(X*(pinv(X)*Y)) / var(Y);
    if abs(tmp_B(i))>0.2
        BVname = string(pneg_lut(ii,2));
        cors = [CorCCA(ii) cors];
        varexpl = [VarExplained(ii) varexpl];
        smname = [BVname smname];
        incexc = [categorical(inc_exc(ii)) incexc];
    end
end

t = table(cors', varexpl', smname', incexc','VariableNames',{'correlation','variance','name','include'});
save('./ABCD_ICA-FIX_Pneg_Mode4_thresh.mat', 't')
%% Mode 4 no thresh

% specify CCA mode
I = 4;
CorCCA = corr(V(:,I), palm_inormal(pneg_vars), 'rows','pairwise');

% Z scores
ZCCA          = 12*0.5*log((1+CorCCA)./(1-CorCCA));    % r2z  -  factor x12 gets close to "real" zstats.
[tmp_B,tmp_I] = sort(CorCCA,'ascend'); % sort by corralation value

VarExplained = []; %variance explained only all SMs
cors = []; % correlations
varexpl = []; % variance explained
smname = {}; % SM name
incexc = []; % was it included in the CCA?

% Iterate over the SMs
for i = 1:length(tmp_I)
    ii = tmp_I(i);
    Y                 = pneg_vars(:,ii);
    Y_no_nan_idx      = ~isnan(Y);
    Y                 = nets_demean(Y(Y_no_nan_idx));
    X                 = nets_demean(V(Y_no_nan_idx,I));
    VarExplained(ii)  = var(X*(pinv(X)*Y)) / var(Y);
    BVname = string(pneg_lut(ii,2));
    cors = [CorCCA(ii) cors];
    varexpl = [VarExplained(ii) varexpl];
    smname = [BVname smname];
    incexc = [categorical(inc_exc(ii)) incexc];
end

t = table(cors', varexpl', smname', incexc','VariableNames',{'correlation','variance','name','include'});
save('./ABCD_ICA-FIX_Pneg_Mode4_nothresh.mat', 't')