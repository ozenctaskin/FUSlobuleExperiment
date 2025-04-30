function warpSet = preprocessMESimpleTask_lobule(dataFolder, subjectID, sessionID, stim, anatomicalPath, MNITemplate, blur, combineMethod, inputWarp)

    % ADD PATH TO SUIT!! 
    %
    %
    % IMPORTANT!!!! This script won't run if you do not start MATLAB from 
    % your terminal. If you are on linux, run "matlab" on your terminal. 
    % If you are on mac, run "open /Applications/MATLAB_R2023b.app" 
    % (Change the R2023b with your version). The reason is that when 
    % started with the icon instead of the terminal, matlab cannot access 
    % your $PATH variables and uses its own paths, so afni functions can't 
    % be found.
    %
    % Note: This function is for task-fMRI preprocessing only.
    %
    % This script performs preprocessing on multi-echo images with AFNI. 
    % Use it if you want to analyze every run separately. This is
    % applicable for instance if you take the subject out of the scanner in
    % the middle of the scan and therefore have multiple fieldmap images. 
    % In the results folder look for final_func.nii and final_anat.nii
    % files. These are your preprocessed final output converted to NIFTI 
    % format. 
    %
    %   dataFolder: BIDS folder where your subjects are located
    %   subjectID: Name of the subject folder located in dataFolder. e.g
    %   sub-01.
    %   sessionID: Name of the session folder located in subject folder e.g
    %   ses-PPN. 
    %   stim: .txt file in which your stimulus onset is located. Currently
    %   only a single condition is supported by this matlab script (finger
    %   tap vs. rest). 
    %   anatomicalPath: Path to anatomical image you want to process
    %   MNITemplate: You can find one in $FSLDIR/data/standard. use 1mm MNI
    %   use the _brain one. 
    %   blur: Whether to use blur or not. Number of NA.
    %   combineMethod: Echo combination method, check afni_proc.py for 
    %   details
    %   inputWarp: path to input warp. If you are processing data from the
    %   same subject and session, no need to run the warp a second time. So
    %   specify the output of the first run as an input here. 
    
    % Set up variables we will use 
    blipForward = fullfile(dataFolder, subjectID, sessionID, 'func', [subjectID '_' sessionID '_task-fingerTap_dir-PA_run-1_echo-1_part-mag_bold.nii.gz']);
    blipReverse = fullfile(dataFolder, subjectID, sessionID, 'fmap', [subjectID '_' sessionID '_acq-e1_dir-AP_epi.nii.gz']);
    funcDatasetRun1 = fullfile(dataFolder, subjectID, sessionID, 'func', [subjectID '_' sessionID '_task-fingerTap_dir-PA_run-1_echo-*_part-mag_bold.nii.gz']);
    funcDatasetRun2 = fullfile(dataFolder, subjectID, sessionID, 'func', [subjectID '_' sessionID '_task-fingerTap_dir-PA_run-2_echo-*_part-mag_bold.nii.gz']);

    % Insert slice timing info from json to nifti
    fprintf('\nAdding slice time information to data. Do not stop the script now or your MRi images get corrupted.\n');
    system(['abids_tool.py -add_slice_times -input ' funcDatasetRun1]);
    system(['abids_tool.py -add_slice_times -input ' funcDatasetRun2]);

    % Build and run the preprocessing setup. No blurring. If you need to
    % add it back. It needs to come after combine block. Also add the below
    % info to the main body
    afni_line = ['cd ' fullfile(dataFolder, subjectID, sessionID) ';' 'afni_proc.py ' ...,
    '-subj_id ' subjectID ' ' ...,
    '-copy_anat ' anatomicalPath ' '  ...,  
    '-anat_has_skull yes ' ..., 
    '-dsets_me_run ' funcDatasetRun1 ' ' ..., 
    '-dsets_me_run ' funcDatasetRun2 ' ' ...,          
    '-blip_forward_dset ' blipForward ' ' ..., 
    '-blip_reverse_dset ' blipReverse ' ' ..., 
    '-combine_method ' combineMethod ' ' ...,
    '-echo_times 13.20 29.94 46.66 -reg_echo 1 ' ..., 
    '-radial_correlate_blocks tcat volreg ' ...,
    '-align_unifize_epi local ' ..., 
    '-align_opts_aea -cost lpc+ZZ -giant_move -check_flip ' ...,    
    '-tlrc_base ' MNITemplate ' ' ..., 
    '-tlrc_NL_warp ' ...,
    '-tlrc_no_ss ' ...,
    '-volreg_align_to MIN_OUTLIER ' ...,
    '-volreg_align_e2a ' ..., 
    '-volreg_tlrc_warp ' ...,
    '-volreg_compute_tsnr yes ' ..., 
    '-mask_epi_anat yes ' ...,
    '-regress_stim_times ' stim ' ' ...,          
    '-regress_stim_labels tap ' ...,                                
    '-regress_basis ''BLOCK(10,1)'' ' ...,                              
    '-regress_motion_per_run ' ...,
    '-regress_censor_motion 0.3 ' ...,
    '-regress_censor_outliers 0.05 ' ..., 
    '-regress_apply_mot_types demean deriv ' ..., 
    '-regress_3dD_stop ' ...,
    '-regress_reml_exec ' ...,
    '-regress_compute_fitts ' ..., 
    '-regress_make_ideal_sum sum_ideal.1D ' ...,
    '-regress_est_blur_epits ' ...,
    '-regress_est_blur_errts ' ..., 
    '-regress_run_clustsim yes ' ..., 
    '-html_review_style pythonic ' ..., 
    '-remove_preproc_files'];
    
    % If blur is specified, add it to the function. 
    if ~strcmp(blur, 'NA')
        afni_line = [afni_line ' -blur_size ' blur ' -blur_in_mask yes -blocks despike tshift align tlrc volreg mask combine blur scale regress'];
    else
        afni_line = [afni_line ' -blocks despike tshift align tlrc volreg mask combine scale regress'];
    end
    
    % Get input warp if supplied
    if ~strcmp(inputWarp, 'NA')
        afni_line = [afni_line ' -tlrc_NL_warped_dsets ' inputWarp{1} ' ' inputWarp{2} ' ' inputWarp{3}];
    end

    % Run the afni line
    system(afni_line);
    
    % Add the run number to the proc script that AFNI creates
    procScript = fullfile(dataFolder, subjectID, sessionID, ['proc.' subjectID]);
    if strcmp(blur, 'NA')
        procScript = fullfile(dataFolder, subjectID, sessionID, ['proc.' subjectID]);
    else
        procScript = fullfile(dataFolder, subjectID, sessionID, ['proc.' subjectID]);
        newProcName = fullfile(dataFolder, subjectID, sessionID, ['proc.' subjectID '.blur_' blur 'mm']);
        system(['mv ' procScript ' ' newProcName]);
        procScript = newProcName;
    end
    
    % Set the output text name
    if strcmp(blur, 'NA')
        outputReport = fullfile(dataFolder, subjectID, sessionID, ['output.proc.' subjectID]);
    else
        outputReport = fullfile(dataFolder, subjectID, sessionID, ['output.proc.' subjectID '.blur_' blur 'mm']);
    end

    % Run preprocessing 
    system(['cd ' fullfile(dataFolder, subjectID, sessionID) '; ' 'tcsh -xef ' procScript ' 2>&1 | tee ' outputReport]);

    % Convert func and anat results to nifti 
    outputFolder = fullfile(dataFolder, subjectID, sessionID, [subjectID '.results']);
    func = fullfile(outputFolder, ['stats.' subjectID '_REML+tlrc']);
    anat = fullfile(outputFolder, ['anat_final.' subjectID '+tlrc.HEAD']);
    system(['cd ' outputFolder ';' '3dAFNItoNIFTI -prefix beta ' func '''[tap#0_Coef]''']);
    system(['cd ' outputFolder ';' '3dAFNItoNIFTI -prefix tstat ' func '''[tap#0_Tstat]''']);
    system(['cd ' outputFolder ';' '3dAFNItoNIFTI -prefix fstat ' func '''[tap_Fstat]''']);
    system(['cd ' outputFolder ';' '3dAFNItoNIFTI -prefix final_anat ' anat]);

    % Return final anat and warps to be used for hte next run
    warpSet = {fullfile(outputFolder,'final_anat.nii'), ...
               fullfile(outputFolder,'anat.un.aff.Xat.1D'), ...
               fullfile(outputFolder,'anat.un.aff.qw_WARP.nii')};

    % Plot the full flattened cerebellar beta activation with 10% threshold
    cerebellarFolder = fullfile(outputFolder, 'cerebellarTarget');
    if ~isfolder(cerebellarFolder)
        mkdir(cerebellarFolder)
    end
    data = suit_map2surf(fullfile(outputFolder, 'beta.nii'));
    fig = figure();
    suit_plotflatmap(data, 'threshold', max(data)/100*10, 'cmap', hot)
    saveas(fig, fullfile(cerebellarFolder, 'betaMap.png'))
    close all

    % Now plot significant t-values (p < 0.05) 
    system(['cd ' outputFolder ';' '3dPval -prefix pvals ' func]);
    system(['cd ' outputFolder ';' '3dAFNItoNIFTI -prefix tstat_pval pvals+tlrc''[tap#0_Tstat_pval]''']);
    data_pval = suit_map2surf(fullfile(outputFolder, 'tstat_pval.nii'));
    data_tstat = suit_map2surf(fullfile(outputFolder, 'tstat.nii'));
    data_tstat(find(data_pval>0.05)) = 0; % p-thresholding is not covered by suit 
    fig = figure();
    suit_plotflatmap(data_tstat, 'cmap', hot, 'threshold', 0.00001) % Threshold high to get rid of dark surface
    saveas(fig, fullfile(cerebellarFolder, 'tmap_0.05.png'))
    close all
end