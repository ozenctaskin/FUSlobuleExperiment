function emgPhys(realStim, shamStim, fs)

% Code to extract oscillatory and non-oscillatory signal components from
% EMG data. Works with Signal data converted to mat via Signal and compares
% the plots for two conditions e.g. real and sham. It works with 2
% channels. Channel 1 is the TMS and channel 2 is FUS burst events.
%
%   realStim = Condition one. Could be multiple files in a cell
%   shamStim = Condition two. Could be multiple files in a cell
%   fs       = Sampling frequency
%
%

% Make everything a cell
if ~iscell(realStim)
    realStim = {realStim};
end
if ~iscell(shamStim)
    shamStim = {shamStim};
end

% Determine the maximum length between realStim and shamStim
maxLen = max(numel(realStim), numel(shamStim));

% Add a single NaN to whichever is shorter
if numel(realStim) < maxLen
    realStim{maxLen} = [NaN];
end
if numel(shamStim) < maxLen
    shamStim{maxLen} = [NaN];
end

% Combine cells
dataAll = [realStim; shamStim];
dataLabel = ['real'; 'sham'];
trialLength = {};
TUSevents = {};
dataLoaded = {};

% Loop through cell items and load the data in
[rowCount, colCount] = size(dataAll);
for row = 1:rowCount
    for col = 1:colCount
        if ~isnan(dataAll{row, col})
            loadedDataItem = load(dataAll{row, col});
            fields = fieldnames(loadedDataItem);
            trialLength{row, col} = size(loadedDataItem.(fields{2}).values(:,1,:), 1) / fs;
            dataLoaded{row, col} = reshape(loadedDataItem.(fields{2}).values(:,1,:), [], 1);
            TUSevents{row, col} = reshape(loadedDataItem.(fields{2}).values(:,2,:), [], 1);
        end
    end
end

% If trial lengths are not equal, throw an error
nonEmptyCells = ~cellfun(@isempty, trialLength);
if ~all(cellfun(@(x) isequal(x, trialLength{1,1}), trialLength(nonEmptyCells)))
    error('Your trials are not in equal length. This is not supported')
end

% Append real with real and sham with sham. Drop the placeholder NaN
combinedData = cellfun(@(row) vertcat(row{:}), num2cell(dataLoaded, 2), 'UniformOutput', false);
combinedTUSevents = cellfun(@(row) vertcat(row{:}), num2cell(TUSevents, 2), 'UniformOutput', false);

% Set a time vector and bandpass values
bandpass = [20 150];

%% Plot average measurements from trials
% Set figures
fig = figure();
set(fig, 'Position', [100, 100, 825, 450]);
ax1 = subplot(1,4,1);
ax2 = subplot(1,4,2);
ax3 = subplot(1,4,3);
ax4 = subplot(1,4,4);
hold(ax1, 'on');
hold(ax2, 'on');
hold(ax3, 'on');
hold(ax4, 'on');
xlabel(ax1, 'Frequency'); ylabel(ax2, 'power (db/Hz)');
xlabel(ax2, 'log frequency'); ylabel(ax1, 'power (dB/Hz)');
xlabel(ax3, 'Condition'); ylabel(ax3, 'Offset');
xlabel(ax4, 'Condition'); ylabel(ax3, 'Exponent');
xlim(ax1, bandpass)
xlim(ax3, [0, 3])
xlim(ax4, [0, 3])
title(ax1, 'Oscillatory');
title(ax2, 'Non-oscillatory');
title(ax3, 'Offset');
title(ax4, 'Exponent');
colors = ['b', 'r'];
sgtitle('Trial average')

% Time frequency cell for comparison later
TFA = {};

