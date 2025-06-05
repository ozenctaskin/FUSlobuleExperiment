function calculateDiffusionMetrics(dataFolder, subjectID, sessionID)
   
    % Create the output directory 
    analysisFolder = fullfile(dataFolder, subjectID, sessionID, [subjectID '.diffusionResults']);
    preprocessedResults = fullfile(analysisFolder, 'preprocessed');
    intermediateFiles = fullfile(analysisFolder, 'intermediateFiles');
    metricFolder = fullfile(analysisFolder, 'diffusionMetrics');
    if ~isfolder(metricFolder)
        mkdir(metricFolder)
    end
    if ~isfolder(preprocessedResults)
        mkdir(preprocessedResults)
    end
    if ~isfolder(intermediateFiles)
        mkdir(intermediateFiles)
    end

    % Get the files we need
    cleanDWI = fullfile(preprocessedResults, 'cleanDWI.mif');
    upscaledCleanDWI = fullfile(preprocessedResults, 'upscaledCleanDWI.mif');
    mask = fullfile(preprocessedResults, 'mask.mif');
    upscaledMask = fullfile(preprocessedResults, 'upscaledMask.mif');
    upscaledMaskDilated = fullfile(preprocessedResults, 'upscaledMaskDilated.mif');

    % Run DTI. Calculate metrics from the upscaled dilated mask
    dt = fullfile(metricFolder, 'dtensors.mif');
    dkt = fullfile(metricFolder, 'dkurtosis.mif');
    fa = fullfile(metricFolder, 'fa.mif');
    md = fullfile(metricFolder, 'md.mif');
    ad = fullfile(metricFolder, 'ad.mif');
    rd = fullfile(metricFolder, 'rd.mif');
    mk = fullfile(metricFolder, 'mk.mif');
    ak = fullfile(metricFolder, 'ak.mif');
    rk = fullfile(metricFolder, 'rk.mif');
    system(['dwi2tensor -mask ' upscaledMaskDilated ' -dkt ' dkt ' ' upscaledCleanDWI ' ' dt]);
    system(['tensor2metric -mask ' upscaledMaskDilated ' -fa ' fa ' -adc ' md ' -ad ' ad ' -rd ' rd ' ' dt]);
    % system(['tensor2metric -mask ' upscaledMaskDilated ' -mk ' mk ' -ak ' ak ' -rk ' rk ' ' dkt]);

    %% NODDI
    % Convert mif to nifti and separate bvac-bvals so that we can pass
    % everything to NODDI. Don't use the upscale as it takes too long
    cleanDWInifti = fullfile(intermediateFiles, 'cleanDWI.nii');
    maskNifti = fullfile(intermediateFiles, 'mask.nii');
    bvecsNifti = fullfile(intermediateFiles, 'combined.bvecs');
    bvalsNifti = fullfile(intermediateFiles, 'combined.bvals');
    system(['mrconvert -export_grad_fsl ' bvecsNifti ' ' bvalsNifti ' ' cleanDWI ' ' cleanDWInifti]);
    system(['mrconvert ' mask ' ' maskNifti]);

    % Convert data for fitting
    noddiROI = fullfile(intermediateFiles, 'NODDI_ROI.mat');
    CreateROI(cleanDWInifti, maskNifti, noddiROI);
    protocol = FSL2Protocol(bvalsNifti, bvecsNifti); 
    noddi = MakeModel('WatsonSHStickTortIsoV_B0'); 
    fittedNODDI = fullfile(preprocessedResults, 'NODDI_fitted.mat');
    batch_fitting(noddiROI, protocol, noddi, fittedNODDI, 8); 
    SaveParamsAsNIfTI(fittedNODDI, noddiROI, maskNifti, fullfile(metricFolder,'noddi'))

    % Calculate whole brain tractography and SIFT. We might want to go up 
    % to 100 million streamlines. ADDD BIAS CORRECTION
    % NECESSARY for SIFT!, CHECK OUT -seed_dynamic with tckgen
    % seedGM = fullfile(subjectTractography, 'seedGM.mif');
    % wholeBrainTracts = fullfile(subjectTractography, 'wholeBrainTracts.tck');
    % wholeBrainTracts_SIFTED = fullfile(subjectTractography, 'wholeBrainTracts_SIFTED.tck');
    % system(['5tt2gmwmi ' tissueSegments ' ' seedGM]);
    % system(['tckgen -act ' tissueSegments ' -algorithm  Tensor_Prob -minlength 100 -select 5000 -nthreads 12 -seed_gmwmi ' seedGM ' ' upscaled_preprocessedImage ' ' wholeBrainTracts]);
    % system(['tcksift ' wholeBrainTracts ' ' wmFOD_norm ' ' wholeBrainTracts_SIFTED]);

end