function preprocessCerebellarFMRI(dataFolder, subjectID, sessionID, stim, blur, combineMethod)

    % ADD PATH TO SPM,SUIT,Freesurfer matlab library, and fieldtrip
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
    % Note: This function is for task-fMRI preprocessing only and spe.
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
    %   blur: Whether to use blur or not. Number of NA.
    %   combineMethod: Echo combination method, check afni_proc.py for 
    %   details

    %% MRI preprocessing - AFNI

    % Set up variables we will use 
    T1path = fullfile(dataFolder, subjectID, sessionID, 'anat', [subjectID '_' sessionID '_acq-btoMPRAGE2x11mmiso_T1w.nii.gz']);
    T2path = fullfile(dataFolder, subjectID, sessionID, 'anat', [subjectID '_' sessionID '_acq-btoSPACET22x2CAIPI1mmiso_T2w.nii.gz']);
    blipForward = fullfile(dataFolder, subjectID, sessionID, 'func', [subjectID '_' sessionID '_task-fingerTap_dir-PA_run-1_echo-1_part-mag_bold.nii.gz']);
    blipReverse = fullfile(dataFolder, subjectID, sessionID, 'fmap', [subjectID '_' sessionID '_acq-e1_dir-AP_epi.nii.gz']);
    funcDatasetRun1 = fullfile(dataFolder, subjectID, sessionID, 'func', [subjectID '_' sessionID '_task-fingerTap_dir-PA_run-1_echo-*_part-mag_bold.nii.gz']);
    funcDatasetRun2 = fullfile(dataFolder, subjectID, sessionID, 'func', [subjectID '_' sessionID '_task-fingerTap_dir-PA_run-2_echo-*_part-mag_bold.nii.gz']);

    % We need to deoblique the T1 image so that our output AFNI processing
    % can be used directly across softwares. Do this without
    % interpolation. And no need to do it for EPI as afni_proc will take
    % care of this
    T1pathDeobliqued = strrep(T1path, 'btoMPRAGE2x11mmiso_T1w', 'btoMPRAGE2x11mmisoDEOBLIQUED_T1w');
    T2pathDeobliqued = strrep(T2path, 'btoSPACET22x2CAIPI1mmiso_T2w', 'btoSPACET22x2CAIPI1mmisoDEOBLIQUED_T2w');
    system(['cd ' fullfile(dataFolder, subjectID, sessionID, 'anat') '; 3dcopy ' [subjectID '_' sessionID '_acq-btoMPRAGE2x11mmiso_T1w.nii.gz'] ' _tmp_dset; 3drefit -oblique_recenter _tmp_dset+orig; 3drefit -deoblique _tmp_dset+orig; 3dcopy _tmp_dset+orig ' T1pathDeobliqued '; rm _tmp*']);
    system(['cd ' fullfile(dataFolder, subjectID, sessionID, 'anat') '; 3dcopy ' [subjectID '_' sessionID '_acq-btoSPACET22x2CAIPI1mmiso_T2w.nii.gz'] ' _tmp_dset; 3drefit -oblique_recenter _tmp_dset+orig; 3drefit -deoblique _tmp_dset+orig; 3dcopy _tmp_dset+orig ' T2pathDeobliqued '; rm _tmp*']);

    % Insert slice timing info from json to nifti
    fprintf('\nAdding slice time information to data. Do not stop the script now or your MRI images get corrupted.\n');
    system(['abids_tool.py -add_slice_times -input ' funcDatasetRun1]);
    system(['abids_tool.py -add_slice_times -input ' funcDatasetRun2]);

    % Build and run the preprocessing setup. No blurring. If you need to
    % add it back. It needs to come after combine block. Also add the below
    % info to the main body
    afni_line = ['cd ' fullfile(dataFolder, subjectID, sessionID) ';' 'afni_proc.py ' ...,
    '-subj_id ' subjectID ' ' ...,
    '-copy_anat ' T1pathDeobliqued ' '  ...,  
    '-anat_has_skull yes ' ..., 
    '-dsets_me_run ' funcDatasetRun1 ' ' ..., 
    '-dsets_me_run ' funcDatasetRun2 ' ' ...,          
    '-blip_forward_dset ' blipForward ' ' ..., 
    '-blip_reverse_dset ' blipReverse ' ' ..., 
    '-combine_method ' combineMethod ' ' ...,
    '-echo_times 13.20 29.94 46.66 -reg_echo 2 ' ..., 
    '-radial_correlate_blocks tcat volreg ' ...,
    '-align_unifize_epi local ' ..., 
    '-align_opts_aea -cost lpc+ZZ -giant_move -check_flip ' ...,    
    '-volreg_align_to MIN_OUTLIER ' ...,
    '-volreg_align_e2a ' ..., 
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
        afni_line = [afni_line ' -blur_size ' blur ' -blur_in_mask yes -blocks despike tshift align volreg mask combine blur scale regress'];
    else
        afni_line = [afni_line ' -blocks despike tshift align volreg mask combine scale regress'];
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
    
end