function droppedTrials = cleanCBITrials(dataPath)

% This function loops through CBI trials and asks whether they should be
% kept or discarded. Saves a new data with the same file name that starts
% with "clean_". Only supports single channel.

% Load data
[filepath, filename, extension] = fileparts(dataPath);
if strcmp(filename(1), '0') || strcmp(filename(1), '3')
    data = load(dataPath, ['V', filename, '_wave_data']);
    data = data.(['V', filename, '_wave_data']);    
else    
    data = load(dataPath, [filename, '_wave_data']);
    data = data.([filename, '_wave_data']);
end

% Specify data topography (in frames not time). CBI pulse has different
% timeline. Take the conditioning pulse as the artifact start. Happens at 
% frames 975.
samplingRate = 5000; 
if contains(filename, 'CBI')
    artifactStart = 975;
else
    artifactStart = 2750;
end

% Calculate the number of frames that correspond to 100ms based on sampling
% and set a 10 microVolt threshold for RMS
hundredMs = samplingRate * 0.1; 
RMSthreshold = 0.01; % 10 microVolt in milliVolt 

% Create an empty struct to save the indices of to-be-deleted trials 
droppedTrials = [];

% Loop through data, plot, and ask whether to keep or delete. Save the
% indices of dropped values
for ii = 1:size(data.values,3)
    dat = data.values(:,1,ii);
    plot(dat)
    hold on
    ylim([-1 1])
    plot(artifactStart-hundredMs:artifactStart, ones(length(artifactStart-hundredMs:artifactStart))*0.05, 'r')
    plot(artifactStart-hundredMs:artifactStart, ones(length(artifactStart-hundredMs:artifactStart))*-0.05, 'r')
    maxIdx = find(dat(artifactStart+50:end) == max(dat(artifactStart+50:end)));
    minIdx = find(dat(artifactStart+50:end) == min(dat(artifactStart+50:end)));
    plot((artifactStart+50 + maxIdx-1), max(dat(artifactStart+50:end)), 'r*')
    plot((artifactStart+50 + minIdx-1), min(dat(artifactStart+50:end)), 'r*')
    % Get axis limits
    xLimits = xlim;
    yLimits = ylim;

    % Check if there are more than 2 peaks. Plot a warning. 
    if length(maxIdx) > 1 || length(minIdx) > 1
        % Add text to the top right corner
        text(xLimits(2), yLimits(2), 'Warning: multiple peaks', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top','Color', 'red');
    end  
    % Check that RMS of 100ms prior artifact is not bigger than 10microV
    if rms(dat(artifactStart-hundredMs:artifactStart)) > RMSthreshold
        text(xLimits(2), yLimits(2) - 0.1*(yLimits(2) - yLimits(1)), 'Warning: RMS baseline > 10microV', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
        'Color', 'red');
    end
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



