function prepareROI(dataFolder, subjectID, sessionID)
    
    % Add required functions
    addpath(genpath('/home/chenlab-linux/Documents/MATLAB/toolboxes/freesurferMatlabLibrary'));
    addpath(genpath('/home/chenlab-linux/Documents/MATLAB/toolboxes/spm12'))
    suit_defaults();
    spm('Defaults','fMRI');
    spm_jobman('initcfg');

    % Main paths
    T1Image = fullfile(dataFolder, subjectID, sessionID, 'anat', [subjectID '_' sessionID '_acq-btoMPRAGE2x11mmisoDEOBLIQUED_T1w.nii.gz']);
    T2Image = fullfile(dataFolder, subjectID, sessionID, 'anat', [subjectID '_' sessionID '_acq-btoSPACET22x2CAIPI1mmisoDEOBLIQUED_T2w.nii.gz']);

    % Create folders
    ROIfolder = fullfile(dataFolder, subjectID, sessionID, [subjectID '.ROI']);
    intermediateFiles = fullfile(ROIfolder, 'intermediateFiles');
    if ~isfolder(ROIfolder)
        mkdir(ROIfolder);
    end    
    if ~isfolder(intermediateFiles)
        mkdir(intermediateFiles);
    end  

    % Run freesurfer
    surfDir = fullfile(ROIfolder, [subjectID '_freesurfer']);
    if ~isfolder(surfDir)
        system(['recon-all -all -subject ' subjectID '_freesurfer' ' -i ' T1Image ' -T2 ' T2Image ' -T2pial -sd ' ROIfolder]);
    end

    % Run 5ttgen
    tsegments = fullfile(ROIfolder, 'segmented5Tissues.mif');
    if ~isfile(tsegments)
        system(['5ttgen hsvs -nthreads 10 -white_stem ' surfDir ' ' tsegments]);
    end

    % Convert freesurfer labels, exclude putamen, caudate, and pallidum
    aparc_aseg = fullfile(surfDir, 'mri', 'aparc+aseg.mgz');
    colorLUT = fullfile(getenv('FREESURFER_HOME'), 'FreeSurferColorLUT.txt');
    fsdefault_trix = '/home/chenlab-linux/Documents/MATLAB/projects/FUSlobuleExperiment/analysis/diffusionAnalysis/atlas_conversion/fs_default_modified.txt';
    subjectNodes = fullfile(intermediateFiles, 'subjectNodes.mif');
    if ~isfile(subjectNodes)
        system(['labelconvert ' aparc_aseg ' ' colorLUT ' ' fsdefault_trix ' ' subjectNodes])
    end

    % Replace subcortical regions with fsl fast regions. Give norm.mgz as
    % the input as this is used in the hsvs processing to avoid any
    % inconsistencies due to any interpolation. We removed basal ganglia
    % before so this is just thalamus
    norm_T1 = fullfile(surfDir, 'mri', 'norm.mgz');
    subjectNodes_gmFixed = fullfile(intermediateFiles, 'subjectNodes_gmFixed.mif');
    if ~isfile(subjectNodes_gmFixed)
        system(['labelsgmfix ' subjectNodes ' ' norm_T1 ' ' fsdefault_trix ' ' subjectNodes_gmFixed ' -premasked']);
    end

    % Register to CITI168 to get subcortical regions. Use nu.mgz as we need
    % the skull for the registration.
    nu_T1 = fullfile(surfDir, 'mri', 'nu.mgz');
    citiAtlas = '/home/chenlab-linux/Documents/MATLAB/projects/FUSlobuleExperiment/analysis/diffusionAnalysis/CIT168_atlas/CIT168_T1w_head_700um.nii.gz';
    labels = '/home/chenlab-linux/Documents/MATLAB/projects/FUSlobuleExperiment/analysis/diffusionAnalysis/CIT168_atlas/labels.nii.gz';
    registeredLabels = fullfile(intermediateFiles, 'registeredSubcorticalLabels.nii.gz');
    genericAffine = fullfile(intermediateFiles, 'T1dwi2CIT1680GenericAffine.mat');
    inverseWarp = fullfile(intermediateFiles, 'T1dwi2CIT1681InverseWarp.nii.gz');
    if ~isfile(genericAffine)
        system(['antsRegistrationSyN.sh -m ' nu_T1 ' -f ' citiAtlas ' -n 10 -o ' fullfile(intermediateFiles, 'T1dwi2CIT168')]);
    end
    if ~isfile(registeredLabels)
        system(['antsApplyTransforms -i ' labels ' -r ' nu_T1 ' -o ' registeredLabels ' -n NearestNeighbor -t ' inverseWarp ' -t [ ' genericAffine ' ,1 ]']);
    end

    % Add these regions to aparc+aseg parcellations and handle overlapping
    % thalamus - caudate
    finalLabels = fullfile(intermediateFiles, 'labels.mif');
    if ~isfile(finalLabels)
        system(['mrcalc ' subjectNodes_gmFixed ' ' registeredLabels ' -add ' finalLabels]);
        system(['mrcalc ' finalLabels ' 113 35 -replace ' finalLabels ' -force']);
        system(['mrcalc ' finalLabels ' 124 38 -replace ' finalLabels ' -force']);
    end

    % Register cerebellar structures to anatomy.
    cerebellarParc = '/home/chenlab-linux/Documents/MATLAB/projects/FUSlobuleExperiment/analysis/diffusionAnalysis/cerebellarAtlas_DiedrichsenNettekoven/combinedAtlas.nii';
    extractedT1 = fullfile(intermediateFiles, 'T1InDWI.nii');
    extractedT2 = fullfile(intermediateFiles, 'T2InDWI.nii');
    if ~isfile(extractedT1)
        system(['gunzip -c ' T1w ' > ' extractedT1]);
    end
    if ~isfile(extractedT2)
        system(['gunzip -c ' T2w ' > ' extractedT2]);
    end

    anatomy = {extractedT1, extractedT2};
    [filePath, fileName, ~] = fileparts(anatomy{1});
    job.subjND.gray = {fullfile(filePath, [fileName '_seg1.nii'])};
    job.subjND.white = {fullfile(filePath, [fileName '_seg2.nii'])};
    job.subjND.isolation = {fullfile(filePath, ['c_' fileName '_pcereb.nii'])};
    if ~isfile(job.subjND.gray{1}) || ~isfile(job.subjND.white{1}) || ~isfile(job.subjND.isolation{1})
        suit_isolate_seg(anatomy);
    end
    suit_normalize_dartel(job);

    job = [];
    job.Affine = {fullfile(filePath, ['Affine_' fileName '_seg1.mat'])};
    job.flowfield = {fullfile(filePath, ['u_a_' fileName '_seg1.nii'])};
    job.resample = {cerebellarParc};
    job.ref = {extractedT1};
    suit_reslice_dartel_inv(job);
end