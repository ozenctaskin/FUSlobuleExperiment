function calculateISPPAandROIoverlap(modellingFolder, ROI)

    % !! Add fieldtrip to path  
    % !! Make sure FSL is installed and can be called from terminal
    % !! Start matlab from terminal 
    % !! Do not use huge ROI (e.g. half a hemisphere)
    %
    % This function generates intensity maps for each modelling target,
    % calculates overlap with the specified ROI, and calculates average 
    % ISPPA within that ROI. Intensity maps are scaled for 30W target in 
    % water. 
    %
    %
    % Inputs:
    %   modellingFolder: Folder that contains your BabelBrain output.
    %   ROI: ROI specified on the isotropic T1 image.
    %
    %%%%%%
    
    % Set the target ISPPA in water 
    targetInWater = 30;

    % Find all files with mat extension and Isppa-5.0W in the name
    files = dir(fullfile(modellingFolder, '*Isppa-5.0W*.mat'));
    
    % Create a folder in modelling folder to save files
    workdir = fullfile(modellingFolder, 'ISPPA_measurementFiles');
    if ~isfolder(workdir)
        mkdir(workdir)
    end

    % Loop through all mat files
    for ii = 1:length(files)
        % Get the name of the target
        targetName = extractBefore(files(ii).name, '_');
    
        % Find the Full elastic image for that target. We will only use this 
        % to make sure the generated ISPPA image has the same resolution 
        % and headers
        fullElastic = dir(fullfile(modellingFolder, [targetName '*PPW_FullElasticSolution_Sub.nii.gz']));
        fullElasticLoaded = MRIread(fullfile(modellingFolder, fullElastic.name));
    
        % Load h5 and calculate ISPPA map
        load(fullfile(modellingFolder, files(ii).name), 'MaterialMap', 'MaterialList', 'RatioLosses', 'Isppa', 'p_map')
    
        % Fix python 0 indexing difference for matlab 
        MaterialMap_corrected = MaterialMap + 1;
    
        % Extract density and c maps 
        rho_map = MaterialList.Density(MaterialMap_corrected);
        c_map   = MaterialList.SoS(MaterialMap_corrected);
    
        % Amount of ISPPA we gotta request to get 30W water
        newIsppaTarget = targetInWater * RatioLosses;
        scalingFactor = newIsppaTarget / Isppa;
    
        % Calculate the ISPPA map at 30W 
        Isppa_map = (p_map.^2) ./ (2 .* rho_map .* c_map) ./ 1e4 * scalingFactor;
    
        % We need to flip and permute the matrix to convert from BabelBrain to
        % MRI format. Then write an ISPPA image to the modelling folder
        Isppa_map = permute(flip(Isppa_map,3), [2 1 3]);
        fullElasticLoaded.vol = Isppa_map;
        ISPPAout = fullfile(workdir, [targetName '_ISPPA_at_30W-water.nii.gz']);
        MRIwrite(fullElasticLoaded, ISPPAout);
    
        % Resample ROI to the intensity field resolution.
        [~, ROIname, ~] = fileparts(ROI);
        ROIname = strrep(ROIname, '.nii', '');
        ROIresampled = fullfile(workdir, [ROIname '_resampled_to_' targetName '.nii.gz']);
        system(['fslmaths ' ROI ' -bin ' ROIresampled]);
        system(['flirt -in ' ROI ' -ref ' ISPPAout ' -applyxfm -usesqform -nosearch -interp nearestneighbour -out ' ROIresampled]);

        % Get overlap and average ISPPA within ROI 
        overlapField = fullfile(workdir, [ROIname '_overlap_for_' targetName '.nii.gz']);
        system(['fslmaths ' ISPPAout ' -mul ' ROIresampled ' ' overlapField]);
        [~, cmdout] = system(['fslstats ' overlapField ' -m']);
        fprintf(['Average ISPPA in ROI for modelling target(' targetName '): ' cmdout]);

    end
end

