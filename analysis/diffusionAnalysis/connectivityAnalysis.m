function connectivityAnalysis(dataFolder, subjectID, sessionID)

    % Create the output folder
    analysisFolder = fullfile(dataFolder, subjectID, sessionID, [subjectID '.diffusionResults']);
    subjectConnectivityFolder = fullfile(analysisFolder, 'connectivity');
    intermediateFiles = fullfile(subjectConnectivityFolder, 'intermediateFiles');
    if ~isfolder(subjectConnectivityFolder)
        mkdir(subjectConnectivityFolder)
    end
    if ~isfolder(intermediateFiles)
        mkdir(intermediateFiles)
    end

    % Get the stuff we need
    preprocessedResults = fullfile(analysisFolder, 'preprocessed');
    subjectTractographyFolder = fullfile(analysisFolder, 'subjectTractography');
    funcResults = fullfile(dataFolder, subjectID, sessionID, [subjectID '.results']);

    upscaledCleanDWI_single = fullfile(subjectTractographyFolder, 'intermediateFiles', 'upscaledCleanDWI_single.nii.gz');
    tractogram = fullfile(subjectTractographyFolder, 'tractogram_10M.tck');
    siftWeights = fullfile(subjectTractographyFolder, 'sift_weights.txt');
    nodes = fullfile(dataFolder, subjectID, sessionID, [subjectID '.ROI'], 'finalLabels.nii.gz');
    stats = fullfile(funcResults, ['stats.' subjectID '_REML+orig']);

    % Register the nodes to DWI space
    DWItoT1affine = fullfile(preprocessedResults, 'registrations', 'dwi2T10GenericAffine.mat');
    nodes_registered = fullfile(intermediateFiles, 'finalLabels_in_DWI.nii.gz');
    system(['antsApplyTransforms -e 3 -i ' nodes ' -r ' upscaledCleanDWI_single ' -n NearestNeighbor -t [ ' DWItoT1affine ',1 ] -o ' nodes_registered]);

    % Generate connectome with weights (number of tracts weighted with
    % sift2)
    connectome = fullfile(subjectConnectivityFolder, [subjectID '_weight_connectome.csv']);
    connectomeAssignments = fullfile(intermediateFiles, [subjectID '_connectomeAsignments.csv']);
    system(['tck2connectome ' tractogram ' ' nodes_registered ' ' connectome ' -tck_weights_in ' siftWeights ' -symmetric -zero_diagonal -assignment_radial_search 2 -out_assignments ' connectomeAssignments]);

    % Now do microstructural measurements of edges
    metricFolder = fullfile(analysisFolder, 'diffusionMetrics');
    metrics = {'fa','md','ad','rd','noddi_ficvf','noddi_fiso','noddi_odi'};
    for ii = 1:length(metrics)
        if ~contains(metrics{ii}, 'noddi')
            metric = fullfile(metricFolder, [metrics{ii} '.mif']);
        else
            metric = fullfile(metricFolder, [metrics{ii} '.nii']);
        end
        meanPerStrl = fullfile(intermediateFiles, [metrics{ii} '_mean_per_streamline.csv']);
        assignment = fullfile(intermediateFiles, [metrics{ii} '_assignments.txt']);
        connectome = fullfile(subjectConnectivityFolder, [subjectID '_' metrics{ii} '_connectome.csv']);
        if ~isfile(meanPerStrl)
            system(['tcksample ' tractogram ' ' metric ' ' meanPerStrl ' -stat_tck mean']);
        end
        if ~isfile(connectome)
            system(['tck2connectome ' tractogram ' ' nodes_registered ' ' connectome ' -tck_weights_in ' siftWeights ' -scale_file ' meanPerStrl ' -stat_edge mean -symmetric -zero_diagonal -assignment_radial_search 4 -out_assignments ' assignment]);
        end
    end

    % Now we do more careful segmentation of the CTC pathway. We first
    % convert fmri tstat to zstat, move to DWI space and threshold z>2.3.
    % Then, get the overlap of this mask and the motor cortex ROI. Use this
    % for the tractography segmentation. Also do it with the whole M1 so 
    % that we report both. Also extract thalamus and cerebellar regions
    zstat = fullfile(intermediateFiles, 'zstat.nii.gz');
    zstatInDWI = fullfile(intermediateFiles, 'zstat_in_DWI.nii.gz');
    zstatInDWIthrs = fullfile(intermediateFiles, 'zstat_in_DWI_thresholded.nii.gz');
    system(['3dmerge -1zscore -prefix ' zstat ' ' stats '[tap#0_Tstat]']);
    system(['antsApplyTransforms -e 3 -i ' zstat ' -r ' upscaledCleanDWI_single ' -t [ ' DWItoT1affine ',1 ] -o ' zstatInDWI]);
    system(['fslmaths ' zstatInDWI ' -thr 2.3 -bin ' zstatInDWIthrs]);
    motorCortexSegment = fullfile(intermediateFiles, 'precentral.nii.gz');
    system(['mri_extract_label ' nodes_registered ' 23 ' motorCortexSegment]);
    motorCortexROI = fullfile(intermediateFiles, 'M1roi.nii.gz');
    system(['fslmaths ' zstatInDWIthrs ' -mul ' motorCortexSegment ' ' motorCortexROI]);
    
    lobule5 = fullfile(intermediateFiles, 'lobule5.nii.gz');
    system(['mri_extract_label ' nodes_registered ' 99 ' lobule5]);
    lobule8 = fullfile(intermediateFiles, 'lobule8.nii.gz');
    system(['mri_extract_label ' nodes_registered ' 100 ' lobule8]);
    dentate = fullfile(intermediateFiles, 'dentate.nii.gz');
    system(['mri_extract_label ' nodes_registered ' 96 ' dentate]);
    thalamus = fullfile(intermediateFiles, 'thalamus.nii.gz');
    system(['mri_extract_label ' nodes_registered ' 35 ' thalamus]);

    %%%%%% SCALE BY MU SCALE BY MU
    % Segment lobule5-dentate 
    lobule5Dentate = fullfile(intermediateFiles, 'lobule5Dentate.tck');
    lobule5DentateWeights = fullfile(intermediateFiles, 'lobule5Dentate_weights.csv');
    system(['tckedit ' tractogram ' -include ' lobule5 ' -include ' dentate ' -maxlength 10 ' lobule5Dentate ' -tck_weights_in ' siftWeights ' -tck_weights_out ' lobule5DentateWeights]);
    
    % Segment lobule8-dentate 
    lobule8Dentate = fullfile(intermediateFiles, 'lobule8Dentate.tck');
    lobule8DentateWeights = fullfile(intermediateFiles, 'lobule8Dentate_weights.csv');
    system(['tckedit ' tractogram ' -include ' lobule8 ' -include ' dentate ' -maxlength 10 ' lobule8Dentate ' -tck_weights_in ' siftWeights ' -tck_weights_out ' lobule8DentateWeights]);

    % Segment dento-thalamic
    dentoThalamicTract = fullfile(intermediateFiles, 'dentoThalamic.tck');
    dentoThalamicTractWeights = fullfile(intermediateFiles, 'dentoThalamic_weights.csv');
    system(['tckedit ' tractogram ' -include ' dentate ' -include ' thalamus ' -maxlength 80 ' dentoThalamicTract ' -tck_weights_in ' siftWeights ' -tck_weights_out ' dentoThalamicTractWeights]);

    % Segment thalamo-cortical
    thalamoM1 = fullfile(intermediateFiles, 'thalamoM1.tck');
    thalamoM1Weights = fullfile(intermediateFiles, 'thalamoM1_weights.csv');
    system(['tckedit ' tractogram ' -include ' thalamus ' -include ' motorCortexROI ' -maxlength 80 ' thalamoM1 ' -tck_weights_in ' siftWeights ' -tck_weights_out ' thalamoM1Weights]);

end


    
