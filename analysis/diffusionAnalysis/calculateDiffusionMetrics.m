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
    upscaledCleanDWI = fullfile(preprocessedResults, 'upscaledCleanDWI.mif');
    upscaledMask = fullfile(preprocessedResults, 'upscaledMask.mif');
    upscaledMaskDilated = fullfile(preprocessedResults, 'upscaledMaskDilated.mif');

    % Run DTI. Calculate metrics from the upscaled dilated mask
    dt = fullfile(metricFolder, 'dtensors.mif');
    dkt = fullfile(metricFolder, 'dkurtosis.mif');
    fa = fullfile(metricFolder, 'fa.mif');
    md = fullfile(metricFolder, 'md.mif');
    ad = fullfile(metricFolder, 'ad.mif');
    rd = fullfile(metricFolder, 'rd.mif');
    system(['dwi2tensor -mask ' upscaledMaskDilated ' -dkt ' dkt ' ' upscaledCleanDWI ' ' dt]);
    system(['tensor2metric -mask ' upscaledMaskDilated ' -fa ' fa ' -adc ' md ' -ad ' ad ' -rd ' rd ' ' dt]);
    
    % Check these metrics out too
    % system(['tensor2metric -mask ' upscaledMaskDilated ' -mk ' mk ' -ak ' ak ' -rk ' rk ' ' dkt]);

    %% NODDI
    % Convert mif to nifti and separate bvac-bvals so that we can pass
    % everything to NODDI.
    upscaledCleanDWI_nifti = fullfile(intermediateFiles, 'upscaledCleanDWI.nii');
    upscaledMask_nifti = fullfile(intermediateFiles, 'upscaledMask.nii');
    bvecsNifti = fullfile(intermediateFiles, 'upscaledCleanDWI.bvecs');
    bvalsNifti = fullfile(intermediateFiles, 'upscaledCleanDWI.bvals');
    system(['mrconvert -export_grad_fsl ' bvecsNifti ' ' bvalsNifti ' ' upscaledCleanDWI ' ' upscaledCleanDWI_nifti]);
    system(['mrconvert ' upscaledMask ' ' upscaledMask_nifti]);

    % Convert data for fitting
    noddiROI = fullfile(intermediateFiles, 'NODDI_ROI.mat');
    CreateROI(upscaledCleanDWI_nifti, upscaledMask_nifti, noddiROI);
    protocol = FSL2Protocol(bvalsNifti, bvecsNifti); 
    model = MakeModel('WatsonSHStickTortIsoV_B0'); 
    fittedNODDI = fullfile(preprocessedResults, 'NODDI_fitted.mat');
    batch_fitting(noddiROI, protocol, model, fittedNODDI, 8); 
    SaveParamsAsNIfTI(fittedNODDI, noddiROI, upscaledMask_nifti, fullfile(metricFolder,'noddi'))

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