function subjectTractography(dataFolder, subjectID, sessionID)

    % Create the output folder
    analysisFolder = fullfile(dataFolder, subjectID, sessionID, [subjectID '.diffusionResults']);
    subjectTractographyFolder = fullfile(analysisFolder, 'subjectTractography');
    intermediateFiles = fullfile(subjectTractographyFolder, 'intermediateFiles');
    if ~isfolder(subjectTractographyFolder)
        mkdir(subjectTractographyFolder)
    end
    if ~isfolder(intermediateFiles)
        mkdir(intermediateFiles)
    end

    % Get the cleaned diffusion images and response functions
    preprocessedResults = fullfile(analysisFolder, 'preprocessed');
    upscaledCleanDWI = fullfile(preprocessedResults, 'upscaledCleanDWI.mif');
    upscaledMask = fullfile(preprocessedResults, 'upscaledMask.mif');
    upscaledMaskDilated = fullfile(preprocessedResults, 'upscaledMaskDilated.mif');
    wmResponse = fullfile(dataFolder, 'wmAverageResponse.txt');
    gmResponse = fullfile(dataFolder, 'gmAverageResponse.txt');
    csfResponse = fullfile(dataFolder, 'csfAverageResponse.txt');

    % Register 5-tissue segments to DWI
    ROIfolder = fullfile(dataFolder, subjectID, sessionID, [subjectID '.ROI']);
    tsegments_native = fullfile(ROIfolder, 'segmented5Tissues_native_final.nii.gz');
    upscaledCleanDWI_single = fullfile(intermediateFiles, 'upscaledCleanDWI_single.nii.gz');
    system(['mrconvert ' upscaledCleanDWI ' -coord 3 0 ' upscaledCleanDWI_single]);
    DWItoT1affine = fullfile(preprocessedResults, 'registrations', 'dwi2T10GenericAffine.mat');
    tsegments_registered = fullfile(intermediateFiles, 'segmented5Tissues_in_DWI.nii.gz');
    system(['antsApplyTransforms -e 3 -i ' tsegments_native ' -r ' upscaledCleanDWI_single ' -t [ ' DWItoT1affine ',1 ] -o ' tsegments_registered]);

    % Create FOD
    wmFOD = fullfile(subjectTractographyFolder, 'subject_wmFOD.mif');
    gmFOD = fullfile(subjectTractographyFolder, 'subject_gmFOD.mif');
    csfFOD = fullfile(subjectTractographyFolder, 'subject_csfFOD.mif');
    system(['dwi2fod msmt_csd -nthreads 5 ' upscaledCleanDWI ' -mask ' upscaledMaskDilated ' ' wmResponse ' ' wmFOD ' ' gmResponse ' ' gmFOD ' ' csfResponse ' ' csfFOD]);

    % Normalize FOD
    wmFOD_norm = fullfile(subjectTractographyFolder, 'subject_wmFOD_norm.mif');
    gmFOD_norm = fullfile(subjectTractographyFolder, 'subject_gmFOD_norm.mif');
    csfFOD_norm = fullfile(subjectTractographyFolder, 'subject_csfFOD_norm.mif');    
    system(['mtnormalise ' wmFOD ' ' wmFOD_norm ' ' gmFOD ' ' gmFOD_norm ' ' csfFOD ' ' csfFOD_norm ' -mask ' upscaledMask]);

    % Run tractography. 10 million tracks
    tractogram = fullfile(subjectTractographyFolder, 'tractogram_70M.tck');
    if ~isfile(tractogram)
        system(['tckgen -act ' tsegments_registered ' -backtrack -crop_at_gmwmi -cutoff 0.06 -maxlength 250 -nthreads 6 -select 70M -seed_dynamic ' wmFOD_norm ' ' wmFOD_norm ' ' tractogram]);
    end

    % SIFT2
    siftWeights = fullfile(subjectTractographyFolder, 'sift_weights.csv');
    siftMu = fullfile(subjectTractographyFolder, 'sift_mu.txt');
    siftCoeffs = fullfile(subjectTractographyFolder, 'sift_coeffs.csv');
    if ~isfile(siftWeights)
        system(['tcksift2 -nthreads 6 -act ' tsegments_registered ' -out_mu ' siftMu ' -out_coeffs ' siftCoeffs ' ' tractogram ' ' wmFOD_norm ' ' siftWeights]);
    end

    % Scale sift weights by mu. We do it here instead of multiplying by
    % connectivity beacuse we will make multiple connectivity maps and
    % that's a lot of 
    scaledByMu = fullfile(subjectTractographyFolder, 'sift_weights_MuScaled.csv');
    lines = readlines(siftWeights);
    weightsLoaded = str2double(split(lines(2), ','))';
    muLoaded = load(siftMu);
    scaledWeights = weightsLoaded * muLoaded;
    writematrix(scaledWeights, scaledByMu);
end