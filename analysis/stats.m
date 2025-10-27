clear all; close all; clc

TMSmat = '/run/user/1000/gvfs/smb-share:server=chenshare.srv.uhnresearch.ca,share=chenshare/Ozzy_Taskin/Experiments/TUSLobuleExperiment_And_CBIDiffusion/Data/subject_results_grandBaseline.xlsx';
BIDSfolder = '/home/chenlab-linux/Desktop/Ozzy/bidsFolder';

% Load TMS data
TMSdata = readtable(TMSmat);
subjectList = TMSdata.subject;
colNames = TMSdata.Properties.VariableNames;
TMSdata(:,[1,5,6,7]) = [];

% Loop through each subject and load their connectivity matrices
labels = {'ad','fa','md','ficvf','fiso','odi','rd','weight'};
maps = {};
for ii = 1:length(subjectList)
    maps{ii,1} = triu(table2array(readtable(fullfile(BIDSfolder, ['sub-' subjectList{ii}],'ses-01',['sub-' subjectList{ii} '.diffusionResults'],'connectivity',['sub-' subjectList{ii} '_ad_connectome.csv']))));
    maps{ii,2} = triu(table2array(readtable(fullfile(BIDSfolder, ['sub-' subjectList{ii}],'ses-01',['sub-' subjectList{ii} '.diffusionResults'],'connectivity',['sub-' subjectList{ii} '_fa_connectome.csv']))));
    maps{ii,3} = triu(table2array(readtable(fullfile(BIDSfolder, ['sub-' subjectList{ii}],'ses-01',['sub-' subjectList{ii} '.diffusionResults'],'connectivity',['sub-' subjectList{ii} '_md_connectome.csv']))));
    maps{ii,4} = triu(table2array(readtable(fullfile(BIDSfolder, ['sub-' subjectList{ii}],'ses-01',['sub-' subjectList{ii} '.diffusionResults'],'connectivity',['sub-' subjectList{ii} '_noddi_ficvf_connectome.csv']))));
    maps{ii,5} = triu(table2array(readtable(fullfile(BIDSfolder, ['sub-' subjectList{ii}],'ses-01',['sub-' subjectList{ii} '.diffusionResults'],'connectivity',['sub-' subjectList{ii} '_noddi_fiso_connectome.csv']))));
    maps{ii,6} = triu(table2array(readtable(fullfile(BIDSfolder, ['sub-' subjectList{ii}],'ses-01',['sub-' subjectList{ii} '.diffusionResults'],'connectivity',['sub-' subjectList{ii} '_noddi_odi_connectome.csv']))));
    maps{ii,7} = triu(table2array(readtable(fullfile(BIDSfolder, ['sub-' subjectList{ii}],'ses-01',['sub-' subjectList{ii} '.diffusionResults'],'connectivity',['sub-' subjectList{ii} '_rd_connectome.csv']))));
    maps{ii,8} = triu(table2array(readtable(fullfile(BIDSfolder, ['sub-' subjectList{ii}],'ses-01',['sub-' subjectList{ii} '.diffusionResults'],'connectivity',['sub-' subjectList{ii} '_weight_connectome.csv']))));
end

% Remove subject 6
TMSdata(6,:) = [];
maps(6,:) = [];

% Define the node pairs of interest
edgesOfInterest = [23 38; 38 96; 96 99; 96 100];
nEdges = size(edgesOfInterest,1);
nSubjects = size(maps,1);
nMetrics  = size(maps,2);
X_reduced = zeros(nSubjects, nEdges * nMetrics);
for s = 1:nSubjects
    featVec = [];
    for m = 1:nMetrics
        mat = maps{s,m};
        temp = zeros(nEdges,1);
        for e = 1:nEdges
            i = edgesOfInterest(e,1);
            j = edgesOfInterest(e,2);
            temp(e) = mat(i,j);  % extract upper-triangle value
        end
        featVec = [featVec; temp];  % concatenate metrics
    end
    X_reduced(s,:) = featVec';  % store as row
end

% Convert TMS table to array
TMSarray = table2array(TMSdata);
TMScolNames = TMSdata.Properties.VariableNames;

% Z-score X
X_z = zscore(X_reduced);
% Z-score each TMS column separately
Y_z = nan(size(TMSarray));
for i = 1:size(TMSarray,2)
    nanIdx = isnan(TMSarray(:,i));
    Y_clean = TMSarray(~nanIdx,i);
    Y_z(~nanIdx,i) = (Y_clean - mean(Y_clean)) / std(Y_clean);
end

% --- PCA on connectivity features ---
[coeff, score, latent, ~, explained] = pca(X_z);

