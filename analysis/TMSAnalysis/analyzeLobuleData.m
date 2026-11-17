close all; clear; clc

%% WARNING!! IF YOU DROP TRIALS IN CLEANING, MAKE SURE THE TRIAL AVERAGE ORDER IS PRESERVED

%% Organize data

% Subject path and randomization file
subjectDataPath = '/Users/ozzy/Desktop/FUSlobuleExperiment';
sumMethod = 'median'; % Or mean

% Subject names and randomization key (codes real sessions)
subjectList = {'L001','L002','L003','L004','L005','L007','L008','L009', ...
               'L010','LDC01','LDC02','LDC04','LDC05','LDC06','LDC07'}; 

baseline = {};
L5 = {};
L8 = {};
DN = {};
sham0W = {};
shamFlip = {};
CBIfixTS = {};
CBIfixCBI = {};
CBIthresholdTS = {};
CBIthresholdCBI = {};

% Loop through subjects
for i = 1:numel(subjectList)
    subjectFolder = fullfile(subjectDataPath, subjectList{i}, 'EMG');
    baseline{end+1} = processSubjectData(subjectFolder, 'baseline');
    L5{end+1} = processSubjectData(subjectFolder, 'L5');
    L8{end+1} = processSubjectData(subjectFolder, 'L8');
    DN{end+1} = processSubjectData(subjectFolder, 'DN');
    sham0W{end+1} = processSubjectData(subjectFolder, 'sham0W');
    shamFlip{end+1} = processSubjectData(subjectFolder, 'shamFlip');
    [CBIfixTS{end+1}, CBIfixCBI{end+1}] = ...
        processSubjectData(subjectFolder, 'CBIfix');
    [CBIthresholdTS{end+1}, CBIthresholdCBI{end+1}] = ...
        processSubjectData(subjectFolder, 'CBIthreshold');
end

%% Plot temporal changes (median across subjects)
conditions = {'DN', 'L8', 'L5'};

