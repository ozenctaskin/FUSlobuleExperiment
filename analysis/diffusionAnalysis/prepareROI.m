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

    % Convert freesurfer labels, exclude putamen, caudate, and pallidum
    aparc_aseg = fullfile(dataFolder, subjectID, sessionID, [subjectID, '.diffusionResults'], [subjectID, '_freesurfer'], 'mri', 'aparc+aseg.mgz');
    colorLUT = fullfile(getenv('FREESURFER_HOME'), 'FreeSurferColorLUT.txt');
    fsdefault_trix = '/home/chenlab-linux/Documents/MATLAB/projects/FUSlobuleExperiment/analysis/diffusionAnalysis/atlas_conversion/fs_default_modified.txt';
    subjectNodes = fullfile(dataFolder, subjectID, sessionID, [subjectID, '.diffusionResults'], 'preprocessed', 'subjectNodes.mif');
    if ~isfile(subjectNodes)
        system(['labelconvert ' aparc_aseg ' ' colorLUT ' ' fsdefault_trix ' ' subjectNodes])
    end

    % Replace subcortical regions with fsl fast regions. Give norm.mgz as
    % the input as this is used in the hsvs processing to avoid any
    % inconsistencies due to any interpolation. We removed basal ganglia
    % before so this is just thalamus
    norm_T1 = fullfile(dataFolder, subjectID, sessionID, [subjectID, '.diffusionResults'], [subjectID, '_freesurfer'], 'mri', 'norm.mgz');
    subjectNodes_gmFixed = fullfile(dataFolder, subjectID, sessionID, [subjectID, '.diffusionResults'], 'preprocessed', 'subjectNodes_gmFixed.mif');
    if ~isfile(subjectNodes_gmFixed)
        system(['labelsgmfix ' subjectNodes ' ' norm_T1 ' ' fsdefault_trix ' ' subjectNodes_gmFixed ' -premasked']);
    end

    % Register to CITI168 to get subcortical regions in
    citiAtlas = '/home/chenlab-linux/Documents/MATLAB/projects/FUSlobuleExperiment/analysis/diffusionAnalysis/CIT168_atlas/CIT168_T1w_head_700um.nii.gz';
    labels = '/home/chenlab-linux/Documents/MATLAB/projects/FUSlobuleExperiment/analysis/diffusionAnalysis/CIT168_atlas/labels.nii.gz';
    registeredLabels = fullfile(dataFolder, subjectID, sessionID, [subjectID, '.diffusionResults'], 'preprocessed', 'registrations', 'registeredSubcorticalLabels.nii.gz');
    genericAffine = fullfile(dataFolder, subjectID, sessionID, [subjectID, '.diffusionResults'], 'preprocessed', 'registrations', 'T1dwi2CIT1680GenericAffine.mat');
    inverseWarp = fullfile(dataFolder, subjectID, sessionID, [subjectID, '.diffusionResults'], 'preprocessed', 'registrations', 'T1dwi2CIT1681InverseWarp.nii.gz');
    if ~isfile(genericAffine)
        system(['antsRegistrationSyN.sh -m ' norm_T1 ' -f ' citiAtlas ' -n 10 -o ' fullfile(dataFolder, subjectID, sessionID, [subjectID, '.diffusionResults'], 'preprocessed', 'registrations', 'T1dwi2CIT168')]);
    end
    if ~isfile(registeredLabels)
        system(['antsApplyTransforms -i ' labels ' -r ' norm_T1 ' -o ' registeredLabels ' -n NearestNeighbor -t ' inverseWarp ' -t [ ' genericAffine ' ,1 ]']);
    end
end