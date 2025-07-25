function cleanCBITrials(folderPath, autoclean)
    
    % This function loops through mat data in a subject folder and cleans
    % trials either manually, if autoclean is set to false, or automatically,
    % if autoclean is set to true. Automatic cleaning is done by rejection all
    % trials whose RMS of baseline (100ms prior stimulus artifact) is larger
    % than 10micro volts. For CBI, this is set to 20micro volts.
    
    % Find matlab files that doesn't contain clean or AMT in the name
    files = dir(fullfile(folderPath, '*.mat'));
    fileNames = {files.name};
    excludeMask = contains(fileNames, 'AMT') | contains(fileNames, 'clean');
    filteredFiles = files(~excludeMask);
    fullPaths = fullfile(folderPath, {filteredFiles.name});
    
    % Set measurement variables
    samplingRate = 5000; 
    hundredMs = samplingRate * 0.1; 
    RMSthreshold_TUS = 0.01; % 10 microVolts in milliVolt 
    RMSthreshold_TMS = 0.02; % 20 microVolt in milliVolt 

    for ii = 1:length(fullPaths)
    
        % Load data
        [filepath, filename, extension] = fileparts(fullPaths{ii});
        if strcmp(filename(1), '0') || strcmp(filename(1), '3')
            data = load(fullPaths{ii}, ['V', filename, '_wave_data']);
            data = data.(['V', filename, '_wave_data']);    
        else    
            data = load(fullPaths{ii}, [filename, '_wave_data']);
            data = data.([filename, '_wave_data']);
        end
        
        % Specify data topography (in frames not time). CBI pulse has different
        % timeline. Take the conditioning pulse as the artifact start. Happens at 
        % frames 975.
        if contains(filename, 'CBI')
            artifactStart = 975;
            RMSthreshold = RMSthreshold_TMS;
        else
            artifactStart = 2750;
            RMSthreshold = RMSthreshold_TUS;
        end
        
        % Create an empty struct to save the indices of to-be-deleted trials 
        droppedTrials = [];
        
        % Loop through data, plot, and ask whether to keep or delete. Save the
        % indices of dropped values
        for ii = 1:size(data.values,3)
            dat = data.values(:,1,ii);
            if ~autoclean
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
            end
            
            % Check that RMS of 100ms prior artifact is not bigger than 10microV
            if ~autoclean
                if rms(dat(artifactStart-hundredMs:artifactStart)) > RMSthreshold
                    text(xLimits(2), yLimits(2) - 0.1*(yLimits(2) - yLimits(1)), 'Warning: RMS baseline > 10microV', ...
                    'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
                    'Color', 'red');
                end
                hold off
                decision = input(['Drop trial number ' num2str(ii) '/' num2str(size(data.values,3)) ' enter: y/n: \n'], 's');
            else
                if rms(dat(artifactStart-hundredMs:artifactStart)) > RMSthreshold
                    decision = 'y';
                else
                    decision = 'n';
                end
            end
        
            % Decision list
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
end