for i = 1:numel(conditions)
    data = eval(conditions{i});

    % Normalize each subject's trials to their baseline median
    data = cellfun(@(x,b) x ./ median(b, 'omitnan'), ...
        data, baseline, 'UniformOutput', false);

    maxTrials = max(cellfun(@numel, data));
    M = cell2mat(cellfun(@(x) ...
        [x(:)' nan(1, maxTrials-numel(x))], ...
        data(:), 'UniformOutput', false));

    % Median and interquartile range across subjects
    groupMedian = median(M, 1, 'omitnan');
    Q1 = prctile(M, 25, 1);
    Q3 = prctile(M, 75, 1);

    figure('Color', 'w');
    errorbar(1:maxTrials, groupMedian, ...
        groupMedian-Q1, Q3-groupMedian, ...
        '-o', 'Color', [0.12 0.35 0.65], 'LineWidth', 1.5);

    yline(1, '--', 'Color', [0.5 0.5 0.5]);

    title(conditions{i});
    xlabel('Trial number');
    ylabel('Normalized MEP amplitude (ratio)');
    grid on;

    exportgraphics(gcf, fullfile(subjectDataPath, ...
        ['Trial_Median_' conditions{i} '.png']), 'Resolution', 300);
end

%% Plot inhibition for all conditions
conditions = {DN, L8, L5, sham0W, shamFlip, ...
              CBIfixCBI, CBIthresholdCBI};

controls = {baseline, baseline, baseline, baseline, baseline, ...
            CBIfixTS, CBIthresholdTS};

labels = {'DN', 'L8', 'L5', 'Sham 0W', 'Sham Flip', ...
          'CBI Fix', 'CBI Threshold'};

normalized = nan(numel(subjectList), numel(conditions));

for c = 1:numel(conditions)
    for s = 1:numel(subjectList)

        response = median(conditions{c}{s}, 'omitnan');
        control = median(controls{c}{s}, 'omitnan');

        if isfinite(control) && control > 0
            normalized(s,c) = response / control;
        end
    end
end

figure('Color', 'w', 'Position', [200 200 1050 500]);
boxplot(normalized, 'Labels', labels, ...
    'Colors', [0.12 0.35 0.65], ...
    'Widths', 0.55, ...
    'Symbol', '');
boxes = findobj(gca, 'Tag', 'Box');
for k = 1:numel(boxes)
    patch(get(boxes(k), 'XData'), get(boxes(k), 'YData'), ...
        [0.35 0.60 0.85], 'FaceAlpha', 0.65, ...
        'EdgeColor', [0.12 0.35 0.65]);
end

% Overlay individual subjects
hold on;
for c = 1:size(normalized, 2)
    y = normalized(:,c);
    scatter(c + 0.12*(rand(size(y))-0.5), y, ...
        22, [0.10 0.25 0.45], 'filled', ...
        'MarkerFaceAlpha', 0.6);
end

yline(1, '--', '', 'Color', [0.4 0.4 0.4], ...
    'LineWidth', 1.2);
ylabel('Normalized MEP amplitude (ratio)', 'FontSize', 12);
title('Normalized MEP amplitudes', 'FontSize', 15, ...
    'FontWeight', 'bold');

set(gca, 'FontSize', 11, 'LineWidth', 1, ...
    'Box', 'off', 'TickDir', 'out');

grid on;
set(gca, 'GridAlpha', 0.12);

exportgraphics(gcf, fullfile(subjectDataPath, 'Normalized_MEP_Boxplot.png'), ...
    'Resolution', 300);

%% CBI correlations
figure('Color', 'w', 'Position', [200 200 1200 400]);

for i = 1:3
    x = normalized(:,6);  % CBI Fix
    y = normalized(:,i);  % DN, L8, L5

    valid = isfinite(x) & isfinite(y);
    [r, p] = corr(x(valid), y(valid), 'Type', 'Pearson');

    subplot(1,3,i);
    scatter(x(valid), y(valid), 55, [0.25 0.50 0.80], 'filled');
    hold on;

    if sum(valid) >= 3
        coeff = polyfit(x(valid), y(valid), 1);
        xx = linspace(min(x(valid)), max(x(valid)), 100);
        plot(xx, polyval(coeff, xx), 'Color', [0.1 0.3 0.6], ...
            'LineWidth', 1.8);
    end

    xlabel('CBI Fix (CBI / TS)');
    ylabel([labels{i} ' / Baseline']);
    title(sprintf('%s: r = %.2f, p = %.3f', labels{i}, r, p));
    grid on;
    set(gca, 'Box', 'off', 'FontSize', 11, 'TickDir', 'out');
end
sgtitle('CBI Fix vs FUS responses');
exportgraphics(gcf, fullfile(subjectDataPath, ...
    'CBIfix_FUS_Correlations.png'), 'Resolution', 300);

%% Helper function to load and process data
function [data, CBIdata] = processSubjectData(sessionFolder, target)

    % Identify CBI recordings and select MEP window
    isCBI = startsWith(target, 'CBI');
    if isCBI
        MEPframes = 1065:1250;
    else
        MEPframes = 2850:2980;
    end
    
    % Find condition files
    if strcmp(target, 'CBIfix')
        files = dir(fullfile(sessionFolder, 'clean_CBI55_*.mat'));
    elseif strcmp(target, 'CBIthreshold')
        files = dir(fullfile(sessionFolder, 'clean_CBI*_*.mat'));
    
        % Keep only numeric intensities other than 55
        isThreshold = false(1, numel(files));
        for k = 1:numel(files)
            tokens = regexp(files(k).name, ...
                '^clean_CBI(\d+)_.*\.mat$', 'tokens', 'once');
            if ~isempty(tokens)
                isThreshold(k) = str2double(tokens{1}) ~= 55;
            end
        end
        files = files(isThreshold);
    else
        files = dir(fullfile(sessionFolder, ...
            ['clean_' target '*.mat']));
    end
    
    % Handle missing files
    if isempty(files)
        if isCBI
            warning('Missing %s in %s', target, sessionFolder);
            % 12 trials per state
            data = nan(1, 12);
            CBIdata = nan(1, 12);
            return;
        else
            error('Missing %s in %s', target, sessionFolder);
        end
    elseif numel(files) > 1
        error('Multiple files found for %s in %s', ...
            target, sessionFolder);
    end
    file = fullfile(sessionFolder, files(1).name);
    
    %Load waveform data
    vars = whos('-file', file);
    idx = find(contains({vars.name}, '_wave_data'));
    
    if numel(idx) ~= 1
        error('Expected one waveform variable in %s', file);
    end
    
    fileLoaded = load(file, vars(idx).name);
    waveData = fileLoaded.(vars(idx).name);
    
    % Extract MEP traces
    if size(waveData.values, 1) < MEPframes(end)
        error('MEP window exceeds recording length in %s', file);
    end
    
    allData = reshape(waveData.values(MEPframes, 1, :), ...
        numel(MEPframes), []);
    
    % Calculate peak-to-peak amplitude for each trial
    allP2P = peak2peak(allData);
    
    %Separate CBI states and plot waveform
    if isCBI

        % Extract trial states
        states = [waveData.frameinfo.state];
        if numel(states) ~= size(allData, 2)
            error('Number of states does not match trials in %s', file);
        end
    
        % Separate waveforms by state
        TStraces = allData(:, states == 1);
        CBItraces = allData(:, states == 2);
    
        % Return peak-to-peak amplitudes
        data = allP2P(states == 1);
        CBIdata = allP2P(states == 2);
    
        % Plot all cut traces separately by state
        fig = figure('Visible', 'off');
        subplot(1, 2, 1);
        plot(MEPframes, TStraces);
        title('TS');
        xlabel('Sample');
        ylabel('EMG (mV)');
        grid on;
    
        subplot(1, 2, 2);
        plot(MEPframes, CBItraces);
        title('CBI');
        xlabel('Sample');
        ylabel('EMG (mV)');
        grid on;
    
    else
    
        % Return peak-to-peak amplitudes
        data = allP2P;
        CBIdata = [];
    
        % Plot all individual cut traces
        fig = figure('Visible', 'off');
    
        plot(MEPframes, allData);
        title(target, 'Interpreter', 'none');
        xlabel('Sample');
        ylabel('EMG (mV)');
        grid on;
    end
    
    %Save waveform plot
    saveas(fig, fullfile(sessionFolder, ...
        ['plot_' vars(idx).name '.png']));
    
    close(fig);

end