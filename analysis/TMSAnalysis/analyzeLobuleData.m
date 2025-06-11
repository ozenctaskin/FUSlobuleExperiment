close all; clear all; clc

% Decide if we are saving diagnostic images. Takes a while to run when set
% to true
setDiagnostics = false; 
baselineCorrect = true;
useClean = true;

% Specify subject paths. Order needs to be baseline, DN, L5, L8, V1, 0w,
% 30wFlip
% dataFolder = '/Volumes/chenshare/Ozzy_Taskin/Experiments/pilot/lobuleExperiment/data/';
% data.HERO01 = {fullfile(dataFolder, 'HERO_01', 'clean_Baseline_160125_000.mat'), ...
%                fullfile(dataFolder, 'HERO_01', 'clean_DN_160125_000.mat'), ...
%                fullfile(dataFolder, 'HERO_01', 'clean_L5_160125_000.mat'), ...
%                fullfile(dataFolder, 'HERO_01', 'clean_L8_160125_000.mat'), ...
%                fullfile(dataFolder, 'HERO_01', 'clean_V1_160125_000.mat'), ...
%                fullfile(dataFolder, 'HERO_01', 'clean_DN_0wsham_160125_000.mat'), ...
%                fullfile(dataFolder, 'HERO_01', 'clean_DN_30wflip_160125_000.mat')};
% 
% data.HERO02 = {fullfile(dataFolder, 'HERO_02', 'clean_X_161224_000.mat'), ...
%                fullfile(dataFolder, 'HERO_02', 'clean_Dentate_161224_000.mat'), ...
%                fullfile(dataFolder, 'HERO_02', 'clean_Lobule5_161224_000.mat'), ...
%                fullfile(dataFolder, 'HERO_02', 'clean_Lobule8_161224_000.mat'), ...
%                fullfile(dataFolder, 'HERO_02', 'clean_V1_161224_000.mat'), ...
%                fullfile(dataFolder, 'HERO_02', 'clean_DentateSham0w_161224_000.mat'), ...
%                fullfile(dataFolder, 'HERO_02', 'clean_DentateSham302_161224_000.mat')};
% 
% data.HERO03 = {fullfile(dataFolder, 'HERO_03', 'clean_Baseline_030125_000.mat'), ...
%                fullfile(dataFolder, 'HERO_03', 'clean_DN_030125_000.mat'), ...
%                fullfile(dataFolder, 'HERO_03', 'clean_L5_030125_000.mat'), ...
%                fullfile(dataFolder, 'HERO_03', 'clean_L8_take2_030125_000.mat'), ...
%                fullfile(dataFolder, 'HERO_03', 'clean_V1_030125_000.mat'), ...
%                fullfile(dataFolder, 'HERO_03', 'clean_DN_0w_030125_000.mat'), ...
%                fullfile(dataFolder, 'HERO_03', 'clean_Dn_30wflip_030125_000.mat')}; 
% 
% data.HERO04 = {fullfile(dataFolder, 'HERO_04', 'clean_Baseline_220125_000.mat'), ...
%                fullfile(dataFolder, 'HERO_04', 'clean_DN2_220125_000.mat'), ...
%                fullfile(dataFolder, 'HERO_04', 'clean_L5_220125_000.mat'), ...
%                fullfile(dataFolder, 'HERO_04', 'clean_L8_220125_000.mat'), ...
%                fullfile(dataFolder, 'HERO_04', 'clean_V1_220125_000.mat'), ...
%                fullfile(dataFolder, 'HERO_04', 'clean_DN0w_220125_000.mat'), ...
%                fullfile(dataFolder, 'HERO_04', 'clean_DN_flip30w_220125_000.mat')}; 
% 
% data.HERO05 = {fullfile(dataFolder, 'HERO_05', 'clean_baseline_280225_000.mat'), ...
%                fullfile(dataFolder, 'HERO_05', 'clean_DN_280225_000.mat'), ...
%                fullfile(dataFolder, 'HERO_05', 'clean_L5_280225_000.mat'), ...
%                fullfile(dataFolder, 'HERO_05', 'clean_L8_280225_000.mat'), ...
%                fullfile(dataFolder, 'HERO_05', 'clean_V1_280225_000.mat'), ...
%                fullfile(dataFolder, 'HERO_05', 'clean_sham0w_280225_000.mat'), ...
%                fullfile(dataFolder, 'HERO_05', 'clean_shamFlip_280225_000.mat')}; 

