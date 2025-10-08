function averageResponseFunctions(bidsFolder)

    % Get folders that starts with sub-
    d = dir(fullfile(bidsFolder, 'sub-*'));

    % Keep only folders (exclude files) and append path
    subFolders = d([d.isdir]);
    subFolders = fullfile(bidsFolder, {subFolders.name});

    % Loop through subjects and append response function paths to a strings
    wmResponse = '';
    gmResponse = '';
    csfResponse = ''; 
    subjectList = strings(0,1);
    for ii = 1:length(subFolders)
        [~, subjectID] = fileparts(subFolders{ii});
        if isfile(fullfile(subFolders{ii}, 'ses-01', [subjectID '.diffusionResults'], 'preprocessed', 'wmResponse.txt'))
            wmResponse = [wmResponse fullfile(subFolders{ii}, 'ses-01', [subjectID '.diffusionResults'], 'preprocessed', 'wmResponse.txt') ' '];
            gmResponse = [gmResponse fullfile(subFolders{ii}, 'ses-01', [subjectID '.diffusionResults'], 'preprocessed', 'gmResponse.txt') ' '];
            csfResponse = [csfResponse fullfile(subFolders{ii}, 'ses-01', [subjectID '.diffusionResults'], 'preprocessed', 'csfResponse.txt') ' '];
            subjectList(end+1) = subjectID;
        end
    end

    % Run response function averaging 
    system(['responsemean ' wmResponse ' ' fullfile(bidsFolder, 'wmAverageResponse.txt')]);
    system(['responsemean ' gmResponse ' ' fullfile(bidsFolder, 'gmAverageResponse.txt')]);
    system(['responsemean ' csfResponse ' ' fullfile(bidsFolder, 'csfAverageResponse.txt')]);

    % Write the list of subjects we used for response averaging to a text
    % file in the bidsFolder
    writelines(subjectList, fullfile(bidsFolder, 'responseSubjectList.txt'));
end