% Loop through the real and sham data and plot components
for ii = 1:size(combinedData,1)
    t = (1:size(combinedData{ii},1))/fs;
    data = [];
    data.trial{1,1} = combinedData{ii}';
    data.time{1,1} = t;
    data.label{1} = 'EMG';
    data.trialinfo(1,1) = 1;
    
    % Notch to remove line noise
    data.trial{1} = ft_preproc_dftfilter(data.trial{1}, fs, 60);

    % chunk into trial segments for long/continuous trials
    cfg           = [];
    cfg.length    = trialLength{1}; % freqency resolution = 1/2^floor(log2(cfg.length*0.9))
    cfg.overlap   = 0;
    data          = ft_redefinetrial(cfg, data);

    % Cleaning
    cfg          = [];
    cfg.method   = 'summary';
    data   = ft_rejectvisual(cfg, data);

    % Time freq
    cfg              = [];
    cfg.output       = 'pow';
    cfg.channel      = 'EMG';
    cfg.method       = 'mtmconvol';
    cfg.taper        = 'hanning';
    cfg.foi          = 20:0.5:150;                         
    cfg.t_ftimwin    = ones(length(cfg.foi),1).*0.2;  
    cfg.toi          = 0:0.01:0.8;     
    cfg.pad          = 'nextpow2';
    cfg.keeptrials   = 'no';
    cfg.tapsmofrq  = 0.4 *cfg.foi;
    TFRhann = ft_freqanalysis(cfg, data);
    TFA{ii} = TFRhann;

    % compute the fractal and original spectra
    cfg               = [];
    cfg.foilim        = bandpass;
    cfg.pad           = 'nextpow2';
    cfg.method        = 'irasa';
    cfg.output        = 'fractal';
    cfg.keeptrials    = 'no';
    fractal = ft_freqanalysis(cfg, data);
    cfg.output        = 'original';
    original = ft_freqanalysis(cfg, data);
    % keep trials, do fractal again, so we can plot all in a single plt
    cfg.keeptrials    = 'yes';
    fractal_trials = ft_freqanalysis(cfg, data);

    % subtract the fractal component from the power spectrum
    cfg               = [];
    cfg.parameter     = 'powspctrm';
    cfg.operation     = 'x2-x1';
    oscillatory = ft_math(cfg, fractal, original);

    % display the spectra in log-log scale
    plot(ax1, fractal.freq, log(oscillatory.powspctrm), colors(ii));    
    plot(ax2, log(fractal.freq), log(fractal.powspctrm), colors(ii)); 

    % Plot individual trial non-oscillatory
    for trl = 1:size(fractal_trials.powspctrm,1)
        p = polyfit(log(fractal.freq), log(reshape(fractal_trials.powspctrm(trl,1,:), 1, [])), 1);
        scatter(ax3, ii, p(2), colors(ii))
        scatter(ax4, ii, p(1), colors(ii))
    end

end
legend(ax1, {'Real', 'Sham'});
legend(ax2, {'Real', 'Sham'});

% figure()
% ft_singleplotTFR(cfg, TFA{1});
% figure()
% ft_singleplotTFR(cfg, TFA{2});
% 
% % Plot TFA difference real - sham
% cfg = [];
% cfg.parameter = 'powspctrm'; % The parameter to operate on
% cfg.operation = 'x1 - x2';  % Subtraction operation
% TFRdiff = ft_math(cfg, TFA{1}, TFA{2});
% cfg = [];
% % cfg.zlim = 'maxabs';
% cfg.channel = 'EMG';
% cfg.showlabels = 'yes';
% cfg.trials = 'all';
% ft_singleplotTFR(cfg, TFRdiff);

%% Just analyze the real data, compare FUS section to baseline
for ii = 1:size(combinedTUSevents,1)
    blocks = lowpass(combinedTUSevents{ii},100,800);
    blocks(find(blocks<0.1)) = 0;
    blocks(find(blocks>0.1)) = 1;
    combinedTUSevents{ii} = blocks;
end
realPart = combinedData{1}(find(combinedTUSevents{1}));
shamPart = combinedData{1}(find(combinedTUSevents{1} == 0));
combinedTimes = {realPart;shamPart};

fig = figure();
set(fig, 'Position', [100, 100, 580, 450]);
ax1 = subplot(1,2,1);
ax2 = subplot(1,2,2);
hold(ax1, 'on');
hold(ax2, 'on');
xlabel(ax1, 'log frequency'); ylabel(ax1, 'power (dB/Hz)');
xlabel(ax2, 'Frequency'); ylabel(ax2, 'power (db/Hz)');
xlim(ax2, bandpass)
title(ax1, 'Non-oscillatory');
title(ax2, 'Oscillatory');
colors = [[0.9290 0.6940 0.1250], 'r'];
sgtitle(['Real trial'])
for ii = 1:size(combinedTimes,1)
    t = (1:size(combinedTimes{ii},1))/fs;
    data = [];
    data.trial{1,1} = combinedTimes{ii}';
    data.time{1,1} = t;
    data.label{1} = 'EMG';
    data.trialinfo(1,1) = 1;
    
    % chunk into trial segments for long/continuous trials
    cfg           = [];
    cfg.length    = 0.8; % freqency resolution = 1/2^floor(log2(cfg.length*0.9))
    cfg.overlap   = 0;
    data          = ft_redefinetrial(cfg, data);

    % compute the fractal and original spectra
    cfg               = [];
    cfg.foilim        = bandpass;
    cfg.pad           = 'nextpow2';
    cfg.method        = 'irasa';
    cfg.output        = 'fractal';
    fractal = ft_freqanalysis(cfg, data);
    cfg.output        = 'original';
    original = ft_freqanalysis(cfg, data);

    % subtract the fractal component from the power spectrum
    cfg               = [];
    cfg.parameter     = 'powspctrm';
    cfg.operation     = 'x2-x1';
    oscillatory = ft_math(cfg, fractal, original);

    % display the spectra in log-log scale
    plot(ax1, log(fractal.freq), log(fractal.powspctrm), colors(ii)); 
    plot(ax2, fractal.freq, log(oscillatory.powspctrm), colors(ii));
end
legend(ax1, {'Real', 'Sham'});
legend(ax2, {'Real', 'Sham'});

end