dataFolder = '/Volumes/chenshare/Ozzy_Taskin/Experiments/TUSLobuleExperiment_And_CBIDiffusion/Data';
data.L001 =   {fullfile(dataFolder, 'L001_ses2', 'EMG', 'baseline_300525_000.mat'), ...
               fullfile(dataFolder, 'L001_ses2', 'EMG', 'DN_300525_000.mat'), ...
               fullfile(dataFolder, 'L001_ses2', 'EMG', 'L5_300525_000.mat'), ...
               fullfile(dataFolder, 'L001_ses2', 'EMG', 'L8_300525_000.mat'), ...
               fullfile(dataFolder, 'L001_ses2', 'EMG', 'V1_300525_000.mat'), ...
               fullfile(dataFolder, 'L001_ses2', 'EMG', 'V0W_300525_000.mat'), ...
               fullfile(dataFolder, 'L001_ses2', 'EMG', 'Flip_300525_000.mat'), ...
               fullfile(dataFolder, 'L001_ses2', 'EMG', 'CBI45_3005_1718_000.mat'), ...
               fullfile(dataFolder, 'L001_ses2', 'EMG', 'CBI55_3005_1737_000.mat'), ...
               fullfile(dataFolder, 'L001_ses2', 'EMG', 'CBI60_3005_1731_000.mat')}; 

% Get fieldnames and empty cell for all subject peaks so we can do some
% averaging at the end. Also specify order of the data entry
subjectIDs = fieldnames(data);
averagePeaks = {};
labels = {'baseline','dentate','lobule 5','lobule 8','sham V1','sham 0w','sham 30w','CBI-1base','CBI-1','CBI-2base','CBI-2','CBI-3base','CBI-3'};
labels = {'baseline','dentate','lobule 5','lobule 8','sham V1','sham 0w','sham 30w','baseline1','45-MSO','baseline2','55-MSO','baseline3','60-MSO'};
colors = {'r', 'g', 'b', 'c', 'm', 'y', 'k', [0.8500, 0.3250, 0.0980], [0.8500, 0.3250, 0.0980], [0.4940, 0.1840, 0.5560], [0.4940, 0.1840, 0.5560], [0.3010, 0.7450, 0.9330], [0.3010, 0.7450, 0.9330]};
% Loop through sujects
for sub = 1:length(subjectIDs)
    % Get the path of the subject from the first input and create a folder
    % for diagnostic images if asked 
    if setDiagnostics
        dataPath = fileparts(data.(subjectIDs{sub}){1});
        if ~isfolder(fullfile(dataPath, 'diagnostics'))
            mkdir(fullfile(dataPath, 'diagnostics'))
        end
    end
    % Load data into cells
    dataLoaded = cellfun(@(p) load_wave_data(p, useClean), data.(subjectIDs{sub}), 'UniformOutput', false);
    % Get an empty cell for subject peaks
    subjectPeaks = {};
    % Loop through trials, load, and get peak to peak
    peakIndex = 0;
    for ii = 1:length(dataLoaded)
        dataset = dataLoaded{ii};
        if ii < 8
            peaks = peak2peak(reshape(dataset.values(2800:3100,1,:), [], size(dataset.values,3)));
            testPeaks = [];
            condPeaks = peaks;
        else
            peaks = peak2peak(reshape(dataset.values(1025:end,1,:), [], size(dataset.values,3)));
            testPeaks = peaks(find([dataset.frameinfo.state] == 1));
            condPeaks = peaks(find([dataset.frameinfo.state] == 2));
        end
        
        % Here we do diagnostic plotting if asked
        if setDiagnostics
            f = figure('visible','off');
            sgtitle([subjectIDs{sub} ' ' labels{ii}])
            for plt = 1:size(dataset.values, 3)
                subplot(4,5,plt)
                plot(dataset.values(2762:3100,1,plt))
            end
            saveas(f,fullfile(dataPath, 'diagnostics', [subjectIDs{sub} '_' labels{ii}]),'jpg')
        end
        % Check if the vector has less than 20 elements, if so add NaNs to
        % make it 20
        if length(condPeaks) < 20
            needNaNs = 20 - length(condPeaks);
            condPeaks(length(condPeaks)+1:20) = NaN;
        end
        if ~isempty(testPeaks)
            if length(testPeaks) < 20
                needNaNs = 20 - length(testPeaks);
                testPeaks(length(testPeaks)+1:20) = NaN;
            end
        end

        % Append to subjectPeaks
        if ii < 8
            peakIndex = peakIndex + 1;
            subjectPeaks{peakIndex} = condPeaks';
        else
            peakIndex = peakIndex + 1;
            subjectPeaks{peakIndex} = testPeaks';
            peakIndex = peakIndex + 1;
            subjectPeaks{peakIndex} = condPeaks';
        end
    end
    % Convert cell to matrix 
    subjectPeaks = cell2mat(subjectPeaks);
    % Do a box plot for the values 
    figure
    boxplot(subjectPeaks, labels(1:size(subjectPeaks, 2)), 'Symbol', '')
    ylim([0 6])
    title(subjectIDs{sub})
    hold on
    % Add scatter points next to each boxplot
    x = repmat(1:size(subjectPeaks, 2), size(subjectPeaks, 1), 1); % X-coordinates
    x = x + 0.1 * (rand(size(x)) - 0.5); % Add a small random jitter to spread points
    % x = x - 0.4;
    for sct = 1:size(x,2)
        scatter(x(:,sct), subjectPeaks(:,sct), 'filled', 'MarkerFaceAlpha', 0.6, 'MarkerFaceColor', colors{sct})
    end
    hold off 

    averagePeaks{sub} = nanmean(subjectPeaks);
