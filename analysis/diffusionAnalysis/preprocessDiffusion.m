function preprocessDiffusion(dataFolder, subjectID, sessionID)

    % % Create a folder for the analysis 
    analysisFolder = fullfile(dataFolder, subjectID, sessionID, [subjectID '.diffusionResults']);
    if ~isfolder(analysisFolder)
        mkdir(analysisFolder)
    end
    % Create a subdirectory workdirs 
    intermediateFiles = fullfile(analysisFolder, 'intermediateFiles');
    if ~isfolder(intermediateFiles)
        mkdir(intermediateFiles)
    end   
    preprocessedResults = fullfile(analysisFolder, 'preprocessed');
    if ~isfolder(preprocessedResults)
        mkdir(preprocessedResults)
    end  
    registrationsFolder = fullfile(preprocessedResults, 'registrations');
     if ~isfolder(registrationsFolder)
        mkdir(registrationsFolder)
    end     

    % Get the input names
    dwiFolder = fullfile(dataFolder, subjectID, sessionID, 'dwi');
    AP98 = fullfile(dwiFolder, [subjectID, '_' sessionID '_acq-HCPdir98_dir-AP_dwi.nii.gz']);
    AP98_bval = fullfile(dwiFolder, [subjectID, '_' sessionID '_acq-HCPdir98_dir-AP_dwi.bval']);
    AP98_bvec = fullfile(dwiFolder, [subjectID, '_' sessionID '_acq-HCPdir98_dir-AP_dwi.bvec']);

    PA98 = fullfile(dwiFolder, [subjectID, '_' sessionID '_acq-HCPdir98_dir-PA_dwi.nii.gz']);
    PA98_bval = fullfile(dwiFolder, [subjectID, '_' sessionID '_acq-HCPdir98_dir-PA_dwi.bval']);
    PA98_bvec = fullfile(dwiFolder, [subjectID, '_' sessionID '_acq-HCPdir98_dir-PA_dwi.bvec']);

    AP99 = fullfile(dwiFolder, [subjectID, '_' sessionID '_acq-HCPdir99_dir-AP_dwi.nii.gz']);
    AP99_bval = fullfile(dwiFolder, [subjectID, '_' sessionID '_acq-HCPdir99_dir-AP_dwi.bval']);
    AP99_bvec = fullfile(dwiFolder, [subjectID, '_' sessionID '_acq-HCPdir99_dir-AP_dwi.bvec']);

    PA99 = fullfile(dwiFolder, [subjectID, '_' sessionID '_acq-HCPdir99_dir-PA_dwi.nii.gz']);
    PA99_bval = fullfile(dwiFolder, [subjectID, '_' sessionID '_acq-HCPdir99_dir-PA_dwi.bval']);
    PA99_bvec = fullfile(dwiFolder, [subjectID, '_' sessionID '_acq-HCPdir99_dir-PA_dwi.bvec']);    

    % Put them into empty cell for looping
    data = {AP98, PA98, AP99, PA99};
    bvecs = {AP98_bvec, PA98_bvec, AP99_bvec, PA99_bvec};
    bvals = {AP98_bval, PA98_bval, AP99_bval, PA99_bval};

    % Convert to mif and do MP-PCA for each acquired image
    dataMPdenoised = {};
    for ii = 1:length(data)

        % Get data path, name, and ext 
        [path, name, ext] = fileparts(data{ii});

        % Convert data to mif adding bvecs and bvals to headers
        mif = fullfile(intermediateFiles, replace(name, '.nii', '.mif'));
        system(['mrconvert -fslgrad ' bvecs{ii} ' ' bvals{ii} ' ' data{ii} ' ' mif]);

        % Do denoising with MP-PCA, and calculate residuals
        denoised = fullfile(intermediateFiles, replace(name, {'.nii', 'dir-'}, {'.mif', 'rec-denoised_dir-'}));
        noise = fullfile(intermediateFiles, replace(name, {'.nii', 'dir-'}, {'.mif', 'rec-noise_dir-'}));
        residuals = fullfile(intermediateFiles, replace(name, {'.nii', 'dir-'}, {'.mif', 'rec-residuals_dir-'}));
        system(['dwidenoise ' mif ' ' denoised ' -noise ' noise ' -nthreads 5']);
        system(['mrcalc ' mif ' ' denoised ' -subtract ' residuals]);

        % Perform gibbs ringing correction
        unringed = strrep(denoised, 'rec-denoised', 'rec-denoisedUnringed');
        system(['mrdegibbs ' denoised ' ' unringed ' -axes 0,1 -nthreads 12'])

        % Append paths to MP denoised cell
        dataMPdenoised{ii} = unringed;
    end

    % Combine 99 and 98 directions; AP with AP, PA with PA
    APdiff = fullfile(intermediateFiles, 'combinedAP.mif'); 
    PAdiff = fullfile(intermediateFiles, 'combinedPA.mif');
    system(['dwicat ' dataMPdenoised{1} ' ' dataMPdenoised{3} ' ' APdiff]);
    system(['dwicat ' dataMPdenoised{2} ' ' dataMPdenoised{4} ' ' PAdiff]);

    % Concatanate AP-PA pairs
    combinedDWI = fullfile(intermediateFiles, 'combinedDWI.mif'); 
    system(['mrcat ' APdiff ' ' PAdiff ' ' combinedDWI ' -axis 3']);

    % Pass it to FSL preprocessing and ants bias correction
    fslCorrectedDWI = fullfile(intermediateFiles, 'fslCorrectedDWI.mif');
    cleanDWI = fullfile(preprocessedResults, 'cleanDWI.mif');
    system(['dwifslpreproc ' combinedDWI ' ' fslCorrectedDWI ' -pe_dir AP -rpe_all -readout_time 0.0959097 -nthreads 12 -topup_options " --nthr=12 " ']);
    system(['dwibiascorrect ants ' fslCorrectedDWI ' ' cleanDWI]);

    % Calculate multi-shell, multi-tissue response function. Happens before
    % upscaling.
    wmResponse = fullfile(preprocessedResults, 'wmResponse.txt');
    gmResponse = fullfile(preprocessedResults, 'gmResponse.txt');
    csfResponse = fullfile(preprocessedResults, 'csfResponse.txt');    
    responseVoxelSelection = fullfile(intermediateFiles, 'responseVoxelSelection.mif');
    system(['dwi2response dhollander -nthreads 12 ' cleanDWI ' ' wmResponse ' ' gmResponse ' ' csfResponse ' -voxels ' responseVoxelSelection]);

    % Now upscale the cleaned image
    upscaledCleanDWI = fullfile(preprocessedResults, 'upscaledCleanDWI.mif');
    system(['mrgrid ' cleanDWI ' regrid -vox 1.25 ' upscaledCleanDWI])

    % Create a whole brain mask from upscaled images. Provide a dilated
    % version as well since it's good for maps.
    mask = fullfile(preprocessedResults, 'mask.mif');
    upscaledMask = fullfile(preprocessedResults, 'upscaledMask.mif');
    upscaledMaskDilated = fullfile(preprocessedResults, 'upscaledMaskDilated.mif');
    system(['dwi2mask ' cleanDWI ' ' mask]);
    system(['dwi2mask ' upscaledCleanDWI ' ' upscaledMask]);
    system(['maskfilter ' upscaledMask ' dilate -npass 2 ' upscaledMaskDilated]);

    % Register T1 to T2. Use DEOBLIQUED
    T1Image = fullfile(dataFolder, subjectID, sessionID, 'anat', [subjectID '_' sessionID '_acq-btoMPRAGE2x11mmisoDEOBLIQUED_T1w.nii.gz']);
    T2Image = fullfile(dataFolder, subjectID, sessionID, 'anat', [subjectID '_' sessionID '_acq-btoSPACET22x2CAIPI1mmisoDEOBLIQUED_T2w.nii.gz']);
    system(['antsRegistrationSyN.sh -m ' T2Image ' -f ' T1Image ' -t r -n 12 -o ' fullfile(registrationsFolder, 'T2inT1')]);
    T2inT1 = fullfile(registrationsFolder, 'T2inT1Warped.nii.gz');
    T2inT1Affine = fullfile(registrationsFolder, 'T2inT10GenericAffine.mat');

    % Register first volume of DWI to T1 image
    singleVolDWI = fullfile(intermediateFiles, 'singleVolDWI.nii.gz');
    system(['mrconvert ' upscaledCleanDWI ' -coord 3 0 -axes 0,1,2 ' singleVolDWI]);
    system(['antsRegistrationSyN.sh -m ' singleVolDWI ' -f ' T1Image ' -t r -n 12 -o ' fullfile(registrationsFolder, 'dwi2T1')]);
    DWItoT1Affine = fullfile(registrationsFolder, 'dwi2T10GenericAffine.mat');

    % Apply the inverse of DWI to T1 to anatomicals so that we get them in
    % the DWI space. For T2, also add the affine matrix from T1-T2
    % registration
    T1InDWI = fullfile(preprocessedResults, 'T1InDWI.nii.gz');
    T2InDWI = fullfile(preprocessedResults, 'T2InDWI.nii.gz');
    system(['antsApplyTransforms -i ' T1Image ' -r ' T1Image ' -o ' T1InDWI ' -t [ ' DWItoT1Affine ',1 ]']);
    system(['antsApplyTransforms -i ' T2Image ' -r ' T1Image ' -o ' T2InDWI ' -t [ ' DWItoT1Affine ',1 ]' ' -t [ ' T2inT1Affine ',0 ]']);
    
    % Do a 5ttgen segmentation
    tissueSegments = fullfile(preprocessedResults, 'segmented5Tissues.mif');
    system(['5ttgen fsl ' T1InDWI ' ' tissueSegments ' -nthreads 12 -t2 ' T2InDWI]);
end