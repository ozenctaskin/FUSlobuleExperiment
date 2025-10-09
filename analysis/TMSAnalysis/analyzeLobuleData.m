close all; clear all; clc

% Decide what this function will do when run
setDiagnostics = false; % Saves diagnostic images in the data folder
baselineCorrect = true; % Corrects baseline
grandBaseline = true;   % Corrects a grand average baseline. Alternative is FUS corrected with FUS, TMS with TMS
useClean = true;        % Use the clean data for analysis. Need to run cleanCBITrials first
plotSubject = false;    % Plots all trials for all subjects in separate figure.

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

data.L001 =   {fullfile(dataFolder, 'L001', 'EMG', 'baseline_300525_000.mat'), ...
               fullfile(dataFolder, 'L001', 'EMG', 'DN_300525_000.mat'), ...
               fullfile(dataFolder, 'L001', 'EMG', 'L5_300525_000.mat'), ...
               fullfile(dataFolder, 'L001', 'EMG', 'L8_300525_000.mat'), ...
               fullfile(dataFolder, 'L001', 'EMG', 'V1_300525_000.mat'), ...
               fullfile(dataFolder, 'L001', 'EMG', 'V0W_300525_000.mat'), ...
               fullfile(dataFolder, 'L001', 'EMG', 'Flip_300525_000.mat'), ...
               fullfile(dataFolder, 'L001', 'EMG', 'CBI45_3005_1718_000.mat'), ...
               fullfile(dataFolder, 'L001', 'EMG', 'CBI55_3005_1737_000.mat')}; 
               % DROPPED fullfile(dataFolder, 'L001_ses2', 'EMG', 'CBI60_3005_1731_000.mat' 

data.L002 =   {fullfile(dataFolder, 'L002', 'EMG', 'Baseline_110725_000.mat'), ...
               fullfile(dataFolder, 'L002', 'EMG', 'DN_110725_000.mat'), ...
               fullfile(dataFolder, 'L002', 'EMG', 'L5_110725_000.mat'), ...
               fullfile(dataFolder, 'L002', 'EMG', 'L8_110725_000.mat'), ...
               fullfile(dataFolder, 'L002', 'EMG', 'V1_110725_000.mat'), ...
               fullfile(dataFolder, 'L002', 'EMG', 'V0W-DN_110725_000.mat'), ...
               fullfile(dataFolder, 'L002', 'EMG', 'Flip_110725_000.mat'), ...
               fullfile(dataFolder, 'L002', 'EMG', 'SUBJ_CBI65_1107_1501_000.mat'), ...
               fullfile(dataFolder, 'L002', 'EMG', 'SUBJ_CBI55_1107_1513_000.mat')}; 

data.L003 =   {fullfile(dataFolder, 'L003', 'EMG', 'baseline_220725_000.mat'), ...
               fullfile(dataFolder, 'L003', 'EMG', 'DN_220725_000.mat'), ...
               fullfile(dataFolder, 'L003', 'EMG', 'L5_220725_000.mat'), ...
               fullfile(dataFolder, 'L003', 'EMG', 'L8_220725_000.mat'), ...
               fullfile(dataFolder, 'L003', 'EMG', 'V1_220725_000.mat'), ...
               fullfile(dataFolder, 'L003', 'EMG', 'V0wL8_220725_000.mat'), ...
               fullfile(dataFolder, 'L003', 'EMG', 'L5Flip_220725_000.mat'), ...
               fullfile(dataFolder, 'L003', 'EMG', 'SUBJ_CBI65_2207_1621_000.mat'), ...
               fullfile(dataFolder, 'L003', 'EMG', 'SUBJ_CBI55_2207_1621_000.mat')}; 

data.L004 =   {fullfile(dataFolder, 'L004', 'EMG', 'baseline_030725_000.mat'), ...
               fullfile(dataFolder, 'L004', 'EMG', 'dentate_030725_000.mat'), ...
               fullfile(dataFolder, 'L004', 'EMG', 'L5p2_030725_000.mat'), ...
               fullfile(dataFolder, 'L004', 'EMG', 'L8_030725_000.mat'), ...
               fullfile(dataFolder, 'L004', 'EMG', 'V1_030725_000.mat'), ...
               fullfile(dataFolder, 'L004', 'EMG', 'V0w_030725_000.mat'), ...
               fullfile(dataFolder, 'L004', 'EMG', 'Flip_030725_000.mat'), ...
               fullfile(dataFolder, 'L004', 'EMG', 'NA'), ...
               fullfile(dataFolder, 'L004', 'EMG', 'NA')};

data.L005 =   {fullfile(dataFolder, 'L005', 'EMG', 'baseline33_020925_000.mat'), ...
               fullfile(dataFolder, 'L005', 'EMG', 'DN_020925_000.mat'), ...
               fullfile(dataFolder, 'L005', 'EMG', 'L5_020925_000.mat'), ...
               fullfile(dataFolder, 'L005', 'EMG', 'L8_020925_000.mat'), ...
               fullfile(dataFolder, 'L005', 'EMG', 'V1_020925_000.mat'), ...
               fullfile(dataFolder, 'L005', 'EMG', 'V0W_L8_020925_000.mat'), ...
               fullfile(dataFolder, 'L005', 'EMG', 'Flip_020925_000.mat'), ...
               fullfile(dataFolder, 'L005', 'EMG', 'SUBJ_CBI65_0209_1640_000'), ...
               fullfile(dataFolder, 'L005', 'EMG', 'SUBJ_CBI55_0209_1654_000.mat')};

data.L006 =   {fullfile(dataFolder, 'L006', 'EMG', 'baseline_220925_000.mat'), ...
               fullfile(dataFolder, 'L006', 'EMG', 'DN_220925_000.mat'), ...
               fullfile(dataFolder, 'L006', 'EMG', 'L5_220925_000.mat'), ...
               fullfile(dataFolder, 'L006', 'EMG', 'L8_220925_000.mat'), ...
               fullfile(dataFolder, 'L006', 'EMG', 'V1_220925_000.mat'), ...
               fullfile(dataFolder, 'L006', 'EMG', 'V0w_220925_000.mat'), ...
               fullfile(dataFolder, 'L006', 'EMG', 'flip_220925_000.mat'), ...
               fullfile(dataFolder, 'L006', 'EMG', 'NA'), ...
               fullfile(dataFolder, 'L006', 'EMG', 'NA')};

data.L007 =   {fullfile(dataFolder, 'L007', 'EMG', 'baseline_260925_000.mat'), ...
               fullfile(dataFolder, 'L007', 'EMG', 'DN_260925_000.mat'), ...
               fullfile(dataFolder, 'L007', 'EMG', 'L5_260925_000.mat'), ...
               fullfile(dataFolder, 'L007', 'EMG', 'L8_2_260925_000.mat'), ...
               fullfile(dataFolder, 'L007', 'EMG', 'V1_260925_000.mat'), ...
               fullfile(dataFolder, 'L007', 'EMG', 'V0wL8_260925_000.mat'), ...
               fullfile(dataFolder, 'L007', 'EMG', 'Flip_260925_000.mat'), ...
               fullfile(dataFolder, 'L007', 'EMG', 'SUBJ_CBI65_2609_1830_000.mat'), ...
               fullfile(dataFolder, 'L007', 'EMG', 'SUBJ_CBI55_2609_1837_000.mat')};

% Get fieldnames and empty cell for all subject peaks so we can do some
% averaging at the end.
subjectIDs = fieldnames(data);
allSubjectPeaks = {};
% Set labels and colors. WARNING the word baseline needs to be used for
% baseline labels, as the scripts look for it to find the baseline data
labels = {'baseline','dentate','lobule 5','lobule 8','sham V1','sham 0w','sham 30w','baseline-1','CBI-1','baseline-2','CBI-2'};
colors = {'r', 'g', 'b', 'c', 'm', 'y', 'k', [0.8500, 0.3250, 0.0980], [0.8500, 0.3250, 0.0980], [0.4940, 0.1840, 0.5560], [0.4940, 0.1840, 0.5560]};
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
    if useClean
        data.(subjectIDs{sub}) = cellfun(@(p) fullfile(fileparts(p), ['clean_' extractAfter(p, [filesep 'EMG' filesep])]), data.(subjectIDs{sub}), 'UniformOutput', false);
    else
        data.(subjectIDs{sub}) = cellfun(@(p) fullfile(fileparts(p), [extractAfter(p, [filesep 'EMG' filesep])]), data.(subjectIDs{sub}), 'UniformOutput', false);
    end        
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
            plotLabels = labels;
            plotLabels(contains(plotLabels, 'baseline-')) = []; % drop baseline labels cuz we are plotting the entire CBI
            f = figure('visible','off');
            sgtitle([subjectIDs{sub} ' ' plotLabels{ii}])
            for plt = 1:size(dataset.values, 3)
                if ii < 8
                    subplot(4,5,plt)
                    plot(dataset.values(2800:3100,1,plt))
                else
                    subplot(4,6,plt)
                    plot(dataset.values(1025:end,1,plt))
                end
            end
            saveas(f,fullfile(dataPath, 'diagnostics', [subjectIDs{sub} '_' plotLabels{ii}]),'jpg')
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
    % Plot if requested 
    if plotSubject
        % Do a box plot for the values 
        figure('Position', [100, 100, 800, 600])
        boxplot(subjectPeaks, labels(1:size(subjectPeaks, 2)), 'Symbol', '')
        ylim([0 6])
        title(subjectIDs{sub})
        hold on
        % Add scatter points next to each boxplot
        x = repmat(1:size(subjectPeaks, 2), size(subjectPeaks, 1), 1); % X-coordinates
        x = x + 0.1 * (rand(size(x)) - 0.5); % Add a small random jitter to spread points
        for sct = 1:size(x,2)
            scatter(x(:,sct), subjectPeaks(:,sct), 'filled', 'MarkerFaceAlpha', 0.6, 'MarkerFaceColor', colors{sct})
        end
        hold off 
    end
    allSubjectPeaks{sub} = subjectPeaks;
end

% Plot dentate, lobule 5 and 8 increase
figure;
title('Subject average peak2peak change with each trial')
subplot(1,3,1)
plot(nanmean(cell2mat(cellfun(@(x) x(:,2), allSubjectPeaks, 'UniformOutput', false)), 2), 'b')
legend('Dentate Temporal')
xlabel('Trials')
ylabel('Dentate peak2paek')
subplot(1,3,2)
plot(nanmean(cell2mat(cellfun(@(x) x(:,3), allSubjectPeaks, 'UniformOutput', false)), 2), 'r')
legend('Lobule 5 Temporal')
xlabel('Trials')
ylabel('Lobule 5 peak2paek')
subplot(1,3,3)
plot(nanmean(cell2mat(cellfun(@(x) x(:,4), allSubjectPeaks, 'UniformOutput', false)), 2), 'g')
legend('Lobule 8 Temporal')
xlabel('Trials')
ylabel('Lobule 8 peak2paek')
legend('Lobule 8 Temporal')

% Loop through all subject peak calculations and do averaging. Also do
% baseline correction if requested
baselineVals = find(contains(labels, 'baseline'));
averageSubjectPeaks = {};
for ii = 1:size(allSubjectPeaks,2)
    % Average all trials
    averageSubjectPeaks{ii} = nanmean(allSubjectPeaks{ii});
    if baselineCorrect
        if grandBaseline
            % Find vectors based on "baseline" keyword in the labels cell.
            baselines = allSubjectPeaks{ii}(:,baselineVals);
            % Flatten and average baseline trials 
            gBaseline = nanmean(baselines(:));
            % Replace the first item on the cell (FUS baseline) with the
            % grand baseline. Drop the rest of the baseline measurements
            % from the averagePeaks.
            averageSubjectPeaks{ii}(1) = gBaseline; 
            averageSubjectPeaks{ii}(baselineVals(2:end)) = [];
            % Now normalize each value with the baseline
            averageSubjectPeaks{ii} = averageSubjectPeaks{ii}./averageSubjectPeaks{ii}(1);
            averageSubjectPeaks{ii}(1) = [];
        else
            FUS = averageSubjectPeaks{ii}(1:7);
            FUSbaselineCorrected = FUS./FUS(1);
            FUSbaselineCorrected(1) = [];
            TMS = averageSubjectPeaks{ii}(8:end);
            TMSbaselineCorrected = TMS(2:2:end) ./ TMS(1:2:end);
            averageSubjectPeaks{ii} = [];
            averageSubjectPeaks{ii} = [FUSbaselineCorrected, TMSbaselineCorrected];
        end
    end
end

% If baseline correct is passed, remove the baseline labels 
if baselineCorrect
    labels(baselineVals) = [];
end


% Do a boxplot
subjectMat = cell2mat(averageSubjectPeaks');
figure('Position', [100, 100, 800, 600])
boxplot(subjectMat, labels, 'Symbol', '')
hold on
h = findobj(gca, 'Tag', 'Box'); 
for j = 1:length(h)
    patch(get(h(j), 'XData'), get(h(j), 'YData'), [0.3010 0.7450 0.9330], 'FaceAlpha', 0.5); % Fill boxes with color
end

% Scatter plot with jitter
jitterAmount = 0.05;  % You can increase this if needed
for ii = 1:size(subjectMat,2) 
    for jj = 1:numel(fieldnames(data))  
        xJittered = ii + (rand()*2 - 1) * jitterAmount;  % adds uniform jitter between -jitterAmount and +jitterAmount
        scatter(xJittered, subjectMat(jj,ii), 50, 'k', 'filled'); 
    end
end

% Set plot properties
if baselineCorrect
    xlim([0 10]);
    ylim([0 6]);
    yline(1, 'r--', 'LineWidth', 1.5);
    if grandBaseline
        ylabel('Grand baseline corrected MEP');
    else
        ylabel('Local baseline corrected MEP');
    end
else
    ylim([0 3]);
    ylabel('MEP amplitude (mV)')
end
xticklabels(labels);
set(gca, 'FontSize', 25) 
ax = gca;
ax.Box = 'off';
title('Subject results - Averaged Peaks');

% Do correlation plots if baseline corrected
if baselineCorrect
    figure; 
    
    subplot(2,3,1);
    scatter(subjectMat(:,1), subjectMat(:,7), 'filled');
    xlabel('Dentate'); ylabel('CBI-1');
    xlim([0 1]); ylim([0 1]);
    axis square
    
    subplot(2,3,2);
    scatter(subjectMat(:,2), subjectMat(:,7), 'filled');
    xlabel('Lobule 5'); ylabel('CBI-1');
    xlim([0 1]); ylim([0 1]);
    axis square
    
    subplot(2,3,3);
    scatter(subjectMat(:,3), subjectMat(:,7), 'filled');
    xlabel('Lobule 8'); ylabel('CBI-1');
    xlim([0 1]); ylim([0 1]);
    axis square

    subplot(2,3,4);
    scatter(subjectMat(:,1), subjectMat(:,8), 'filled');
    xlabel('Dentate'); ylabel('CBI-2');
    xlim([0 1]); ylim([0 1]);
    axis square
    
    subplot(2,3,5);
    scatter(subjectMat(:,2), subjectMat(:,8), 'filled');
    xlabel('Lobule 5'); ylabel('CBI-2');
    xlim([0 1]); ylim([0 1]);
    axis square
    
    subplot(2,3,6);
    scatter(subjectMat(:,3), subjectMat(:,8), 'filled');
    xlabel('Lobule 8'); ylabel('CBI-2');
    xlim([0 1]); ylim([0 1]);
    axis square    
end

% Save a sheet for future anayses. Only save if grandBaseline is used.
if baselineCorrect
    sheetLabels = [{'subject'}, labels];
    subjects = fieldnames(data);
    % Create table
    T = array2table(subjectMat, 'VariableNames', sheetLabels(2:end));
    T = addvars(T, subjects, 'Before', 1, 'NewVariableNames', sheetLabels{1});
    if ~grandBaseline
        writetable(T, fullfile(dataFolder, 'subject_results_individualBaseline.xlsx'))
    else
        writetable(T, fullfile(dataFolder, 'subject_results_grandBaseline.xlsx'))
    end
end

% Helper function to load data in without sub variable names
function data = load_wave_data(filename, useClean)
    testName = string(split(filename, '/')); testName = testName{end};
    if ~strcmp(testName, 'NA') && ~strcmp(testName, 'clean_NA')
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
    else
        data.frameinfo.state = ones(20,1);
        data.frameinfo.state(11:end) = 2;
        data.values = nan(4000,2,20);
    end
end