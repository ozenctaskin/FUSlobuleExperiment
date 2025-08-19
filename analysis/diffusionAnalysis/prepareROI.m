function prepareROI(dataFolder, subjectID, sessionID)
    
    % Get T1 and T2 images in the DWI space
    T1w = fullfile(dataFolder, subjectID, sessionID, [subjectID, '.diffusionResults'], 'preprocessed', 'T1InDWI.nii.gz');
    T2w = fullfile(dataFolder, subjectID, sessionID, [subjectID, '.diffusionResults'], 'preprocessed', 'T2InDWI.nii.gz');

    % Run freesurfer
    surfDir = fullfile(dataFolder, subjectID, sessionID, [subjectID, '.diffusionResults'], [subjectID '_freesurfer']);
    if ~isfile(surfDir)
        system(['recon-all -all -subject ' subjectID '_freesurfer' ' -i ' T1w ' -T2 ' T2w ' -T2pial -sd ' fullfile(dataFolder, subjectID, sessionID, [subjectID, '.diffusionResults'])]);
    end

    % Run 5ttgen
    tsegments = fullfile(dataFolder, subjectID, sessionID, [subjectID, '.diffusionResults'], 'preprocessed', 'segmented5Tissues.mif');
    if ~isfile(tsegments)
        system(['5ttgen hsvs -nthreads 10 -white_stem ' surfDir ' ' tsegments]);
    end   

end