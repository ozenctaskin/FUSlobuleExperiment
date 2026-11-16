function cleanCBITrials(folderPath, autoclean)
% CLEANCBITRIALS Review, filter, and clean CBI/TUS EMG recordings.
%
% Usage:
%   cleanCBITrials('/path/to/subject', false)  % interactive trial rejection
%   cleanCBITrials('/path/to/subject', true)   % conservative automatic rejection
%
% Details:
%   * Only EMG channels (2) are filtered; trigger/TUS channels stay untouched.
%   * Raw pre-stimulation RMS flags persist after filtering.
%     For FUS: pre-FUS; for TMS-CBI: pre-TMS.
%   * Residual pre-TMS RMS is assessed separately after filtering.
%   * Automatic rejection uses raw pre-stimulation QC ONLY by default.
%   * Each file gets a clean_*.mat and an accompanying qc_*.csv.
%
% Timing (5 kHz):
%   FUS onset approximately 0.0985 s, when present.
%   The original file-specific artifact sample (975 for filenames with
%   "CBI", 2750 otherwise) represents a TMS artifact, NOT FUS onset.
%   MEP peak-to-peak windows:
%       FUS: 0.56--0.60 s (samples 2801:3001, 5 kHz)
%       TMS-CBI: samples 1070:1250 (user-specified)
%   The raw pre-FUS window applies ONLY to FUS recordings.
%   TMS-CBI uses a pre-TMS window as its raw muscle-activity QC.
%
% Important: Verify FUS onset, TMS timing, sample units, and EMG channel
% for other acquisition protocols before generalizing these settings.

    if nargin < 2 || isempty(autoclean)
        autoclean = false;
    end
    if nargin < 1 || isempty(folderPath)
        folderPath = pwd;
    end

    %% USER SETTINGS
    Fs = 5000;
    emgChannels = 1;                 % DO NOT include the TUS/trigger channel
    rawRmsThreshold_mV = 0.05;       % 50 microvolts, assumes EMG data in mV
    residualRmsThreshold_mV = 0.05;  % flag for review, not automatic rejection
    autoRejectResidual = false;      % keep false until threshold validated

    % Raw EMG activation check for FUS trials (before ~0.0985-s FUS onset).
    preFUSWindow_s = [0.020 0.085];

    % Pre-TMS QC: a 100-ms window ending 20 ms before the file's TMS artifact.
    % The 20-ms gap reduces, but does not eliminate, filter-ringing effects.
    preTMSOffsets_s = [-0.120 -0.020];

    mepWindowFUS_s = [0.56 0.60];
    mepWindowTMSCBI_samples = [1070 1250];  % sample indices, NOT seconds
    lowCutoff = 20;
    highCutoff = 450;
    notchQ = 35;                     % bandwidth ~ 50/35 = 1.43 Hz

    % Same output naming and original MAT structure as your previous script.
    fprintf('CBI cleaning: Fs = %d Hz | EMG channel(s) = %s\n', ...
        Fs, mat2str(emgChannels));

    %% FILTERS
    [bBP, aBP] = butter(4, [lowCutoff highCutoff] / (Fs/2), 'bandpass');
    [bN50, aN50] = iirnotch(50/(Fs/2), (50/(Fs/2))/notchQ);
    [bN60, aN60] = iirnotch(60/(Fs/2), (60/(Fs/2))/notchQ);

    %% FILES
    files = dir(fullfile(folderPath, '*.mat'));
    names = {files.name};
    exclude = startsWith(names, 'clean_', 'IgnoreCase', true) | ...
              contains(names, 'AMT', 'IgnoreCase', true);
    files = files(~exclude);

    if isempty(files)
        fprintf('No eligible MAT files in %s\n', folderPath);
        return
    end

    for fileIdx = 1:numel(files)
        filename = files(fileIdx).name;
        inputPath = fullfile(folderPath, filename);
        [~, stem, ~] = fileparts(filename);
        loadedData = load(inputPath);

        % Identify original data field; handles '0w' -> 'V0w' and variants.
        allFields = fieldnames(loadedData);
        candidates = allFields(endsWith(allFields, '_wave_data', ...
                                          'IgnoreCase', true));
        exactName = [stem '_wave_data'];
        if isfield(loadedData, exactName)
            variableName = exactName;
        elseif numel(candidates) == 1
            variableName = candidates{1};
        else
            warning('Cannot uniquely identify wave_data in %s; skipping.', filename);
            continue
        end

        data = loadedData.(variableName);
        if ~isstruct(data) || ~isfield(data, 'values') || ...
                ~isfield(data, 'frameinfo')
            warning('Unexpected wave_data structure in %s; skipping.', filename);
            continue
        end

        nSamples = size(data.values, 1);
        nChannels = size(data.values, 2);
        nTrials = size(data.values, 3);

        if nTrials == 0 || any(emgChannels < 1) || ...
                any(emgChannels > nChannels) || size(data.frameinfo, 1) ~= nTrials
            warning('Invalid trial/channel/frameinfo dimensions in %s; skipping.', filename);
            continue
        end

        % The two modalities have DIFFERENT TMS/MEP timing.
        % 'CBI' in the filename means TMS-based CBI, not FUS.
        isTMSCBI = contains(stem, 'CBI', 'IgnoreCase', true);
        if isTMSCBI
            tmsArtifactSample = 975;
            mepIdx = mepWindowTMSCBI_samples(1):mepWindowTMSCBI_samples(2);
            preFUSIdx = [];  % This is NOT a FUS recording.
            rawQCLabel = 'pre-TMS';
        else
            tmsArtifactSample = 2750;
            mepIdx = (round(mepWindowFUS_s(1)*Fs)+1): ...
                     (round(mepWindowFUS_s(2)*Fs)+1);
            preFUSIdx = (round(preFUSWindow_s(1)*Fs)+1): ...
                        (round(preFUSWindow_s(2)*Fs)+1);
            rawQCLabel = 'pre-FUS';
        end

        % Both modalities get a pre-test-TMS measurement ending 20 ms
        % before the TMS artifact. In TMS-CBI, that earlier interval is
        % also used for the raw muscle-activity rejection criterion.
        preTMSIdx = (tmsArtifactSample + round(preTMSOffsets_s(1)*Fs)): ...
                    (tmsArtifactSample + round(preTMSOffsets_s(2)*Fs));

        allQCIdx = [preFUSIdx preTMSIdx mepIdx];
        if min(allQCIdx) < 1 || max(allQCIdx) > nSamples
            warning(['QC/MEP window out of range in %s (length %d; ', ...
                     'TMS sample %d; MEP %d:%d). Skipping.'], ...
                filename, nSamples, tmsArtifactSample, mepIdx(1), mepIdx(end));
            continue
        end

        % Keep the *unfiltered* EMG for permanent raw-QC information.
        rawEMG = double(data.values(:, emgChannels(1), :));
        rawEMG = reshape(rawEMG, nSamples, nTrials);

        rawPreTMSRMS = windowRMS(rawEMG, preTMSIdx);
        if isTMSCBI
            rawPreFUSRMS = nan(nTrials,1);  % not applicable
            rawPreStimRMS = rawPreTMSRMS;
        else
            rawPreFUSRMS = windowRMS(rawEMG, preFUSIdx);
            rawPreStimRMS = rawPreFUSRMS;
        end
        rawMEP = windowP2P(rawEMG, mepIdx);

        rawFlag = ~isfinite(rawPreStimRMS) | ...
                  rawPreStimRMS > rawRmsThreshold_mV;
        invalidEMG = any(~isfinite(rawEMG), 1)';
        rawFlag = rawFlag | invalidEMG;

        % Current values start out identical to raw; these update on filter.
        currentEMG = rawEMG;
        currentPreFUSRMS = rawPreFUSRMS;
        currentPreStimRMS = rawPreStimRMS;
        currentPreTMSRMS = rawPreTMSRMS;
        currentMEP = rawMEP;
        residualFlag = ~isfinite(currentPreTMSRMS) | ...
                       currentPreTMSRMS > residualRmsThreshold_mV;
        filterApplied = false;
        filterDescription = 'Unfiltered';
        overviewClosed = false;

        fprintf('\n===================================================\n');
        fprintf('%s | %d trials | %d channels | TMS sample %d\n', ...
            filename, nTrials, nChannels, tmsArtifactSample);
        fprintf('MEP window: samples %d:%d\n', mepIdx(1), mepIdx(end));
        fprintf('Raw %s RMS flags: %d/%d\n', rawQCLabel, sum(rawFlag), nTrials);
        fprintf('Pre-TMS flags BEFORE filtering: %d/%d (review only)\n', ...
            sum(residualFlag), nTrials);
        fprintf('Mean raw MEP P2P: %.4f mV\n', ...
            mean(rawMEP(isfinite(rawMEP))));

        %% INTERACTIVE OVERVIEW
        fig = figure('Name', ['Trial QC - ' stem], 'NumberTitle', 'off', ...
            'Color', 'w', 'Units', 'normalized', ...
            'Position', [0.02 0.04 0.96 0.90]);
        set(fig, 'CloseRequestFcn', @closeOverview);

        hSummary = uicontrol(fig, 'Style', 'text', 'String', '', ...
            'Units', 'normalized', 'Position', [0.02 0.875 0.96 0.065], ...
            'FontSize', 10, 'FontWeight', 'bold', ...
            'HorizontalAlignment', 'center', 'BackgroundColor', 'w');

        nCols = ceil(sqrt(nTrials));
        nRows = ceil(nTrials / nCols);
        tl = tiledlayout(fig, nRows, nCols, ...
            'TileSpacing', 'compact', 'Padding', 'compact');
        tl.Units = 'normalized';
        tl.Position = [0.02 0.09 0.96 0.77];

        t_ms = (0:nSamples-1) / Fs * 1000;
        hAx = gobjects(nTrials, 1);
        hTrace = gobjects(nTrials, 1);
        hMax = gobjects(nTrials, 1);
        hMin = gobjects(nTrials, 1);

        for tr = 1:nTrials
            hAx(tr) = nexttile(tl);
            hTrace(tr) = plot(hAx(tr), t_ms, rawEMG(:,tr), ...
                'LineWidth', 0.7);
            hold(hAx(tr), 'on');
            xline(hAx(tr), t_ms(tmsArtifactSample), 'k:', ...
                'LineWidth', 0.7);
            if ~isTMSCBI
                xline(hAx(tr), t_ms(preFUSIdx(end)), ':', ...
                    'Color', [0.4 0.4 0.4], 'LineWidth', 0.5);
            end
            hMax(tr) = plot(hAx(tr), NaN, NaN, 'k*', 'MarkerSize', 6);
            hMin(tr) = plot(hAx(tr), NaN, NaN, 'k*', 'MarkerSize', 6);
            hold(hAx(tr), 'off');
            xlim(hAx(tr), [0 t_ms(end)]);
            ylim(hAx(tr), [-1 1]);  % original display scale
            hAx(tr).FontSize = 7;
            grid(hAx(tr), 'on');
        end
        title(tl, stem, 'Interpreter', 'none', 'FontWeight', 'bold');

        % Five filter choices: none, BP only, BP+50, BP+60, BP+both.
        % 'Continue' accepts the current (possibly filtered) version.
        bpButton = uicontrol(fig, 'Style', 'pushbutton', ...
            'String', '20-450 only', 'Units', 'normalized', ...
            'Position', [0.01 0.015 0.18 0.05], 'Callback', @(~,~) applyFiltering(0));
        hz50Button = uicontrol(fig, 'Style', 'pushbutton', ...
            'String', '20-450 + 50 Hz', 'Units', 'normalized', ...
            'Position', [0.20 0.015 0.18 0.05], 'Callback', @(~,~) applyFiltering(50));
        hz60Button = uicontrol(fig, 'Style', 'pushbutton', ...
            'String', '20-450 + 60 Hz', 'Units', 'normalized', ...
            'Position', [0.39 0.015 0.18 0.05], 'Callback', @(~,~) applyFiltering(60));
        bothButton = uicontrol(fig, 'Style', 'pushbutton', ...
            'String', '20-450 + 50/60', 'Units', 'normalized', ...
            'Position', [0.58 0.015 0.18 0.05], 'Callback', @(~,~) applyFiltering(5060));
        continueButton = uicontrol(fig, 'Style', 'pushbutton', ...
            'String', 'Continue', 'Units', 'normalized', ...
            'Position', [0.77 0.015 0.22 0.05], 'Callback', @continueQC);

        updatePlots();
        drawnow;
        fprintf('Choose a filter, or Continue with unfiltered data.\n');
        uiwait(fig);

        if isgraphics(fig)
            if overviewClosed
                delete(fig);
            else
                set(fig, 'CloseRequestFcn', 'closereq');
            end
        end

        %% TRIAL SELECTION
        % Raw pre-stimulation flags survive filtering. Residual flags are for review.
        reviewFlag = rawFlag | residualFlag;
        droppedTrials = [];

        if autoclean
            droppedTrials = find(rawFlag);
            if autoRejectResidual
                droppedTrials = find(reviewFlag);
            end
            fprintf('Automatic rejection: raw %s flags', rawQCLabel);
            if autoRejectResidual
                fprintf(' PLUS residual pre-TMS flags');
            end
            fprintf('.\n');
        else
            labels = cell(nTrials,1);
            for tr = 1:nTrials
                labels{tr} = sprintf([ ...
                    'Trial %02d | raw %s %.3f | raw pre-TMS %.3f | ', ...
                    'filtered pre-TMS %.3f mV | raw:%d residual:%d | ', ...
                    'MEP %.3f'], ...
                    tr, rawQCLabel, rawPreStimRMS(tr), rawPreTMSRMS(tr), ...
                    currentPreTMSRMS(tr), rawFlag(tr), residualFlag(tr), ...
                    currentMEP(tr));
            end

            [selected, ok] = listdlg( ...
                'Name', ['Reject trials - ' stem], ...
                'PromptString', { ...
                    'Select trials to DROP (both raw and filtered flags shown).', ...
                    'Raw pre-stimulation flags persist after filtering.', ...
                    'Residual flags are review prompts, not proof of bad MEPs.'}, ...
                'ListString', labels, 'SelectionMode', 'multiple', ...
                'InitialValue', find(reviewFlag), ...
                'ListSize', [760 460], ...
                'OKString', 'Reject selected', 'CancelString', 'Keep all');

            if ok
                droppedTrials = selected(:);
            end
        end

        rejected = false(nTrials,1);
        rejected(droppedTrials) = true;
        retained = ~rejected;

        %% SAVE AUDIT TABLE (BEFORE DELETING TRIALS)
        trial = (1:nTrials)';
        filterName = repmat({filterDescription}, nTrials, 1);
        if isTMSCBI
            modality = repmat({'TMS-CBI'}, nTrials, 1);
        else
            modality = repmat({'FUS'}, nTrials, 1);
        end
        qc = table(trial, modality, rawPreStimRMS, rawPreFUSRMS, ...
            rawPreTMSRMS, currentPreStimRMS, currentPreFUSRMS, ...
            currentPreTMSRMS, rawMEP, currentMEP, rawFlag, residualFlag, ...
            rejected, retained, filterName, ...
            'VariableNames', {'trial', 'modality', 'rawPreStimRMS_mV', ...
            'rawPreFUSRMS_mV', 'rawPreTMSRMS_mV', ...
            'currentPreStimRMS_mV', 'currentPreFUSRMS_mV', ...
            'currentPreTMSRMS_mV', 'rawMEPP2P_mV', ...
            'currentMEPP2P_mV', 'rawPreStimFlag', 'residualPreTMSFlag', ...
            'rejected', 'retained', 'filter'});
        qcPath = fullfile(folderPath, ['qc_' stem '.csv']);
        writetable(qc, qcPath);

        % Commit the EMG ONLY; all other channel values remain untouched.
        data.values(:,emgChannels,:) = reshape( ...
            currentEMG, nSamples, 1, nTrials);
        data.values(:,:,droppedTrials) = [];
        data.frameinfo(droppedTrials,:) = [];
        loadedData.(variableName) = data;

        outPath = fullfile(folderPath, ['clean_' filename]);
        save(outPath, '-struct', 'loadedData', '-v7.3');

        fprintf('Filter: %s\n', filterDescription);
        fprintf('Rejected %d/%d trials. Retained %d.\n', ...
            numel(droppedTrials), nTrials, sum(retained));
        if any(retained)
            fprintf('Retained mean MEP P2P: %.4f mV\n', ...
                mean(currentMEP(retained & isfinite(currentMEP))));
        end
        fprintf('Saved %s\nSaved %s\n', outPath, qcPath);
    end

    %% NESTED UI CALLBACKS
    function applyFiltering(whichNotch)
        if filterApplied
            return
        end
        if any(~isfinite(rawEMG(:)))
            errordlg('EMG contains NaN/Inf. Filtering cancelled.', ...
                'Filter error', 'modal');
            return
        end

        try
            filteredEMG = zeros(size(rawEMG));
            for trLocal = 1:nTrials
                y = filtfilt(bBP, aBP, rawEMG(:,trLocal));
                switch whichNotch
                    case 0
                        % Bandpass only
                    case 50
                        y = filtfilt(bN50, aN50, y);
                    case 60
                        y = filtfilt(bN60, aN60, y);
                    case 5060
                        y = filtfilt(bN50, aN50, y);
                        y = filtfilt(bN60, aN60, y);
                end
                filteredEMG(:,trLocal) = y;
            end
        catch ME
            errordlg(ME.message, 'Filter error', 'modal');
            return
        end

        currentEMG = filteredEMG;
        currentPreTMSRMS = windowRMS(currentEMG, preTMSIdx);
        if isTMSCBI
            currentPreFUSRMS = nan(nTrials,1);
            currentPreStimRMS = currentPreTMSRMS;
        else
            currentPreFUSRMS = windowRMS(currentEMG, preFUSIdx);
            currentPreStimRMS = currentPreFUSRMS;
        end
        currentMEP = windowP2P(currentEMG, mepIdx);
        residualFlag = ~isfinite(currentPreTMSRMS) | ...
                       currentPreTMSRMS > residualRmsThreshold_mV;

        filterApplied = true;
        switch whichNotch
            case 0, filterDescription = '20-450 Hz only';
            case 50, filterDescription = '20-450 Hz + 50 Hz (Q=35)';
            case 60, filterDescription = '20-450 Hz + 60 Hz (Q=35)';
            case 5060, filterDescription = '20-450 Hz + 50/60 Hz (Q=35)';
        end
        set([bpButton hz50Button hz60Button bothButton], 'Enable', 'off');
        updatePlots();
        fprintf('Applied: %s | residual pre-TMS flags: %d/%d\n', ...
            filterDescription, sum(residualFlag), nTrials);
    end

    function updatePlots()
        for trLocal = 1:nTrials
            x = currentEMG(:,trLocal);
            set(hTrace(trLocal), 'YData', x);
            seg = x(mepIdx);
            if all(isfinite(seg))
                [pMax, imax] = max(seg);
                [pMin, imin] = min(seg);
                set(hMax(trLocal), 'XData', t_ms(mepIdx(imax)), ...
                    'YData', pMax);
                set(hMin(trLocal), 'XData', t_ms(mepIdx(imin)), ...
                    'YData', pMin);
            else
                set(hMax(trLocal), 'XData', NaN, 'YData', NaN);
                set(hMin(trLocal), 'XData', NaN, 'YData', NaN);
            end
            if rawFlag(trLocal)
                c = [0.82 0.10 0.10];  % raw muscle/QC flag
            elseif residualFlag(trLocal)
                c = [0.92 0.50 0.04];  % residual interference flag
            else
                c = [0.00 0.35 0.75];
            end
            set(hTrace(trLocal), 'Color', c);
            title(hAx(trLocal), sprintf([ ...
                '#%d raw%s %.3f | preTMS %.3f | MEP %.3f'], ...
                trLocal, rawQCLabel, rawPreStimRMS(trLocal), ...
                currentPreTMSRMS(trLocal), currentMEP(trLocal)), ...
                'Color', c, 'FontSize', 8, 'Interpreter', 'none');
        end

        meanRaw = mean(rawMEP(isfinite(rawMEP)));
        meanCur = mean(currentMEP(isfinite(currentMEP)));
        if isfinite(meanRaw) && meanRaw ~= 0
            pct = 100*(meanCur-meanRaw)/meanRaw;
        else
            pct = NaN;
        end
        set(hSummary, 'String', sprintf([ ...
            'MEP P2P (all trials): raw %.4f mV | current %.4f mV | ', ...
            '%+.2f%% | %s | raw flags %d | residual flags %d'], ...
            meanRaw, meanCur, pct, filterDescription, ...
            sum(rawFlag), sum(residualFlag)));
        drawnow;
    end

    function continueQC(~,~)
        if isgraphics(fig)
            % Prevent an old overview from advancing a later file's QC.
            set([bpButton hz50Button hz60Button bothButton ...
                 continueButton], 'Enable', 'off');
            uiresume(fig);
        end
    end

    function closeOverview(~,~)
        overviewClosed = true;
        if isgraphics(fig)
            set(fig, 'Visible', 'off');
            uiresume(fig);
        end
    end

    %% NUMERIC HELPERS
    function r = windowRMS(x, indices)
        if isempty(indices)
            r = nan(size(x,2),1);
            return
        end
        n = size(x,2);
        r = nan(n,1);
        for it = 1:n
            segment = x(indices,it);
            if all(isfinite(segment))
                r(it) = sqrt(mean(segment.^2));
            end
        end
    end

    function p = windowP2P(x, indices)
        n = size(x,2);
        p = nan(n,1);
        for it = 1:n
            segment = x(indices,it);
            if all(isfinite(segment))
                p(it) = max(segment) - min(segment);
            end
        end
    end
end
