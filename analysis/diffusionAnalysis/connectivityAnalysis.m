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

    upscaledCleanDWI_single = fullfile(subjectTractographyFolder, 'intermediateFiles', 'upscaledCleanDWI_single.nii.gz');
    tractogram = fullfile(subjectTractographyFolder, 'tractogram_10M.tck');
    siftWeights = fullfile(subjectTractographyFolder, 'sift_weights.txt');
    nodes = fullfile(dataFolder, subjectID, sessionID, [subjectID '.ROI'], 'finalLabels.nii.gz');
    tstatMap = fullfile(dataFolder, subjectID, sessionID, [subjectID '.results'], 'cerebellarTarget', 'workdir', 'tstat.nii');

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
    % Use this for the tractography segmentation. Also do it with the whole
    % M1 so that we report both.


end


    
