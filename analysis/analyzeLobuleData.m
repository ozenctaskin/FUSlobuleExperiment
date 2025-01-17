clear all; clc

% Decide if we are saving diagnostic images. Takes a while to run when set
% to true
setDiagnostics = true; 

% Specify subject paths. Order needs to be baseline, DN, L5, L8, V1, DN_0w,
% DN_30w
data.HERO01 = {'/Volumes/chenshare/Ozzy_Taskin/pilot_data/lobuleExperiment/data/HERO_01/clean_Baseline_160125_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/pilot_data/lobuleExperiment/data/HERO_01/clean_DN_160125_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/pilot_data/lobuleExperiment/data/HERO_01/clean_L5_160125_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/pilot_data/lobuleExperiment/data/HERO_01/clean_L8_160125_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/pilot_data/lobuleExperiment/data/HERO_01/clean_V1_160125_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/pilot_data/lobuleExperiment/data/HERO_01/clean_DN_0wsham_160125_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/pilot_data/lobuleExperiment/data/HERO_01/clean_DN_30wflip_160125_000.mat'};

data.HERO02 = {'/Volumes/chenshare/Ozzy_Taskin/pilot_data/lobuleExperiment/data/HERO_02/clean_X_161224_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/pilot_data/lobuleExperiment/data/HERO_02/clean_Dentate_161224_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/pilot_data/lobuleExperiment/data/HERO_02/clean_Lobule5_161224_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/pilot_data/lobuleExperiment/data/HERO_02/clean_Lobule8_161224_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/pilot_data/lobuleExperiment/data/HERO_02/clean_V1_161224_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/pilot_data/lobuleExperiment/data/HERO_02/clean_DentateSham0w_161224_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/pilot_data/lobuleExperiment/data/HERO_02/clean_DentateSham302_161224_000.mat'};

data.HERO03 = {'/Volumes/chenshare/Ozzy_Taskin/pilot_data/lobuleExperiment/data/HERO_03/clean_Baseline_030125_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/pilot_data/lobuleExperiment/data/HERO_03/clean_DN_030125_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/pilot_data/lobuleExperiment/data/HERO_03/clean_L5_030125_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/pilot_data/lobuleExperiment/data/HERO_03/clean_L8_take2_030125_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/pilot_data/lobuleExperiment/data/HERO_03/clean_V1_030125_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/pilot_data/lobuleExperiment/data/HERO_03/clean_DN_0w_030125_000.mat', ...
               '/Volumes/chenshare/Ozzy_Taskin/pilot_data/lobuleExperiment/data/HERO_03/clean_Dn_30wflip_030125_000.mat'}; 


% Get fieldnames and empty cell for all subject peaks so we can do some
% averaging at the end. Also specify order of the data entry
subjectIDs = fieldnames(data);
allPeaks = {};
labels = {'baseline','dentate','lobule5','lobule8','V1sham','sham0w','sham30w'};

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
    boxplot(subjectPeaks, labels)
    ylim([0 6])
    title(subjectIDs{sub})
    allPeaks{sub} = subjectPeaks;
end

% Plot the subject average box plot
mean = nanmean(cat(3, allPeaks{:}), 3);
figure
boxplot(mean, labels)
ylim([0 6])
title('Average')
