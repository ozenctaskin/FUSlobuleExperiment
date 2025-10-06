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
    subjectTractographyFolder = fullfile(analysisFolder, 'subjectTractography');
    tractogram = fullfile(subjectTractographyFolder, 'tractogram_10M.tck');
    siftWeights = fullfile(subjectTractographyFolder, 'sift_weights.txt');
    ROIfolder = fullfile(dataFolder, subjectID, sessionID, [subjectID '.ROI']);
    nodes = fullfile(ROIfolder, 'segmented5Tissues_native_final.nii.gz');

    % Generate connectome with weights (number of tracts weighted with
    % sift2)
    connectome = fullfile(subjectConnectivityFolder, [subjectID '_connectome.csv']);
    connectomeAssignments = fullfile(subjectConnectivityFolder, [subjectID '_connectomeAsignments.csv']);
    system(['tck2connectome ' tractogram ' ' nodes ' ' connectome ' -tck_weights_in ' siftWeights ' -symmetric -zero_diagonal -assignment_radial_search 4 -out_assignments ' connectomeAssignments]);

    % Now do microstructural measurements of edges
    metricFolder = fullfile(analysisFolder, 'diffusionMetrics');
    metrics = {'fa','md','ad','rd','noddi_ficvf','noddi_fiso','noddi_odi'};
    for ii = 1:length(metrics)
        metric = fullfile(metricFolder, [metrics{ii} '.mif']);
        meanPerStrl = fullfile(intermediateFiles, [metrics{ii} '_mean_per_streamline.mif']);
        assignment = fullfile(intermediateFiles, [metrics{ii} '_assignments.mif']);
        connectome = fullfile(subjectConnectivityFolder, [metrics{ii} '_connectivity.mif']);
        system(['tcksample ' tractogram ' ' metric ' ' meanPerStrl ' -stat_tck mean']);
        system(['tck2connectome ' tractogram ' ' nodes ' ' connectome ' -tck_weights_in ' siftWeights ' -scale_file ' meanPerStrl ' -stat_edge mean -symmetric -zero_diagonal -assignment_radial_search 4 -out_assignments ' assignment]);
    end

end


    
