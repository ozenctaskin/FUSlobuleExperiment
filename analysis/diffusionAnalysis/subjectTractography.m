function subjectTractography(dataFolder, subjectID, sessionID)

    subjectTractographyFolder = fullfile(dataFolder, subjectID, sessionID, [subjectID, '.diffusionResults'], 'subjectTractography');
    if ~isfolder(subjectTractographyFolder)
        mkdir(subjectTractographyFolder)
    end

    upscaledCleanDWI = fullfile(dataFolder, subjectID, sessionID, [subjectID, '.diffusionResults'], 'preprocessed', 'upscaledCleanDWI.mif');
    upscaledMask = fullfile(dataFolder, subjectID, sessionID, [subjectID, '.diffusionResults'], 'preprocessed', 'upscaledMask.mif');
    upscaledMaskDilated = fullfile(dataFolder, subjectID, sessionID, [subjectID, '.diffusionResults'], 'preprocessed', 'upscaledMaskDilated.mif');
    wmResponse = fullfile(dataFolder, subjectID, sessionID, [subjectID, '.diffusionResults'], 'preprocessed', 'wmResponse.txt');
    gmResponse = fullfile(dataFolder, subjectID, sessionID, [subjectID, '.diffusionResults'], 'preprocessed', 'gmResponse.txt');
    csfResponse = fullfile(dataFolder, subjectID, sessionID, [subjectID, '.diffusionResults'], 'preprocessed', 'csfResponse.txt');
    tsegments = fullfile(dataFolder, subjectID, sessionID, [subjectID, '.diffusionResults'], 'preprocessed', 'segmented5Tissues.mif');

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

    % Get gray matter seed. We use the dynamic seeding option, but generate 
    % this in case we change mind
    gmwmiMask = fullfile(subjectTractographyFolder, 'gmwmiMask.mif');
    system(['5tt2gmwmi ' tsegments ' ' gmwmiMask]);

    % Run tractography. 100 million tracks
    tractogram = fullfile(subjectTractographyFolder, 'tractogram_10M.tck');
    if ~isfile(tractogram)
        system(['tckgen -act ' tsegments ' -backtrack -crop_at_gmwmi -cutoff 0.06 -maxlength 250 -nthreads 10 -select 10M -seed_dynamic ' wmFOD_norm ' ' wmFOD_norm ' ' tractogram]);
    end

    % SIFT
    siftWeights = fullfile(subjectTractographyFolder, 'sift_weights.txt');
    siftMu = fullfile(subjectTractographyFolder, 'sift_mu.txt');
    siftCoeffs = fullfile(subjectTractographyFolder, 'sift_coeffs.txt');
    if ~isfile(tractogram)
        system(['tcksift2 -nthreads 10 -act ' tsegments ' -out_mu ' siftMu ' -out_coeffs ' siftCoeffs ' ' tractogram ' ' wmFOD_norm ' ' siftWeights]);
    end
end