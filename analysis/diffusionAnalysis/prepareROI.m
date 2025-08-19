function prepareROI(dataFolder, subjectID, sessionID)
    
    % Get T1 and T2 images in the DWI space
    T1w = fullfile(dataFolder, subjectID, sessionID, [subjectID, '.diffusionResults'], 'preprocessed', 'T1InDWI.nii.gz');
    T2w = fullfile(dataFolder, subjectID, sessionID, [subjectID, '.diffusionResults'], 'preprocessed', 'T2InDWI.nii.gz');

    % Run freesurfer
    surfDir = fullfile(dataFolder, subjectID, sessionID, [subjectID, '.diffusionResults'], [subjectID '_freesurfer']);
    if ~isfolder(surfDir)
        system(['recon-all -all -subject ' subjectID '_freesurfer' ' -i ' T1w ' -T2 ' T2w ' -T2pial -sd ' fullfile(dataFolder, subjectID, sessionID, [subjectID, '.diffusionResults'])]);
    end

    % Run 5ttgen
    tsegments = fullfile(dataFolder, subjectID, sessionID, [subjectID, '.diffusionResults'], 'preprocessed', 'segmented5Tissues.mif');
    if ~isfile(tsegments)
        system(['5ttgen hsvs -nthreads 10 -white_stem ' surfDir ' ' tsegments]);
    end

    % Convert freesurfer labels
    aparc_aseg = fullfile(dataFolder, subjectID, sessionID, [subjectID, '.diffusionResults'], [subjectID, '_freesurfer'], 'mri', 'aparc+aseg.mgz');
    colorLUT = fullfile(getenv('FREESURFER_HOME'), 'FreeSurferColorLUT.txt');
    fsdefault_trix = '/home/chenlab-linux/mrtrix3/share/mrtrix3/labelconvert/fs_default.txt';
    subjectNodes = fullfile(dataFolder, subjectID, sessionID, [subjectID, '.diffusionResults'], 'preprocessed', 'subjectNodes.mif');
    if ~isfile(subjectNodes)
        system(['labelconvert ' aparc_aseg ' ' colorLUT ' ' fsdefault_trix ' ' subjectNodes])
    end

    % Replace subcortical regions with fsl fast regions. Give norm.mgz as
    % the input as this is used in the hsvs processing to avoid any
    % inconsistencies due to any interpolation.
    norm_T1 = fullfile(dataFolder, subjectID, sessionID, [subjectID, '.diffusionResults'], [subjectID, '_freesurfer'], 'mri', 'norm.mgz');
    subjectNodes_gmFixed = fullfile(dataFolder, subjectID, sessionID, [subjectID, '.diffusionResults'], 'preprocessed', 'subjectNodes_gmFixed.mif');
    system(['labelsgmfix ' subjectNodes ' ' norm_T1 ' ' fsdefault_trix ' ' subjectNodes_gmFixed ' -premasked']);
end