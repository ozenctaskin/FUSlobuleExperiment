useClean = false;
setDiagnostics = false;
plotSubject = true;
dataFolder = '/Volumes/chenshare/Ozzy_Taskin/Experiments/TUSLobuleExperiment_And_CBIDiffusion/Data';

data.L003 =   {fullfile(dataFolder, 'L003', 'EMG', 'basalGanglia', 'baseline1_090925_000.mat'), ...
               fullfile(dataFolder, 'L003', 'EMG', 'basalGanglia', 'lobule5_1_090925_000.mat'), ...
               fullfile(dataFolder, 'L003', 'EMG', 'basalGanglia', 'lobule8_1_090925_000.mat'), ...
               fullfile(dataFolder, 'L003', 'EMG', 'basalGanglia', 'baseline_2_090925_000.mat'), ...
               fullfile(dataFolder, 'L003', 'EMG', 'basalGanglia', 'lobule5_2_090925_000.mat'), ...
               fullfile(dataFolder, 'L003', 'EMG', 'basalGanglia', 'lobule8_2_090925_000.mat')}; 

data.L004 =   {fullfile(dataFolder, 'L003', 'EMG', 'basalGanglia', 'baseline1_090925_000.mat'), ...
               fullfile(dataFolder, 'L003', 'EMG', 'basalGanglia', 'lobule5_1_090925_000.mat'), ...
               fullfile(dataFolder, 'L003', 'EMG', 'basalGanglia', 'lobule8_1_090925_000.mat'), ...
               fullfile(dataFolder, 'L003', 'EMG', 'basalGanglia', 'baseline_2_090925_000.mat'), ...
               fullfile(dataFolder, 'L003', 'EMG', 'basalGanglia', 'lobule5_2_090925_000.mat'), ...
               fullfile(dataFolder, 'L003', 'EMG', 'basalGanglia', 'lobule8_2_090925_000.mat')}; 

% Get fieldnames and empty cell for all subject peaks so we can do some
% averaging at the end.
subjectIDs = fieldnames(data);
allSubjectPeaks = {};

% Set labels and colors. WARNING the word baseline needs to be used for
% baseline labels, as the scripts look for it to find the baseline data
labels = {'baseline pre','lobule 5 pre','lobule 8 pre','baseline post','lobule 5 post','lobule 8 post'};
colors = {'r', 'g', 'b', 'c', 'm', 'y'};

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
        data.(subjectIDs{sub}) = cellfun(@(p) fullfile(fileparts(p), ['clean_' extractAfter(p, [filesep 'basalGanglia' filesep])]), data.(subjectIDs{sub}), 'UniformOutput', false);
    else
        data.(subjectIDs{sub}) = cellfun(@(p) fullfile(fileparts(p), [extractAfter(p, [filesep 'basalGanglia' filesep])]), data.(subjectIDs{sub}), 'UniformOutput', false);
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
        ylim([0 3]);
        hold off 
    end
    allSubjectPeaks{sub} = subjectPeaks;
end

% Subject averages
for ii = 1:size(allSubjectPeaks,2)
    averageSubjectPeaks{ii} = nanmean(allSubjectPeaks{ii});
end

% Box plot
subjectMat = cell2mat(averageSubjectPeaks');
lobule5Data_pre = subjectMat(:,2) ./  subjectMat(:,1);
lobule8Data_pre = subjectMat(:,3) ./  subjectMat(:,1);
lobule5Data_post = subjectMat(:,5) ./  subjectMat(:,4);
lobule8Data_post = subjectMat(:,6) ./  subjectMat(:,4);

lobuleResultsCombined = [lobule5Data_pre lobule5Data_post lobule8Data_pre  lobule8Data_post];
labels = {'lobule 5 pre', 'lobule 5 post', 'lobule 8 pre', 'lobule 8 post'};
figure('Position', [100, 100, 800, 600])
boxplot(lobuleResultsCombined, labels, 'Symbol', '')
ylim([0 2]);
yline(1, 'r--', 'LineWidth', 1.5);

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