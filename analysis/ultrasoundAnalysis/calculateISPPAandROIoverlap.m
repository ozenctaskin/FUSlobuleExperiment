function calculateISPPAandROIoverlap(modellingFolder, atlas)

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
    %
    %   ROI: ROI or atlas registered to the isotropic T1 image. If set to 
    %   'NA' just create the ISPPA maps. If the input is an atlas that
    %   contains multiple ROI, then calculate the results for all ROI.
    %
    %%%%%%
    
    % Set the target ISPPA in water 
    targetInWater = 30;

    % Find all files with mat extension and Isppa-5.0W in the name
    files = dir(fullfile(modellingFolder, '*Isppa-5.0W*.mat'));
    
    % Create a folder in modelling folder to save files
    saveDir = fullfile(modellingFolder, 'ISPPA_measurementFiles');
    if ~isfolder(saveDir)
        mkdir(saveDir)
    end

    % Loop through all mat files
    for ii = 1:length(files)
        % Get the name of the target
        targetName = extractBefore(files(ii).name, '_');
    
        % Load the mat file containing BabelBrain calculations
        load(fullfile(modellingFolder, files(ii).name), 'MaterialMap', 'MaterialList', 'RatioLosses', 'Isppa', 'p_map', 'TxSystem')

        % Find the Full elastic image for that target. We will only use this 
        % to make sure the generated ISPPA image has the same resolution 
        % and headers
        fullElastic = dir(fullfile(modellingFolder, [targetName '_' TxSystem '*PPW_FullElasticSolution_Sub.nii.gz']));

        % Load the full elastic 
        fullElasticLoaded = MRIread(fullfile(modellingFolder, fullElastic.name));

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

        % Write ISPPA and do NORM masking
        ISPPAout = fullfile(saveDir, [targetName '_' TxSystem '_ISPPA_at_30W-water.nii.gz']);
        MRIwrite(fullElasticLoaded, ISPPAout);
        normMask = fullfile(modellingFolder, 'tmpMask.nii.gz');
        system(['fslmaths ' fullfile(modellingFolder, strrep(fullElastic.name, '_Sub', '_Sub_NORM')) ' -thr 0 -bin ' normMask]);
        system(['flirt -in ' normMask ' -ref ' ISPPAout ' -applyxfm -usesqform -nosearch -interp nearestneighbour -out ' normMask]);
        maskedISPPAout = fullfile(saveDir, [targetName '_' TxSystem '_ISPPA_at_30W-water_NORM.nii.gz']);
        system(['fslmaths ' ISPPAout ' -mul ' normMask ' ' maskedISPPAout]);
        system(['rm ' normMask]);

        if ~strcmp(atlas, 'NA')
            % Create a workdir inside the saveDir folder
            workdir = fullfile(saveDir, 'tempWork');
            if ~isfolder(workdir)
                mkdir(workdir)
            end

            % Resample atlas to the intensity field resolution.
            [~, atlasName, ~] = fileparts(atlas);
            atlasName = strrep(atlasName, '.nii', '');
            atlasResampled = fullfile(workdir, [atlasName '_resampled_to_target' targetName '.nii.gz']);
            system(['fslmaths ' atlas ' -bin ' atlasResampled]);
            system(['flirt -in ' atlas ' -ref ' ISPPAout ' -applyxfm -usesqform -nosearch -interp nearestneighbour -out ' atlasResampled]);
    
            % Load atlas resampled and check the number of ROIs in it
            atlasLoaded = MRIread(atlasResampled);
            saveTemp = atlasLoaded;
            uniqueROI = unique(atlasLoaded.vol);
            uniqueROI(uniqueROI == 0) = [];
            if isempty(uniqueROI)
                warning(['For your target: ' targetName ' no overlapping ROI was found in the specified atlas'])
            end
            
            % Create a mat so we can save a table
            meanISPPAlist = [];
            meanISPPAlist_exposure_weighted = [];

            % Loop through each unique ROI
            for maskIdx = 1:length(uniqueROI)
                % Separate each ROI within atlas and save the sepated
                % versions into workdir.
                emptyMat = zeros(atlasLoaded.volsize);
                emptyMat(find(atlasLoaded.vol == uniqueROI(maskIdx))) = 1;
                saveTemp.vol = emptyMat;
                ROIfile = fullfile(workdir, [num2str(maskIdx) '.nii.gz']);
                MRIwrite(saveTemp, ROIfile);
    
                % Threshold very small values in the ISPPA beam
                beamMask = fullfile(workdir, 'beamMask.nii.gz');
                system(['fslmaths ' ISPPAout ' -thr 0.1 -bin ' beamMask]);
                ISPPAoutThresh = fullfile(workdir, 'ISPPAthresh.nii.gz');
                system(['fslmaths ' ISPPAout ' -mul ' beamMask ' ' ISPPAoutThresh]);

                % Get ISSPA within each ROI and append to subject list.
                % Do 2 calculations (-M and -m), first not including zero
                % voxels in ROI and second including them. The aim of the
                % second measurement is to create a metric based both on
                % intensity and beam coverage (e.g. subject with a larger
                % ROI will have a smaller number due to a larger number of
                % zero voxels if the beam size is similar.
                [~, ISPPAwithinROI] = system(['fslstats ' ISPPAoutThresh ' -k ' ROIfile ' -M -m']);
                ISPPAwithinROI = regexprep(strtrim(ISPPAwithinROI),'\s+', ' '); % Format FSL output

                if contains(ISPPAwithinROI, 'Empty')
                    meanISPPA = 0;
                    meanISPPA_weighted = 0;
                else
                    ISPPAwithinROI = str2num(ISPPAwithinROI);
                    meanISPPA = ISPPAwithinROI(1);
                    meanISPPA_weighted = ISPPAwithinROI(2);
                end
                meanISPPAlist = [meanISPPAlist; meanISPPA];
                meanISPPAlist_exposure_weighted = [meanISPPAlist_exposure_weighted; meanISPPA_weighted];

                % Print the results to terminal
                [~, ROIname, ~] = fileparts(ROIfile);
                if length(uniqueROI) > 1
                    fprintf(['Mean ISPPA in ROI number ' strrep(ROIname,'.nii','') ' for modelling target(' targetName '): ' num2str(meanISPPA) ', volume weighted: ' num2str(meanISPPA_weighted) '\n']);
                else
                    fprintf(['Mean ISPPA in ROI for modelling target(' targetName '): ' num2str(meanISPPA) ', volume weighted: ' num2str(meanISPPA_weighted) '\n']);
                end
            end

            % Write table
            if length(uniqueROI) > 1
                T = table(uniqueROI, meanISPPAlist, meanISPPAlist_exposure_weighted,  'VariableNames', {'ROI_number', 'Mean_ROI_ISPPA', 'Weighted_Mean_ROI_ISPPA'});
                writetable(T, fullfile(saveDir, ['ROI_ISPPA_for_target_' targetName '.xlsx']));
            end

            % Pop the workdir
            system(['rm -r ' workdir]);
        end
    end
end

