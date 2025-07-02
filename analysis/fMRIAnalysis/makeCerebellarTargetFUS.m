function makeCerebellarTargetFUS(dataFolder, subjectID, sessionID, outputCluster, handedness)
    
    % This function takes the output of preprocessCerebellarFMRI function
    % and produces cerebellar targets for sonication. Cluster analysis is
    % performed and overlap of the clusters in the cerebellum and the
    % cerebellar atlas is calculated to constrain the stimulation location.
    % 
    %   dataFolder: BIDS folder where your subjects are located.
    %   subjectID: Name of the subject folder located in dataFolder. e.g
    %              sub-01.
    %   sessionID: Name of the session folder located in subject folder e.g
    %              ses-01. 
    %   outputCluster: Is number of clusters (targets) to produce from
    %                  larger to smaller. For finger tapping targets, 
    %                  setting this to 3 essentially captures both lobule 5
    %                  and 8. If you set this to 'all', then all detected
    %                  clusters are produced.
    %   handedness: Whether the subject is left or right handed. Decides
    %               which hemisphere atlas is used in the function.

    % Add path to functions we will use
    addpath(genpath('/home/chenlab-linux/Documents/MATLAB/toolboxes/spm12'));
    addpath(genpath('/home/chenlab-linux/Documents/MATLAB/toolboxes/freesurferMatlabLibrary'));
    addpath(genpath('/home/chenlab-linux/Documents/MATLAB/toolboxes/fieldtrip/external/afni'));

    % Get the de-obliques anatomical images and atlases
    T1pathDeobliqued = fullfile(dataFolder, subjectID, sessionID, 'anat', [subjectID '_' sessionID '_acq-btoMPRAGE2x11mmisoDEOBLIQUED_T1w.nii.gz']);
    T2pathDeobliqued = fullfile(dataFolder, subjectID, sessionID, 'anat', [subjectID '_' sessionID '_acq-btoSPACET22x2CAIPI1mmisoDEOBLIQUED_T2w.nii.gz']);
    spm_Dir= fileparts(which('spm'));
    atlasNettekoven = fullfile(fileparts(matlab.desktop.editor.getActiveFilename), 'atlas', 'atl-NettekovenAsym32_space-SUIT_dseg.nii');
    atlasDiedrichsen = fullfile(fileparts(matlab.desktop.editor.getActiveFilename), 'atlas', 'atl-Anatom_space-SUIT_dseg.nii');

    %% Cerebellar processing - SUIT

    %Set Suit defaults and atlas paths
    suit_defaults();
    spm('Defaults','fMRI');
    spm_jobman('initcfg');

    % Create a cerebellar folder inside the AFNI results folder
    outputFolder = fullfile(dataFolder, subjectID, sessionID, [subjectID '.results']);
    cerebellarFolder = fullfile(outputFolder, 'cerebellarTarget');
    if ~isfolder(cerebellarFolder)
        mkdir(cerebellarFolder);
    end
    workdir = fullfile(cerebellarFolder, 'workdir');
    if ~isfolder(workdir)
        mkdir(workdir);
    end

    % Convert stats to nifti and make a beta surface map
    func = fullfile(outputFolder, ['stats.' subjectID '_REML+orig']);
    system(['cd ' outputFolder ';' '3dAFNItoNIFTI -prefix ' fullfile(workdir,'beta') ' ' func '''[tap#0_Coef]''']);
    system(['cd ' outputFolder ';' '3dAFNItoNIFTI -prefix ' fullfile(workdir,'tstat') ' ' func '''[tap#0_Tstat]''']);
    system(['cd ' outputFolder ';' '3dAFNItoNIFTI -prefix ' fullfile(workdir,'tstat') ' ' func '''[tap_Fstat]''']);
    beta = fullfile(workdir, 'beta.nii');

    % Bias correct T1 and T2 and move them into the workdir
    T1 = fullfile(workdir, 'T1.nii');
    T2 = fullfile(workdir, 'T2.nii');
    system(['N4BiasFieldCorrection -i ' T1pathDeobliqued ' -o ' T1]);
    system(['N4BiasFieldCorrection -i ' T2pathDeobliqued ' -o ' T2]);

    % Register T2 to T1 and setup SUIT anatomy cell
    system(['antsRegistrationSyN.sh -m ' T2 ' -f ' T1 ' -t r -n 12 -o ' fullfile(workdir,'T2registered')]);
    system(['gunzip ' fullfile(workdir,'T2registeredWarped.nii.gz') ' -f']);
    T2 = fullfile(workdir, 'T2registeredWarped.nii');
    anatomy = {T1, T2};
    [filePath, fileName, ~] = fileparts(anatomy{1});
    
    % Segment cerebellum, and normalize to SUIT atlas coordinates
    suit_isolate_seg(anatomy);
    job.subjND.gray = {fullfile(filePath, [fileName '_seg1.nii'])};
    job.subjND.white = {fullfile(filePath, [fileName '_seg2.nii'])};
    job.subjND.isolation = {fullfile(filePath, ['c_' fileName '_pcereb.nii'])};
    suit_normalize_dartel(job)
    
    % Copy atlases into workdir, and update the path 
    system(['cp ' atlasNettekoven ' ' workdir]);
    system(['cp ' atlasDiedrichsen ' ' workdir]);
    atlasNettekoven = fullfile(workdir, 'atl-NettekovenAsym32_space-SUIT_dseg.nii');
    atlasDiedrichsen = fullfile(workdir, 'atl-Anatom_space-SUIT_dseg.nii');

    % Map Nettekoven32/Diedrichsen atlas and cerebellar mask to subject
    % fMRI space. We'll map Diedrichsen atlas directly to anatomical
    % coordinates as we don't use it for any fMRI business
    job = [];
    job.Affine = {fullfile(filePath, ['Affine_' fileName '_seg1.mat'])};
    job.flowfield = {fullfile(filePath, ['u_a_' fileName '_seg1.nii'])};
    job.resample = {atlasNettekoven};
    job.ref = {beta};
    suit_reslice_dartel_inv(job);  
    job.resample = {[spm_Dir '/toolbox/suit/templates/maskSUIT.nii']};
    suit_reslice_dartel_inv(job);  
    job.resample = {atlasDiedrichsen};
    job.ref = {T1};
    suit_reslice_dartel_inv(job);  
    cerebellarMaskResampled = fullfile(filePath, ['iw_maskSUIT_u_a_' fileName '_seg1.nii']);
    atlasNettekovenResampled = fullfile(filePath, ['iw_atl-NettekovenAsym32_space-SUIT_dseg_u_a_' fileName '_seg1.nii']);
    atlasDiedrichsenResampled = fullfile(filePath, ['iw_atl-Anatom_space-SUIT_dseg_u_a_' fileName '_seg1.nii']);

    % Get the left/right motor regions from the Nettekoven atlas
    if strcmp(handedness, 'right')
        motorAtlas = fullfile(workdir, 'M3R.nii'); % Number 19 is the right hemi
        atlasIndex = '19';
    elseif strcmp(handedness, 'left')
        motorAtlas = fullfile(workdir, 'M3L.nii'); % Number 3 is the left hemi
        atlasIndex = '3';
    end
    system(['mri_extract_label ' atlasNettekovenResampled ' ' atlasIndex ' ' motorAtlas]);
    system(['mri_binarize --i ' motorAtlas ' --match 128 --o ' motorAtlas]);

    % Get the dentate mask and center of mass coordinates
    if strcmp(handedness, 'right')
        dentateMask = fullfile(workdir, 'dentateMaskRight.nii'); % idx is 30
        atlasIndex = '30';
    elseif strcmp(handedness, 'left')
        dentateMask = fullfile(workdir, 'dentateMaskLeft.nii'); % idx is 29
        atlasIndex = '29';
    end
    system(['fslmaths ' atlasDiedrichsenResampled ' -uthr ' atlasIndex ' -thr ' atlasIndex ' -bin ' dentateMask]);
    system(['gunzip ' dentateMask ' -f']);
    [~, massDentate] = system(['fslstats ' dentateMask ' -C ']);
    massDentate_vox = strsplit(massDentate);
    massDentate_vox = round(cell2mat(cellfun(@str2double, massDentate_vox(1:end-1), 'UniformOutput', false)));
    [~, massDentate] = system(['fslstats ' dentateMask ' -c ']);
    massDentate_mm = strsplit(massDentate);
    massDentate_mm = round(cell2mat(cellfun(@str2double, massDentate_mm(1:end-1), 'UniformOutput', false)));    
    writematrix(massDentate_mm, fullfile(cerebellarFolder, 'DentateCoordinatesCOM.txt'));
    dentateTargetMask = fullfile(cerebellarFolder, 'dentateTargetMask.nii.gz');
    system(['fslmaths ' dentateMask ' -roi ' num2str(massDentate_vox(1)) ' 1 ' num2str(massDentate_vox(2)) ' 1 ' num2str(massDentate_vox(3)) ' 1 0 1 -mul 3 -add ' dentateMask ' ' dentateTargetMask]);
    system(['gunzip ' dentateTargetMask ' -f']);

    % Make a cerebellar flatmap plot for the beta values
    job = [];
    job.subj.resample = {beta};
    job.subj.affineTr = {fullfile(filePath, ['Affine_' fileName '_seg1.mat'])};
    job.subj.flowfield = {fullfile(filePath, ['u_a_' fileName '_seg1.nii'])};
    job.subj.mask = fullfile(filePath, ['iw_maskSUIT_u_a_' fileName '_seg1.nii']);
    suit_reslice_dartel(job)
    betaResampled = fullfile(workdir, 'wdbeta.nii');
    fig = figure();
    suit_plotflatmap(suit_map2surf(betaResampled), 'threshold', max(suit_map2surf(betaResampled))/100*10, 'cmap', hot);
    saveas(fig, fullfile(cerebellarFolder, 'betaMap_10perThr.png'));
    close all 

    % Clusterize and threshold the cerebellar activity so we get the lobule
    % 5 and 8 activity only on separate images. Do multiple comparisons
    % test with the ClustSim results. A cluster is at p=0.001, alpha=0.05.
    clusterSim = Read_1D(fullfile(outputFolder,'files_ClustSim','ClustSim.ACF.NN1_bisided.1D'));
    nVox = num2str(floor(clusterSim(find(clusterSim(:,1) == 0.001), 7))); 
    prefMap = fullfile(cerebellarFolder, 'ClusterMap.nii.gz');
    prefDat = fullfile(cerebellarFolder, 'ClusterEffEst.nii.gz');
    system(['3dClusterize -inset ' func ' -ithr 2 -idat 1 -mask ' cerebellarMaskResampled ' -NN 1 -bisided p=0.001 -clust_nvox ' nVox ' -pref_map ' prefMap ' -pref_dat ' prefDat]);

    % Make a surface plot from prefDat
    prefdatGziped = fullfile(workdir, 'ClusterEffEst.nii');
    system(['gunzip -c ' prefDat ' > ' prefdatGziped]);
    job = [];
    job.subj.resample = {prefdatGziped};
    job.subj.affineTr = {fullfile(filePath, ['Affine_' fileName '_seg1.mat'])};
    job.subj.flowfield = {fullfile(filePath, ['u_a_' fileName '_seg1.nii'])};
    job.subj.mask = fullfile(filePath, ['iw_maskSUIT_u_a_' fileName '_seg1.nii']);
    suit_reslice_dartel(job)
    clusterResampled = fullfile(workdir, 'wdClusterEffEst.nii');
    fig = figure();
    suit_plotflatmap(suit_map2surf(clusterResampled), 'cmap', hot);
    saveas(fig, fullfile(cerebellarFolder, 'ClusterMap.png'));
    close all 

    % Make separate binary masks from clustermaps and calculate internal
    % center of mass with AFNI. Output number of clusters based on the
    % outputCluster variable. 
    prefMapLoaded = MRIread(prefMap);
    if strcmp(outputCluster, 'all')
        clusterIndex = max(max(max(prefMapLoaded.vol)));
    else
        clusterIndex = outputCluster;
    end
    for ii = 1:clusterIndex
        % Separate cluster masks into separate images and mask the data
        % with each of them.
        clusterMask = fullfile(workdir, ['ClusterMask_' num2str(ii) '.nii.gz']);
        system(['mri_extract_label ' prefMap ' ' num2str(ii) ' ' clusterMask]);
        system(['mri_binarize --i ' clusterMask ' --match 128 --o ' clusterMask]);
        clusterData = fullfile(workdir, ['ClusterData_' num2str(ii) '.nii.gz']);
        system(['fslmaths ' prefDat ' -mas ' clusterMask ' ' clusterData]);

        % Now mask the data with the overlap of clusterMask and Nettekoven
        % motor mask 
        clusterMaskMotor = fullfile(workdir, ['ClusterMaskMotor_' num2str(ii) '.nii.gz']);
        system(['fslmaths ' clusterMask ' -mul ' motorAtlas ' ' clusterMaskMotor]);
        clusterDataMotor = fullfile(workdir, ['ClusterDataMotor_' num2str(ii) '.nii.gz']);
        system(['fslmaths ' prefDat ' -mas ' clusterMaskMotor ' ' clusterDataMotor]);
        
        % calculate the peak activation in cluster data
        [~, peakCluster] = system(['fslstats ' clusterData ' -x ']);
        peakCluster_vox = strsplit(peakCluster);
        peakCluster_vox = round(cell2mat(cellfun(@str2double, peakCluster_vox(1:end-1), 'UniformOutput', false)));
        [~, peakCluster_mm] = system(['echo ' peakCluster(1:end-2) '| img2stdcoord -img ' clusterData ' -std ' clusterData ' -vox']);
        peakCluster_mm = strsplit(peakCluster_mm);
        peakCluster_mm = round(cell2mat(cellfun(@str2double, peakCluster_mm(1:end-1), 'UniformOutput', false)));

        % Calculate the peak coordinates in Nettekoven atlas, convert to mm
        [~, peakMotor] = system(['fslstats ' clusterDataMotor ' -x']);
        peakMotor_vox = strsplit(peakMotor);
        peakMotor_vox = round(cell2mat(cellfun(@str2double, peakMotor_vox(1:end-1), 'UniformOutput', false)));
        [~, peakMotor_mm] = system(['echo ' peakMotor(1:end-2) '| img2stdcoord -img ' clusterDataMotor ' -std ' clusterDataMotor ' -vox']);
        peakMotor_mm = strsplit(peakMotor_mm);
        peakMotor_mm = round(cell2mat(cellfun(@str2double, peakMotor_mm(1:end-1), 'UniformOutput', false)));

        % Write TUS targets into a text file in mm.
        writematrix(peakCluster_mm, fullfile(cerebellarFolder, ['Cluster_' num2str(ii) '_peakCluster.txt']));
        writematrix(peakMotor_mm, fullfile(cerebellarFolder, ['Cluster_' num2str(ii) '_peakMotor.txt']));
        
        % Make target masks and plot 
        peakTargetMask = fullfile(cerebellarFolder, ['Cluster_' num2str(ii) '_peakTargetMask.nii.gz']);
        peakMotorTargetMask = fullfile(cerebellarFolder, ['Cluster_' num2str(ii) '_peakMotorTargetMask.nii.gz']);
        system(['fslmaths ' clusterMask ' -roi ' num2str(peakCluster_vox(1)) ' 1 ' num2str(peakCluster_vox(2)) ' 1 ' num2str(peakCluster_vox(3)) ' 1 0 1 -mul 3 -add ' clusterMask ' ' peakTargetMask]);
        system(['fslmaths ' clusterMaskMotor ' -roi ' num2str(peakMotor_vox(1)) ' 1 ' num2str(peakMotor_vox(2)) ' 1 ' num2str(peakMotor_vox(3)) ' 1 0 1 -mul 3 -add ' clusterMaskMotor ' ' peakMotorTargetMask]);
        system(['gunzip ' peakTargetMask ' -f']);
        system(['gunzip ' peakMotorTargetMask ' -f']);
        peakTargetMask = strrep(peakTargetMask, '.gz', '');
        peakMotorTargetMask = strrep(peakMotorTargetMask, '.gz', '');
        
        % Map masked target data to SUIT space
        peakTargetMaskSUIT = fullfile(workdir, ['wdCluster_' num2str(ii) '_peakTargetMask.nii']);
        peakMotorTargetMaskSUIT = fullfile(workdir, ['wdCluster_' num2str(ii) '_peakMotorTargetMask.nii']);
        job = [];
        job.interp = 0;
        % job.vox = [2.5, 2.5, 2.5];
        job.subj.resample = {peakTargetMask};
        job.subj.mask = {peakTargetMask};
        job.subj.affineTr = {fullfile(filePath, ['Affine_' fileName '_seg1.mat'])};
        job.subj.flowfield = {fullfile(filePath, ['u_a_' fileName '_seg1.nii'])};
        job.subj.outname = {peakTargetMaskSUIT};
        suit_reslice_dartel(job);
        job.subj.resample = {peakMotorTargetMask};
        job.subj.mask = {peakMotorTargetMask};
        job.subj.outname = {peakMotorTargetMaskSUIT};
        suit_reslice_dartel(job);
        
        % Plot diagnostic target plots
        data = suit_map2surf(peakTargetMaskSUIT);
        fig = figure();
        suit_plotflatmap(data, 'cmap', autumn);
        saveas(fig, fullfile(cerebellarFolder, ['TUStargetPlot_Peak_' num2str(ii) '.png']));
        close all
        data = suit_map2surf(peakMotorTargetMaskSUIT);
        fig = figure();
        suit_plotflatmap(data, 'cmap', autumn);
        saveas(fig, fullfile(cerebellarFolder, ['TUStargetPlot_PeakMotor_' num2str(ii) '.png']));
        close all
    end

    % Plot the motor atlas
    motorAtlasPlot = fullfile(workdir, ['wdNettekovenPlot.nii']);
    job = [];
    job.interp = 0;
    job.subj.resample = {motorAtlas};
    job.subj.mask = {motorAtlas};
    job.subj.affineTr = {fullfile(filePath, ['Affine_' fileName '_seg1.mat'])};
    job.subj.flowfield = {fullfile(filePath, ['u_a_' fileName '_seg1.nii'])};
    job.subj.outname = {motorAtlasPlot};
    suit_reslice_dartel(job);
    data = suit_map2surf(motorAtlasPlot);
    fig = figure();
    data(isnan(data)) = 0;
    suit_plotflatmap(data, 'cmap', autumn, 'threshold', 0.1);
    saveas(fig, fullfile(cerebellarFolder, ['MotorAtlasSurface.png']));
    close all
end