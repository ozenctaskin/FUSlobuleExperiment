close all; clear all; clc

% Subject path and randomization file
subjectDataPath = '/Users/ozzy/Desktop/FUSlobuleExperiment';
randomizationFile = '/Users/ozzy/Desktop/FUSlobuleExperiment/basalRandomization.xlsx';
sumMethod = 'median'; % Or mean

% Subject names and randomization key (codes real sessions)
subjectList = {'L001','L002','L003','L007','L009','L010','LDC01',...
               'LDC05','LDC06','LDC07'};

% Based on the randomization file, find the sham and real sessions.
randTable = readtable(randomizationFile, 'ReadVariableNames', false);

% Get the sham and GPi session orders from excel file
shamVisitFolder = cell(size(subjectList));
gpiVisitFolder = cell(size(subjectList));

% Loop through subjects
for i = 1:numel(subjectList)
    % Find subject in randomization table
    idx = strcmp(string(randTable{:,1}), subjectList{i});
    if ~any(idx)
        error('Subject %s not found!', subjectList{i});
    end

    % Get visit 1 and visit 2 conditions
    visit1 = string(randTable{idx,2});
    visit2 = string(randTable{idx,3});

    % Determine sham and real visits
    if strcmpi(strtrim(visit1), 'Sham')
        shamVisitFolder{i} = 'basalGanglia_visit1';
        gpiVisitFolder{i} = 'basalGanglia_visit2';
    elseif strcmpi(strtrim(visit2), 'Sham')
        shamVisitFolder{i} = 'basalGanglia_visit2';
        gpiVisitFolder{i} = 'basalGanglia_visit1';
    else
        warning('Invalid randomization for subject %s', subjectList{i});
    end
end

% Loop through subjects, process data
real.baselinePre = []; sham.baselinePre = []; 
real.baselinePost = []; sham.baselinePost = [];
real.L5Pre = []; sham.L5Pre = [];
real.L5Post = []; sham.L5Post = [];
real.L8Pre = []; sham.L8Pre = [];
real.L8Post = []; sham.L8Post = [];

for i = 1:numel(subjectList)
    realPath = fullfile(subjectDataPath, subjectList{i}, 'EMG', gpiVisitFolder{i});
    real.baselinePre(end+1) = processSubjectData(realPath, 'baseline', 'pre', sumMethod);
    real.baselinePost(end+1) = processSubjectData(realPath, 'baseline', 'post', sumMethod);
    real.L5Pre(end+1) = processSubjectData(realPath, 'L5', 'pre', sumMethod);
    real.L5Post(end+1) = processSubjectData(realPath, 'L5', 'post', sumMethod);
    real.L8Pre(end+1) = processSubjectData(realPath, 'L8', 'pre', sumMethod);
    real.L8Post(end+1) = processSubjectData(realPath, 'L8', 'post', sumMethod);    
    
    shamPath = fullfile(subjectDataPath, subjectList{i}, 'EMG', shamVisitFolder{i});
    sham.baselinePre(end+1) = processSubjectData(shamPath, 'baseline', 'pre', sumMethod);
    sham.baselinePost(end+1) = processSubjectData(shamPath, 'baseline', 'post', sumMethod);
    sham.L5Pre(end+1) = processSubjectData(shamPath, 'L5', 'pre', sumMethod);
    sham.L5Post(end+1) = processSubjectData(shamPath, 'L5', 'post', sumMethod);
    sham.L8Pre(end+1) = processSubjectData(shamPath, 'L8', 'pre', sumMethod);
    sham.L8Post(end+1) = processSubjectData(shamPath, 'L8', 'post', sumMethod);       
end

% Calculate CBI for L5 and L8
real.L5PreCBI = real.L5Pre ./ real.baselinePre;
real.L5PostCBI = real.L5Post ./ real.baselinePost;
real.L8PreCBI = real.L8Pre ./ real.baselinePre;
real.L8PostCBI = real.L8Post ./ real.baselinePost;

sham.L5PreCBI = sham.L5Pre ./ sham.baselinePre;
sham.L5PostCBI = sham.L5Post ./ sham.baselinePost;
sham.L8PreCBI = sham.L8Pre ./ sham.baselinePre;
sham.L8PostCBI = sham.L8Post ./ sham.baselinePost;

% Plot baseline MEP and CBI for L5 and L8
conditions = {real, sham};
names = {'Real', 'Sham'};

measures = {'baseline', 'L5', 'L8'};
labels = {'MEP amplitude (mV)', 'L5 CBI ratio', 'L8 CBI ratio'};

basalFigures = fullfile(subjectDataPath, 'basalFigures');
if ~exist(basalFigures)
    mkdir(basalFigures)
end

for c = 1:2
    for m = 1:3

        % Select data
        if m == 1
            pre = conditions{c}.baselinePre(:);
            post = conditions{c}.baselinePost(:);
        else
            pre = conditions{c}.([measures{m} 'PreCBI'])(:);
            post = conditions{c}.([measures{m} 'PostCBI'])(:);
        end

        figure('Color', 'w');
        hold on;

        % Colored boxplots
        boxchart(ones(size(pre)), pre, ...
            'BoxFaceColor', [0.3 0.6 0.9]);
        boxchart(2*ones(size(post)), post, ...
            'BoxFaceColor', [0.9 0.4 0.3]);

        % % Connect individual subjects
        % plot([ones(size(pre)), 2*ones(size(post))]', [pre, post]', ...
        %     '-o', 'Color', [0.6 0.6 0.6]);

        xticks([1 2]);
        xticklabels({'Pre', 'Post'});
        ylabel(labels{m});
        title([names{c} ' Basal Stimulation - ' measures{m}]);
        box off;

        % Reference line for CBI = 1 (no inhibition)
        if m > 1
            yline(1, '--k');
        end

        % Save figure
        exportgraphics(gcf, ...
            fullfile(basalFigures, ...
            [names{c} '_' measures{m} '_plot.png']), ...
            'Resolution', 300);
    end
end


% Helper function to process individual data based on session folder and
% target
function avgP2P = processSubjectData(sessionFolder, target, condition, sumMethod)

    % sessionFolder: Where you have the cleaned mat traces
    % target: L8, L5, baseline
    % condition: 'pre' or 'post'
    % sumMethod: session mean or median

    % Define where in the time we are looking for the MEP
    MEPframes = (2800:3000);

    % Find the condition file in the directory
    files = dir(fullfile(sessionFolder, ['clean_' target '_' condition '*.mat']));
    if numel(files) ~= 1
        error('Expected one file for %s %s, found %d', ...
            target, condition, numel(files));
    end
    file = fullfile(sessionFolder, files(1).name);

    % Load data and plot all traces cut to the portion of MEP. Save plot 
    vars = whos('-file', file);
    idx = find(contains({vars.name}, '_wave_data'));
    if numel(idx) ~= 1
        error('Expected one waveform variable in %s', file);
    end
    fileLoaded = load(file, vars(idx).name);
    data = squeeze(fileLoaded.(vars(idx).name).values(MEPframes,1,:));
    
    fig = figure('Visible', 'off');
    plot(data);
    saveas(fig, fullfile(sessionFolder, ['plot_' vars(idx).name, '.png']));
    close(fig);

    % Do peak to peak on each trial and return median or mean
    if strcmp(sumMethod, 'mean')
        avgP2P = mean(peak2peak(data,1));
    elseif strcmp(sumMethod, 'median')
        avgP2P = median(peak2peak(data,1));
    else
        error('Summarization method not recognized. Either specify mean or median');
    end
end