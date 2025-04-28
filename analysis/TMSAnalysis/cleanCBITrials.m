function droppedTrials = cleanCBITrials(dataPath)

% This function loops through CBI trials and asks whether they should be
% kept or discarded. Saves a new data with the same file name that starts
% with "clean_". Only supports single channel.

% Load data
[filepath, filename, extension] = fileparts(dataPath);
data = load(dataPath, [filename, '_wave_data']);
data = data.([filename, '_wave_data']);

% Create an empty struct to save the indices of to-be-deleted trials 
droppedTrials = [];

% Loop through data, plot, and ask whether to keep or delete. Save the
% indices of dropped values
for ii = 1:size(data.values,3)
    dat = data.values(:,1,ii);
    plot(dat)
    hold on
    ylim([-0.6 0.6])
    plot([0:2752], ones(length([0:2752]))*0.05, 'r')
    plot([0:2752], ones(length([0:2752]))*-0.05, 'r')
    hold off

    decision = input(['Drop trial number ' num2str(ii) '/' num2str(size(data.values,3)) ' enter: y/n: \n'], 's');
    if strcmp(decision, 'y')
        droppedTrials = [droppedTrials, ii];
    end
end

% Drop the bad trials  
data.values(:,:,droppedTrials) = [];
data.frameinfo(droppedTrials,:) = [];

save(fullfile(filepath, ['clean_' filename extension]), 'data')
close all

end



