function preprocessDiffusion_bto(dataFolder, subjectID, sessionID)

    % % Create a folder for the analysis 
    analysisFolder = fullfile(dataFolder, subjectID, sessionID, [subjectID '.diffusionResults_bto']);
    if ~isfolder(analysisFolder)
        mkdir(analysisFolder)
    end
    % Create a subdirectory workdirs 
    preprocessedResults = fullfile(analysisFolder, 'preprocessed');
    if ~isfolder(preprocessedResults)
        mkdir(preprocessedResults)
    end  
    intermediateFiles = fullfile(preprocessedResults, 'intermediateFiles');
    if ~isfolder(intermediateFiles)
        mkdir(intermediateFiles)
    end   
    registrationsFolder = fullfile(preprocessedResults, 'registrations');
     if ~isfolder(registrationsFolder)
        mkdir(registrationsFolder)
    end     

    % Get the input names
    dwiFolder = fullfile(dataFolder, subjectID, sessionID, 'dwi');
    TWHAP = fullfile(dwiFolder, [subjectID, '_' sessionID '_acq-TWHprotocoldir64_dir-AP_dwi.nii.gz']);
    TWHAP_bval = fullfile(dwiFolder, [subjectID, '_' sessionID '_acq-TWHprotocoldir64_dir-AP_dwi.bval']);
    TWHAP_bvec = fullfile(dwiFolder, [subjectID, '_' sessionID '_acq-TWHprotocoldir64_dir-AP_dwi.bvec']);

    TWHPA = fullfile(dwiFolder, [subjectID, '_' sessionID '_acq-TWHprotocoldir64_dir-PA_dwi.nii.gz']);
    TWHPA_bval = fullfile(dwiFolder, [subjectID, '_' sessionID '_acq-TWHprotocoldir64_dir-PA_dwi.bval']);
    TWHPA_bvec = fullfile(dwiFolder, [subjectID, '_' sessionID '_acq-TWHprotocoldir64_dir-PA_dwi.bvec']);

    % Put them into empty cell for looping
    data = {TWHAP, TWHPA};
    bvals = {TWHAP_bval, TWHPA_bval};
    bvecs = {TWHAP_bvec, TWHPA_bvec};

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
        system(['mrdegibbs ' denoised ' ' unringed ' -axes 0,1 -nthreads 12']);

        % Append paths to MP denoised cell
        dataMPdenoised{ii} = unringed;
    end

    % Concatanate AP-PA pairs
    combinedDWI = fullfile(intermediateFiles, 'combinedDWI.mif'); 
    system(['mrcat ' dataMPdenoised{1} ' ' dataMPdenoised{2} ' ' combinedDWI ' -axis 3']);

    % Pass it to FSL preprocessing and ants bias correction
    fslCorrectedDWI = fullfile(intermediateFiles, 'fslCorrectedDWI.mif');
    eddyQC = fullfile(intermediateFiles, 'eddyQC');
    if ~isfolder(eddyQC)
        mkdir(eddyQC)
    end
    cleanDWI = fullfile(preprocessedResults, 'cleanDWI.mif');
    system(['dwifslpreproc ' combinedDWI ' ' fslCorrectedDWI ' -pe_dir AP -rpe_all -readout_time 0.0713887 -eddyqc_all ' eddyQC ' -nthreads 12 -topup_options " --nthr=12 " -eddy_options " --slm=linear --repol "']);
    bias = fullfile(intermediateFiles, 'biasfield.mif');
    system(['dwibiascorrect ants ' fslCorrectedDWI ' ' cleanDWI ' -bias ' bias]);

    % Calculate multi-shell, multi-tissue response function. Happens before
    % upscaling.
    wmResponse = fullfile(preprocessedResults, 'wmResponse.txt');
    gmResponse = fullfile(preprocessedResults, 'gmResponse.txt');
    csfResponse = fullfile(preprocessedResults, 'csfResponse.txt');    
    responseVoxelSelection = fullfile(intermediateFiles, 'responseVoxelSelection.mif');
    system(['dwi2response dhollander -nthreads 12 ' cleanDWI ' ' wmResponse ' ' gmResponse ' ' csfResponse ' -voxels ' responseVoxelSelection]);

    % Now upscale the cleaned image
    upscaledCleanDWI = fullfile(preprocessedResults, 'upscaledCleanDWI.mif');
    system(['mrgrid ' cleanDWI ' regrid -vox 1.25 ' upscaledCleanDWI]);

    % Create a whole brain mask from upscaled images. Provide a dilated
    % version as well since it's good for maps. The standard version will
    % be relevant for mtnormalise as that is sensitive to non brain voxels.
    mask = fullfile(preprocessedResults, 'mask.mif');
    upscaledMask = fullfile(preprocessedResults, 'upscaledMask.mif');
    upscaledMaskDilated = fullfile(preprocessedResults, 'upscaledMaskDilated.mif');
    system(['dwi2mask ' cleanDWI ' ' mask]);
    system(['dwi2mask ' upscaledCleanDWI ' ' upscaledMask]);
    system(['maskfilter ' upscaledMask ' dilate -npass 2 ' upscaledMaskDilated]);

    % Register T1 to T2. Use DEOBLIQUED bias corrected version from the
    % cerebellar workdir
    cerebellarWorkdir = fullfile(dataFolder, subjectID, sessionID, [subjectID '.results'], 'cerebellarTarget', 'workdir');
    T1Image = fullfile(cerebellarWorkdir, 'T1.nii');

    % Register first volume of DWI to T1 image
    singleVolDWI = fullfile(intermediateFiles, 'singleVolDWI.nii.gz');
    system(['mrconvert ' upscaledCleanDWI ' -coord 3 0 -axes 0,1,2 ' singleVolDWI]);
    system(['antsRegistrationSyN.sh -m ' singleVolDWI ' -f ' T1Image ' -t r -n 12 -o ' fullfile(registrationsFolder, 'dwi2T1')]);
    DWItoT1Affine = fullfile(registrationsFolder, 'dwi2T10GenericAffine.mat');

    % Apply the inverse of DWI to T1 to anatomicals so that we get them in
    % the DWI space. For T2, also add the affine matrix from T1-T2
    % registration
    T1InDWI = fullfile(preprocessedResults, 'T1InDWI.nii.gz');
    system(['antsApplyTransforms -i ' T1Image ' -r ' T1Image ' -o ' T1InDWI ' -t [ ' DWItoT1Affine ',1 ]']);
   
end