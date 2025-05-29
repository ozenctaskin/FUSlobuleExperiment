close all; clear all; clc

% Decide if we are saving diagnostic images. Takes a while to run when set
% to true
setDiagnostics = false; 
cleaned = true;
baselineCorrect = true;

% Specify subject paths. Order needs to be baseline, DN, L5, L8, V1, DN_0w,
% DN_30w
data.HERO01 = {'/Volumes/chenshare/Ozzy_Taskin/Experiments/pilot/lobuleExperiment/data/HERO_01/clean_Baseline_160125_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/Experiments/pilot/lobuleExperiment/data/HERO_01/clean_DN_160125_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/Experiments/pilot/lobuleExperiment/data/HERO_01/clean_L5_160125_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/Experiments/pilot/lobuleExperiment/data/HERO_01/clean_L8_160125_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/Experiments/pilot/lobuleExperiment/data/HERO_01/clean_V1_160125_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/Experiments/pilot/lobuleExperiment/data/HERO_01/clean_DN_0wsham_160125_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/Experiments/pilot/lobuleExperiment/data/HERO_01/clean_DN_30wflip_160125_000.mat'};

data.HERO02 = {'/Volumes/chenshare/Ozzy_Taskin/Experiments/pilot/lobuleExperiment/data/HERO_02/clean_X_161224_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/Experiments/pilot/lobuleExperiment/data/HERO_02/clean_Dentate_161224_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/Experiments/pilot/lobuleExperiment/data/HERO_02/clean_Lobule5_161224_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/Experiments/pilot/lobuleExperiment/data/HERO_02/clean_Lobule8_161224_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/Experiments/pilot/lobuleExperiment/data/HERO_02/clean_V1_161224_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/Experiments/pilot/lobuleExperiment/data/HERO_02/clean_DentateSham0w_161224_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/Experiments/pilot/lobuleExperiment/data/HERO_02/clean_DentateSham302_161224_000.mat'};

data.HERO03 = {'/Volumes/chenshare/Ozzy_Taskin/Experiments/pilot/lobuleExperiment/data/HERO_03/clean_Baseline_030125_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/Experiments/pilot/lobuleExperiment/data/HERO_03/clean_DN_030125_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/Experiments/pilot/lobuleExperiment/data/HERO_03/clean_L5_030125_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/Experiments/pilot/lobuleExperiment/data/HERO_03/clean_L8_take2_030125_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/Experiments/pilot/lobuleExperiment/data/HERO_03/clean_V1_030125_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/Experiments/pilot/lobuleExperiment/data/HERO_03/clean_DN_0w_030125_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/Experiments/pilot/lobuleExperiment/data/HERO_03/clean_Dn_30wflip_030125_000.mat'}; 

data.HERO04 = {'/Volumes/chenshare/Ozzy_Taskin/Experiments/pilot/lobuleExperiment/data/HERO_04/clean_Baseline_220125_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/Experiments/pilot/lobuleExperiment/data/HERO_04/clean_DN2_220125_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/Experiments/pilot/lobuleExperiment/data/HERO_04/clean_L5_220125_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/Experiments/pilot/lobuleExperiment/data/HERO_04/clean_L8_220125_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/Experiments/pilot/lobuleExperiment/data/HERO_04/clean_V1_220125_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/Experiments/pilot/lobuleExperiment/data/HERO_04/clean_DN0w_220125_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/Experiments/pilot/lobuleExperiment/data/HERO_04/clean_DN_flip30w_220125_000.mat'}; 

data.HERO05 = {'/Volumes/chenshare/Ozzy_Taskin/Experiments/pilot/lobuleExperiment/data/HERO_05/clean_baseline_280225_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/Experiments/pilot/lobuleExperiment/data/HERO_05/clean_DN_280225_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/Experiments/pilot/lobuleExperiment/data/HERO_05/clean_L5_280225_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/Experiments/pilot/lobuleExperiment/data/HERO_05/clean_L8_280225_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/Experiments/pilot/lobuleExperiment/data/HERO_05/clean_V1_280225_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/Experiments/pilot/lobuleExperiment/data/HERO_05/clean_sham0w_280225_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/Experiments/pilot/lobuleExperiment/data/HERO_05/clean_shamFlip_280225_000.mat'}; 

% Get fieldnames and empty cell for all subject peaks so we can do some
% averaging at the end. Also specify order of the data entry
subjectIDs = fieldnames(data);
averagePeaks = {};
labels = {'baseline','dentate','lobule 5','lobule 8','sham V1','sham 0w','sham 30w'};
colors = {'r', 'b', [0.4660 0.6740 0.1880], 'm', 'k', [0.8500 0.3250 0.0980], [0.4940 0.1840 0.5560]};
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
    dataLoaded = cellfun(@(p) getfield(load(p, 'data'), 'data'), data.(subjectIDs{sub}), 'UniformOutput', false);
    % Get an empty cell for subject peaks
    subjectPeaks = {};
    % Loop through trials, load, and get peak to peak
    for ii = 1:length(dataLoaded)
        dataset = dataLoaded{ii};
        peaks = peak2peak(reshape(dataset.values(2762:3100,1,:), [], size(dataset.values,3)));
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
        if length(peaks) < 20
            needNaNs = 20 - length(peaks);
            peaks(length(peaks)+1:20) = NaN;
        end
        subjectPeaks{ii} = peaks';
    end
    % Convert cell to matrix 
    subjectPeaks = cell2mat(subjectPeaks);
    % Do a box plot for the values 
    figure
    boxplot(subjectPeaks, labels, 'Symbol', '')
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
