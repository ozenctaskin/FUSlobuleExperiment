function calculateROIexposure(modellingFolder, ROI, ROIisMNI, charmFolder)

% This function calculates the overlap of each full elastic solution
% outputted by BabelBrain and the provided ROI, and calculates the average
% ultrasound energy in the ROI. The elastic solution files are found
% automatically by the script and an output is saved in an xlsx file placed
% in the modelling folder. 
%
% WARNING: Needs FSL installed.
%
% Inputs:
%
%   modellingFolder: Path to the modelling folder created by BabelBrain.
%   ROI            : Path to the region of interest mask.
%   ROIisMNI       : true or false. Set true if your ROI is in MNI space.
%                    false if your ROI is in subject space
%   charmFolder    : Path to charmFolder. Only needed if your ROI is in MNI
%                    space. Otherwise you can set this to 'NA'

    % Get the ultrasound models. Look FullElasticSolution_Sub_NORM in file
    % names.
    files = dir(fullfile(modellingFolder, '*FullElasticSolution_Sub_NORM*'));
    
    % Get rid of the Water measurements
    files = files(~contains({files.name}, '_Water_FullElasticSolution_Sub_NORM'));
    
    % If ROI is in MNI space, move it to subject space
    if ROIisMNI
        ROIinSubject = fullfile(modellingFolder, 'ROI_in_Subject');
        system(['mni2subject -m ' charmFolder ' -i ' ROI ' -o ' ROIinSubject ' --interpolation_order 0' ]);
    end
    
    % Create a folder for resampled images
    resampledImages = fullfile(modellingFolder, 'resampledModels');
    if ~isfolder(resampledImages)
        mkdir(resampledImages);
    end
    
    % Make sure the ROI only contains values of 1 by thresholding
    ROIbinarized = fullfile(resampledImages,'ROIbin.nii.gz');
    system(['fslmaths ' ROI ' -thr 0.1 -bin ' ROIbinarized]);

    % Loop through all models 
    for ii = 1:length(files)
        % Resample all models to ROI space
        model = fullfile(files(ii).folder, files(ii).name);
        modelResampled = fullfile(resampledImages, strrep(files(ii).name, '.nii.gz', '_resampled.nii.gz'));
        system(['flirt -in ' model ' -ref ' ROIbinarized ' -applyxfm -usesqform -out ' modelResampled]);

        % Get the overlap of the ROI mask and the model
        overlap = fullfile(resampledImages, strrep(files(ii).name, '.nii.gz', '_overlap.nii.gz'));
        system(['fslmaths ' ROIbinarized ' -mul ' modelResampled ' ' overlap]);
    end


end