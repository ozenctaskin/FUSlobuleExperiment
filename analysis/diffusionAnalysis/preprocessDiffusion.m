function preprocessDiffusion(dataFolder, subjectID, sessionID)

    % Create a folder for the analysis 
    analysisFolder = fullfile(dataFolder, subjectID, sessionID, [subjectID '.diffusionResults']);
    if ~isfolder(analysisFolder)
        mkdir(analysisFolder)
    end

    % Create a subdirectory workdirs 
    workdir = fullfile(analysisFolder, 'intermediateFiles');
    if ~isfolder(workdir)
        mkdir(workdir)
    end   
    mifFolder = fullfile(workdir, '01-mifConverted');
    if ~isfolder(mifFolder)
        mkdir(mifFolder)
    end  
    denoisedFolder = fullfile(workdir, '02-denoised');
    if ~isfolder(denoisedFolder)
        mkdir(denoisedFolder)
    end  
    dirCombined = fullfile(workdir, '03-dirCombined');
    if ~isfolder(dirCombined)
        mkdir(dirCombined)
    end  
    preprocessedFolder = fullfile(workdir, '04-preprocessed');
    if ~isfolder(preprocessedFolder)
        mkdir(preprocessedFolder)
    end  
    dtiFolder = fullfile(workdir, '05-dti');
    if ~isfolder(dtiFolder)
        mkdir(dtiFolder)
    end  
    anatProcess = fullfile(workdir, '06-anat');
    if ~isfolder(anatProcess)
        mkdir(anatProcess)
    end  
    subjectFod = fullfile(workdir, '07-subjectFOD_withOwnResponseFun');
    if ~isfolder(subjectFod)
        mkdir(subjectFod)
    end  
    subjectTractography = fullfile(workdir, '08-subjectTractography');
    if ~isfolder(subjectTractography)
        mkdir(subjectTractography)
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
        mif = fullfile(mifFolder, replace(name, '.nii', '.mif'));
        % system(['mrconvert -fslgrad ' bvecs{ii} ' ' bvals{ii} ' ' data{ii} ' ' mif]);

        % Do denoising with MP-PCA, and calculate residuals
        denoised = fullfile(denoisedFolder, replace(name, {'.nii', 'dir-'}, {'.mif', 'rec-denoised_dir-'}));
        noise = fullfile(denoisedFolder, replace(name, {'.nii', 'dir-'}, {'.mif', 'rec-noise_dir-'}));
        residuals = fullfile(denoisedFolder, replace(name, {'.nii', 'dir-'}, {'.mif', 'rec-residuals_dir-'}));
        % system(['dwidenoise ' mif ' ' denoised ' -noise ' noise ' -nthreads 12']);
        % system(['mrcalc ' mif ' ' denoised ' -subtract ' residuals]);

        % Perform gibbs ringing correction
        unringed = strrep(denoised, 'rec-denoised', 'rec-denoisedUnringed');
        % system(['mrdegibbs ' denoised ' ' unringed ' -axes 0,1 -nthreads 12'])

        % Append paths to MP denoised cell
        dataMPdenoised{ii} = unringed;
    end

    % Combine 99 and 98 directions; AP with AP, PA with PA
    APdiff = fullfile(dirCombined, 'AP_all_data.mif'); 
    PAdiff = fullfile(dirCombined, 'PA_all_data.mif');
    % system(['dwicat ' dataMPdenoised{1} ' ' dataMPdenoised{3} ' ' APdiff]);
    % system(['dwicat ' dataMPdenoised{2} ' ' dataMPdenoised{4} ' ' PAdiff]);

    % Concatanate AP-PA pairs
    combined = fullfile(dirCombined, 'combinedDWI.mif'); 
    % system(['mrcat ' APdiff ' ' PAdiff ' ' combined ' -axis 3']);
    
    % Pass it to preprocessing, %% CUDA VERSION NOT WORKING FOR SOME REASON - FIX!! 
    preprocessedImage = fullfile(preprocessedFolder, 'clean_dwi.mif');
    % system(['dwifslpreproc ' combined ' ' preprocessedImage ' -pe_dir AP -rpe_all -readout_time 0.0959097 -eddy_options " --nthr=12 " -nthreads 12 -topup_options " --nthr=12 " ']);

    % Calculate multi-shell, multi-tissue response function. Happens before
    % upscaling.
    wmResponse = fullfile(preprocessedFolder, 'wm_response.txt');
    gmResponse = fullfile(preprocessedFolder, 'gm_response.txt');
    csfResponse = fullfile(preprocessedFolder, 'csf_response.txt');    
    voxels = fullfile(preprocessedFolder, 'voxels.mif');
    % system(['dwi2response dhollander -nthreads 12 ' preprocessedImage ' ' wmResponse ' ' gmResponse ' ' csfResponse ' -voxels ' voxels]);

    % Now upscale the cleaned image
    upscaled_preprocessedImage = fullfile(preprocessedFolder, 'upscaled_clean_dwi.mif');
    % system(['mrgrid ' preprocessedImage ' regrid -vox 1.25 ' upscaled_preprocessedImage])
    
    % Create a whole brain mask from upscaled images. Provide a dilated
    % version as well since it's good for maps.
    mask = fullfile(preprocessedFolder, 'upscaled_clean_mask.mif');
    maskDilated = fullfile(preprocessedFolder, 'upscaled_clean_mask_dilated.mif');
    % system(['dwi2mask ' upscaled_preprocessedImage ' ' mask]);
    % system(['maskfilter ' mask ' dilate -npass 2 ' maskDilated]);

    % Run DTI. Calculate metrics from the upscaled dilated mask
    dt = fullfile(dtiFolder, 'dt.mif');
    fa = fullfile(dtiFolder, 'fa.mif');
    md = fullfile(dtiFolder, 'md.mif');
    ad = fullfile(dtiFolder, 'ad.mif');
    rd = fullfile(dtiFolder, 'rd.mif');
    % system(['dwi2tensor -mask ' maskDilated ' ' upscaled_preprocessedImage ' ' dt]);
    % system(['tensor2metric -mask ' maskDilated ' -fa ' fa ' -adc ' md ' -ad ' ad ' -rd ' rd ' ' dt]);

    % Perform a rigid registration between preprocessed dwi and anatomical
    % and run 5ttgen tissue segmentation
    anatomical = fullfile(dataFolder, subjectID, sessionID, 'anat', [subjectID '_' sessionID '_acq-btoMPRAGE2x11mmiso_T1w.nii.gz']);
    singleVolDWI = fullfile(anatProcess, 'singleVolDWI.nii.gz');
    % system(['mrconvert ' upscaled_preprocessedImage ' -coord 3 0 -axes 0,1,2 ' singleVolDWI]);
    % system(['antsRegistrationSyN.sh -m ' singleVolDWI ' -f ' anatomical ' -t r -n 12 -o ' fullfile(anatProcess, 'dwi2anat')]);

    registeredAnatomical = fullfile(anatProcess, 'anatInDWI.nii.gz');
    genericAffine = fullfile(anatProcess, 'dwi2anat0GenericAffine.mat');
    % system(['antsApplyTransforms -i ' anatomical ' -r ' anatomical ' -o ' registeredAnatomical ' -t [ ' genericAffine ',1 ]']);
    
    tissueSegments = fullfile(anatProcess, 'segmented5Tissues.mif');
    % system(['5ttgen fsl ' registeredAnatomical ' ' tissueSegments ' -nthreads 12']); % ADD T2 here as well

    % Calculate subject FOD image with own response function. Not to be
    % used for fixel based analysis as we need a group FOD. Use dilated
    % mask. For normalization, use the undilated mask.
    wmFOD = fullfile(subjectFod, 'wm.mif'); wmFOD_norm = fullfile(subjectFod, 'wm_norm.mif');
    gmFOD = fullfile(subjectFod, 'gm.mif'); gmFOD_norm = fullfile(subjectFod, 'gm_norm.mif');
    csfFOD = fullfile(subjectFod, 'csf.mif'); csfFOD_norm = fullfile(subjectFod, 'csf_norm.mif');
    % system(['dwi2fod msmt_csd ' upscaled_preprocessedImage ' ' wmResponse ' ' wmFOD ' ' gmResponse ' ' gmFOD ' ' csfResponse ' ' csfFOD ' -nthreads 12 -mask ' maskDilated]);
    % system(['mtnormalise ' wmFOD ' ' wmFOD_norm ' ' gmFOD ' ' gmFOD_norm ' ' csfFOD ' ' csfFOD_norm ' -mask ' mask]);

    % Calculate whole brain tractography and SIFT. We might want to go up 
    % to 100 million streamlines. ADDD BIAS CORRECTION
    % NECESSARY for SIFT!
    seedGM = fullfile(subjectTractography, 'seedGM.mif');
    wholeBrainTracts = fullfile(subjectTractography, 'wholeBrainTracts.tck');
    wholeBrainTracts_SIFTED = fullfile(subjectTractography, 'wholeBrainTracts_SIFTED.tck');
    system(['5tt2gmwmi ' tissueSegments ' ' seedGM]);
    system(['tckgen -act ' tissueSegments ' -algorithm  Tensor_Prob -minlength 100 -select 5000 -nthreads 12 -seed_gmwmi ' seedGM ' ' upscaled_preprocessedImage ' ' wholeBrainTracts]);
    system(['tcksift ' wholeBrainTracts ' ' wmFOD_norm ' ' wholeBrainTracts_SIFTED]);
end