function prepareROI(dataFolder, subjectID, sessionID, freesurferType)
    
    % Add required functions
    homeVar = getenv('HOME');
    addpath(genpath(fullfile(homeVar, 'Documents', 'MATLAB', 'toolboxes', 'freesurferMatlabLibrary')));
    addpath(genpath(fullfile(homeVar, 'Documents', 'MATLAB', 'toolboxes', 'spm12')))
    suit_defaults();
    spm('Defaults','fMRI');
    spm_jobman('initcfg');
    currentPath = fileparts(matlab.desktop.editor.getActiveFilename);

    % Get T1 and registered T2 from the functional analysis folder
    cerebellarWorkdir = fullfile(dataFolder, subjectID, sessionID, [subjectID '.results'], 'cerebellarTarget', 'workdir');
    T1Image = fullfile(cerebellarWorkdir, 'T1.nii');
    T2Image = fullfile(cerebellarWorkdir, 'T2registeredWarped.nii');

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
        if strcmp(freesurferType, 'local')
            system(['recon-all -subjid ' subjectID '_freesurfer -i ' T1Image ' -T2 ' T2Image ' -T2pial -sd ' ROIfolder ' -all']);
        elseif strcmp(freesurferType, 'docker')
            [~, T1name, T1ext] = fileparts(T1Image);
            [~, T2name, T2ext] = fileparts(T2Image);
            system(['docker run -it --rm -v ' T1Image ':/anat/' [T1name,T1ext] ' -v ' T2Image ':/anat/' [T2name,T2ext] ' -v ' ROIfolder ':/subjects freesurfer:latest recon-all -i ' fullfile('/anat', [T1name,T1ext]) ' -T2 ' fullfile('/anat', [T2name,T2ext]) ' -T2pial -sd /subjects -s ' subjectID '_freesurfer' ' -all']);
            system(['docker run --rm -v ' ROIfolder ':/subjects alpine chmod -R a+rwX /subjects']);
        else
            error('Freesurfer type not recognized. Enter local or docker')
        end
    end

    % Run 5ttgen
    tsegments = fullfile(intermediateFiles, 'segmented5Tissues.mif');
    if ~isfile(tsegments)
        system(['5ttgen hsvs -nthreads 13 -white_stem ' surfDir ' ' tsegments]);
    end

    % Convert freesurfer labels, exclude putamen, caudate, and pallidum
    aparc_aseg = fullfile(surfDir, 'mri', 'aparc+aseg.mgz');
    colorLUT = fullfile(getenv('FREESURFER_HOME'), 'FreeSurferColorLUT.txt');
    fsdefault_trix = fullfile(currentPath, 'atlas_conversion', 'fs_default_modified.txt');
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
    citiAtlas = fullfile(currentPath, 'CIT168_atlas', 'CIT168_T1w_head_700um.nii.gz');
    labels = fullfile(currentPath, 'CIT168_atlas', 'labels.nii.gz');
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
    subjectNodes_subcortAdded = fullfile(intermediateFiles, 'labels.mif');
    if ~isfile(subjectNodes_subcortAdded)
        system(['mrcalc ' subjectNodes_gmFixed ' ' registeredLabels ' -add ' subjectNodes_subcortAdded]);
        system(['mrcalc ' subjectNodes_subcortAdded ' 113 35 -replace ' subjectNodes_subcortAdded ' -force']);
        system(['mrcalc ' subjectNodes_subcortAdded ' 124 38 -replace ' subjectNodes_subcortAdded ' -force']);
    end

    % Convert the labels to nifti and map back to native space from
    % freesurfer space
    subjectNodes_subcortAdded_nifti = fullfile(intermediateFiles, 'labels.nii.gz');
    if ~isfile(subjectNodes_subcortAdded_nifti)
        system(['mrconvert ' subjectNodes_subcortAdded ' ' subjectNodes_subcortAdded_nifti]);
    end
    rawAvg = fullfile(surfDir, 'mri', 'rawavg.mgz');
    subjectNodes_subcortAdded_native = fullfile(intermediateFiles, 'labels_native.nii.gz');
    if ~isfile(subjectNodes_subcortAdded_native)
        system(['mri_label2vol --seg ' subjectNodes_subcortAdded_nifti ' --temp ' rawAvg ' --o ' subjectNodes_subcortAdded_native ' --regheader ' aparc_aseg]);
    end

    % Register cerebellar structures to anatomy. Use calculations we make
    % during the functional analysis
    cerebellarParc = fullfile(intermediateFiles, 'combinedAtlas.nii');
    cerebellarAffine = fullfile(intermediateFiles, 'Affine_T1_seg1.mat');
    cerebellarFlow = fullfile(intermediateFiles, 'u_a_T1_seg1.nii');
    system(['cp ' fullfile(currentPath, 'cerebellarAtlas_DiedrichsenNettekoven', 'combinedAtlas.nii') ' ' intermediateFiles]);
    system(['cp ' fullfile(cerebellarWorkdir, 'Affine_T1_seg1.mat') ' ' intermediateFiles]);
    system(['cp ' fullfile(cerebellarWorkdir, 'u_a_T1_seg1.nii') ' ' intermediateFiles]);

    cerebellarParc_native = fullfile(intermediateFiles, 'iw_combinedAtlas_u_a_T1_seg1.nii');
    if ~isfile(cerebellarParc_native)
        job = [];
        job.Affine = {cerebellarAffine};
        job.flowfield = {cerebellarFlow};
        job.resample = {cerebellarParc};
        job.ref = {T1Image};
        suit_reslice_dartel_inv(job);
    end
    system(['mrcalc -force ' cerebellarParc_native ' -finite ' cerebellarParc_native ' 0.0 -if ' cerebellarParc_native]);

    % Mask the cerebellar cortex with a cerebellar mask so that
    % we don't have any overlap between cortical and cerebellar regions
    cerebellumMask = fullfile(intermediateFiles, 'cerebellarMask.nii.gz');
    system(['mri_extract_label ' aparc_aseg ' 7 8 46 47 ' cerebellumMask]);
    system(['fslmaths ' cerebellumMask ' -thr 1 -bin ' cerebellumMask]);
    system(['mrcalc -force ' cerebellarParc_native ' ' cerebellumMask ' -mult ' cerebellarParc_native]);

    % Add cerebellar parcellations to the final label set
    finalLabels = fullfile(ROIfolder, 'finalLabels.nii.gz');
    if ~isfile(finalLabels)
        system(['mrcalc ' subjectNodes_subcortAdded_native ' ' cerebellarParc_native ' -add ' finalLabels]);
        system(['fslmaths ' finalLabels ' -uthr 100 ' finalLabels]);
    end

    % Convert 5-tissue segments to native anatomical space  
    tsegments_nifti = fullfile(intermediateFiles, 'segmented5Tissues.nii.gz');
    system(['mrconvert ' tsegments ' ' tsegments_nifti]);
    tsegments_natived = fullfile(intermediateFiles, 'segmented5Tissues_native.nii.gz');
    if ~isfile(tsegments_natived)
        system(['mri_vol2vol --mov ' tsegments_nifti ' --targ ' rawAvg ' --o ' tsegments_natived ' --regheader --no-save-reg']);
    end

    % Add cerebellar nuclei to the 5t gray matter mask and threshold to get
    % rid of the overlapping regions use 5ttedit
    cerebellarNuclei = fullfile(intermediateFiles, 'cerebellarNuclei.nii.gz');
    if ~isfile(cerebellarNuclei)
        system(['mri_extract_label ' finalLabels ' 91 92 93 96 97 98 ' cerebellarNuclei]);
        system(['fslmaths ' cerebellarNuclei ' -thr 1 -bin ' cerebellarNuclei]);
    end
    
    cerebellarGrayMatter = fullfile(intermediateFiles, 'cerebellarGM.nii.gz');
    if ~isfile(cerebellarGrayMatter)
        system(['fslroi ' tsegments_natived ' ' cerebellarGrayMatter ' 1 1']);
        system(['fslmaths ' cerebellarGrayMatter ' -add ' cerebellarNuclei ' ' cerebellarGrayMatter]);
        system(['mrcalc -force ' cerebellarGrayMatter ' 1 -min ' cerebellarGrayMatter]);
    end

    finalSegmentations = fullfile(ROIfolder, 'segmented5Tissues_native_final.nii.gz');
    if ~isfile(finalSegmentations)
        system(['5ttedit -force -sgm ' cerebellarGrayMatter ' ' tsegments_natived ' ' finalSegmentations]);
    end
end