end

% Plot the subject average box plot
averagePeaks = cat(1, averagePeaks{:});

% Calculate ratio of paired vs. baseline
ratios = averagePeaks ./ averagePeaks(:,1);
averageRatios = mean(ratios);
stdRatios = std(ratios);

% % Define specific colors for each subject
% colors = [1 0 0; 0 1 0; 1 0.4 0.8; 1 0.5 0; 0.2 0.4 0]; 

numSubjects = 5; 

% Baseline correct if asked
if baselineCorrect
    averagePeaks = averagePeaks./averagePeaks(:,1);
    averagePeaks(:,1) = [];
    labels = labels(2:end);
end

% Do a boxplot
figure
boxplot(averagePeaks, labels, 'Symbol', '')
hold on
h = findobj(gca, 'Tag', 'Box'); 
for j = 1:length(h)
    patch(get(h(j), 'XData'), get(h(j), 'YData'), [0.3010 0.7450 0.9330], 'FaceAlpha', 0.5); % Fill boxes with color
end

% Scatter plot with unique colors for each subject
for ii = 1:size(averagePeaks,2) 
    for jj = 1:numSubjects 
        % scatter(ii, averagePeaks(jj,ii), 50, colors(jj,:), 'filled'); 
        scatter(ii, averagePeaks(jj,ii), 50, 'k', 'filled'); 
    end
end

% Set limits
if baselineCorrect
    ylim([0 6]);
    xlim([0 7]);
    ylabel('Baseline corrected MEP')
    yline(1, 'r--', 'LineWidth', 1.5);
else
    ylim([0 3]);
    xlim([0 8]);
    ylabel('MEP amplitude (mV)')
end

xticklabels(labels);
set(gca, 'FontSize', 25) 
ax = gca;
ax.Box = 'off';
title('Subject results - Averaged Peaks');

% Function to load data in without sub variable names
function data = load_wave_data(filename, useClean)
    vars = whos('-file', filename);
    if useClean
        idx = find(contains({vars.name}, 'data'), 1);
    else
        idx = find(contains({vars.name}, '_wave_data'), 1);
    end
    if isempty(idx)
        error(['No variable with "_wave_data" in file: ' filename]);
    end
    varname = vars(idx).name;
    tmp = load(filename, varname);
    data = tmp.(varname);
end