% Determine how many PCs to reach 70% cumulative variance
cumVar = cumsum(explained);
nPCs = find(cumVar >= 70, 1, 'first');
fprintf('Using first %d PCs to explain %.1f%% of variance.\n', nPCs, cumVar(nPCs));

%% --- Correlate selected PCs with TMS measures ---
nTMS = size(Y_z,2);
PCcorrs = nan(nTMS, nPCs);
PCpvals = nan(nTMS, nPCs);

nPerm = 1000; % number of permutations for p-value

for t = 1:nTMS
    Yvec = Y_z(:,t);
    nanIdx = isnan(Yvec);
    Yvec_clean = Yvec(~nanIdx);
    
    for p = 1:nPCs
        PC_scores_clean = score(~nanIdx, p);
        
        % Observed correlation
        r = corr(PC_scores_clean, Yvec_clean);
        PCcorrs(t,p) = r;
        
        % Permutation test
        r_perm = zeros(nPerm,1);
        for permIdx = 1:nPerm
            Y_perm = Yvec_clean(randperm(length(Yvec_clean)));
            r_perm(permIdx) = corr(PC_scores_clean, Y_perm);
        end
        PCpvals(t,p) = mean(abs(r_perm) >= abs(r));
        
        fprintf('TMS: %s | PC%d corr = %.3f | p = %.3f\n', TMScolNames{t}, p, r, PCpvals(t,p));
    end
end

%--- Optional: visualize loadings for first PC ---
figure;
bar(coeff(:,1));
xlabel('Connectivity features (edges × metrics)');
ylabel('PC1 loading');
title('PC1 Loadings for Connectivity Features');

nEdges = 4;  % number of edges
nMetrics = 8; % number of metrics
PCnum = 2;   % which PC you are inspecting

% Reshape loadings to edges × metrics
W = reshape(coeff(:,PCnum), [nEdges, nMetrics]);

% Sum or average absolute values across edges to see metric contributions
metric_contrib = mean(abs(W),1);

% Display
for m = 1:nMetrics
    fprintf('%s contribution to PC%d: %.3f\n', labels{m}, PCnum, metric_contrib(m));
end

figure;
bar(metric_contrib);
xticks(1:nMetrics); xticklabels(labels);
ylabel('Mean absolute loading');
title(sprintf('Contribution of metrics to PC%d', PCnum));


% % Number of PLS components
% nComponents = 2;
% 
% % Number of permutations
% nPerm = 700;
% 
% % Preallocate storage
% nTMS = size(Y_z,2);
% corrs = nan(nTMS,1);       % observed correlation
% pvals = nan(nTMS,1);       % permutation p-value
% weights = cell(nTMS,1);    % feature weights for first component
% 
% for i = 1:nTMS
%     % Extract TMS variable
%     Y = Y_z(:,i);
% 
%     % Skip if all NaNs
%     if all(isnan(Y))
%         fprintf('TMS variable %s contains only NaNs, skipping\n', TMScolNames{i});
%         continue
%     end
% 
%     % Remove subjects with NaN for this measure
%     nanIdx = isnan(Y);
%     X_clean = X_z(~nanIdx,:);
%     Y_clean = Y(~nanIdx);
%     nSubj_clean = sum(~nanIdx);
% 
%     % --- Run PLS for observed data ---
%     [XL, YL, XS, YS, beta, PCTVAR] = plsregress(X_clean, Y_clean, nComponents);
%     r_obs = corr(XS(:,1), YS(:,1));
%     corrs(i) = r_obs;
%     weights{i} = XL(:,1);
% 
%     % --- Permutation test ---
%     r_perm = zeros(nPerm,1);
%     for p = 1:nPerm
%         Y_perm = Y_clean(randperm(nSubj_clean));  % shuffle TMS labels
%         [~, ~, XS_p, YS_p] = plsregress(X_clean, Y_perm, nComponents);
%         r_perm(p) = corr(XS_p(:,1), YS_p(:,1));
%     end
% 
%     % p-value: proportion of permuted correlations >= observed
%     pvals(i) = mean(abs(r_perm) >= abs(r_obs));
% 
%     fprintf('TMS variable: %s | Corr(LV1) = %.3f | p = %.3f\n', TMScolNames{i}, r_obs, pvals(i));
% end
% 
% % Optional: visualize weights as before
% for i = 1:nTMS
%     if isempty(weights{i})
%         continue
%     end
%     W = reshape(weights{i}, [nEdges, nMetrics]);
%     figure;
%     imagesc(W);
%     colorbar;
%     xticks(1:nMetrics); xticklabels(labels);
%     yticks(1:nEdges); yticklabels({'motor-thalamus','thalamus-dentate','dentate-lobule5','dentate-lobule8'});
%     title(['PLS Weights for TMS: ' TMScolNames{i}]);
% end
