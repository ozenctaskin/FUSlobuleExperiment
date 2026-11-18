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
V1 = {};
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
    V1{end+1} = processSubjectData(subjectFolder, 'V1');
    [CBIfixTS{end+1}, CBIfixCBI{end+1}] = ...
        processSubjectData(subjectFolder, 'CBIfix');
    [CBIthresholdTS{end+1}, CBIthresholdCBI{end+1}] = ...
        processSubjectData(subjectFolder, 'CBIthreshold');
end


%% Plot inhibition for all conditions
conditions = {DN, L8, L5, sham0W, shamFlip, V1, ...
              CBIfixCBI, CBIthresholdCBI};

controls = {baseline, baseline, baseline, baseline, baseline, ...
            baseline, CBIfixTS, CBIthresholdTS};

labels = {'DN', 'L8', 'L5', 'Sham 0W', 'Sham Flip', 'Sham V1', ...
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

%% Plot temporal changes - compact 3-panel figure

conditions = {'DN', 'L8', 'L5'};

fig = figure('Color', 'w', ...
    'Units', 'pixels', ...
    'Position', [100 100 1200 350]);

t = tiledlayout(fig, 1, 3, ...
    'TileSpacing', 'compact', ...
    'Padding', 'compact');

% Store axes for consistent Y limits
ax = gobjects(1, 3);

for i = 1:3

    data = eval(conditions{i});

    % Normalize to each subject's baseline median
    data = cellfun(@(x,b) x ./ median(b, 'omitnan'), ...
        data, baseline, 'UniformOutput', false);

    maxTrials = max(cellfun(@numel, data));

    M = cell2mat(cellfun(@(x) ...
        [x(:)' nan(1, maxTrials-numel(x))], ...
        data(:), 'UniformOutput', false));

    groupMedian = median(M, 1, 'omitnan');
    Q1 = prctile(M, 25, 1);
    Q3 = prctile(M, 75, 1);

    ax(i) = nexttile(t);
    hold(ax(i), 'on');

    errorbar(1:maxTrials, groupMedian, ...
        groupMedian-Q1, Q3-groupMedian, ...
        '-o', ...
        'Color', [0.12 0.35 0.65], ...
        'MarkerFaceColor', [0.12 0.35 0.65], ...
        'LineWidth', 1.4, ...
        'MarkerSize', 4, ...
        'CapSize', 3);

    yline(1, '--', ...
        'Color', [0.5 0.5 0.5], ...
        'LineWidth', 1);

    title(conditions{i}, 'FontSize', 12, ...
        'FontWeight', 'bold');

    xlabel('Trial number');

    % Only first panel needs Y label
    if i == 1
        ylabel('Normalized MEP amplitude');
    end

    xlim([0.5 maxTrials+0.5]);

    grid on;
    set(gca, 'FontSize', 10, ...
        'Box', 'off', ...
        'TickDir', 'out', ...
        'GridAlpha', 0.12);

end

% Match Y-axis scales across all panels
linkaxes(ax, 'y');

% Compact title
title(t, 'Temporal MEP responses', ...
    'FontSize', 14, 'FontWeight', 'bold');

% Export at fixed physical dimensions
set(fig, 'PaperUnits', 'inches');
set(fig, 'PaperPosition', [0 0 12 3.5]);
set(fig, 'PaperSize', [12 3.5]);

exportgraphics(fig, fullfile(subjectDataPath, ...
    'Temporal_MEP_Combined.png'), ...
    'Resolution', 300);

%% CBI correlations
figure('Color', 'w', 'Position', [200 200 1200 400]);

for i = 1:3
    x = normalized(:,7);  % CBI Fix
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

%% Do the diffusion comparison 
connectivityPath = fullfile(subjectDataPath, 'diffusionConnectivity');

% normalized columns from the existing analysis:
% 1 = DN, 2 = L8, 3 = L5
fusLabels = {'DN', 'L8', 'L5'};

% Load CTC strength for each subject
CTCstrength = nan(numel(subjectList), 1);

for s = 1:numel(subjectList)

    subjectID = subjectList{s};

    file = fullfile(connectivityPath, ...
        [subjectID '_CTC_connectivity.mat']);

    if ~isfile(file)
        warning('Missing connectivity file for %s', subjectID);
        continue;
    end

    S = load(file, 'CTCstrength');

    if ~isfield(S, 'CTCstrength')
        warning('CTCstrength missing for %s', subjectID);
        continue;
    end

    % Expect one scalar connectivity value per subject
    if ~isnumeric(S.CTCstrength) || ...
            ~isscalar(S.CTCstrength)
        warning('CTCstrength is not scalar for %s', subjectID);
        continue;
    end

    CTCstrength(s) = double(S.CTCstrength);

end

% Generate scatter plots

fig = figure('Color', 'w', ...
    'Position', [150 200 1200 400]);

for c = 1:3

    x = CTCstrength;
    y = normalized(:, c);

    % Exclude missing or invalid observations
    valid = isfinite(x) & isfinite(y);

    subplot(1, 3, c);
    hold on;

    % Scatter individual subjects
    scatter(x(valid), y(valid), 65, ...
        [0.20 0.45 0.75], 'filled', ...
        'MarkerFaceAlpha', 0.75);

    % Linear best-fit line (visualization only)
    if sum(valid) >= 2 && numel(unique(x(valid))) >= 2

        coefficients = polyfit(x(valid), y(valid), 1);

        xFit = linspace(min(x(valid)), ...
            max(x(valid)), 100);

        yFit = polyval(coefficients, xFit);

        plot(xFit, yFit, '-', ...
            'Color', [0.85 0.25 0.20], ...
            'LineWidth', 2);

    end

    % Reference line: no change from baseline
    yline(1, '--', 'Color', [0.5 0.5 0.5], ...
        'LineWidth', 1);

    xlabel('CTC strength');
    ylabel('Normalized MEP amplitude');
    title(fusLabels{c}, 'FontWeight', 'bold');

    grid on;
    set(gca, 'Box', 'off', ...
        'FontSize', 11, ...
        'TickDir', 'out', ...
        'LineWidth', 1);

end

sgtitle('CTC connectivity vs FUS responses', ...
    'FontSize', 15, 'FontWeight', 'bold');

exportgraphics(fig, fullfile(subjectDataPath, ...
    'CTC_FUS_Scatter.png'), 'Resolution', 300);


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