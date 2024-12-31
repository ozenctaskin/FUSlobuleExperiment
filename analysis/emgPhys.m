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

% Combine cells
dataAll = [realStim; shamStim];
dataLabel = ['real'; 'sham'];
trialLength = {};
TUSevents = {};

% Loop through cell items and load the data in
[rowCount, colCount] = size(dataAll);
for row = 1:rowCount
    for col = 1:colCount
        loadedDataItem = load(dataAll{row, col});
        fields = fieldnames(loadedDataItem);
        trialLength{row, col} = size(loadedDataItem.(fields{2}).values(:,1,:), 1) / fs;
        dataAll{row, col} = reshape(loadedDataItem.(fields{2}).values(:,1,:), [], 1);
        TUSevents{row, col} = reshape(loadedDataItem.(fields{2}).values(:,2,:), [], 1);
    end
end

% If trial lengths are not equal, throw an error
if ~all(cellfun(@(x) isequal(x, trialLength{1,1}), trialLength(:)))
    error('Your trials are not in equal length. This is not supported')
end

% Append real with real and sham with sham
combinedData = cellfun(@(row) vertcat(row{:}), num2cell(dataAll, 2), 'UniformOutput', false);
combinedTUSevents = cellfun(@(row) vertcat(row{:}), num2cell(TUSevents, 2), 'UniformOutput', false);

% Set a time vector and bandpass values
t = (1:size(combinedData{1},1))/fs;
bandpass = [10 50];

%% Plot average measurements from trials
% Set figures
ax1 = subplot(1,2,1);
ax2 = subplot(1,2,2);
hold(ax1, 'on');
hold(ax2, 'on');
xlabel(ax1, 'Frequency'); ylabel(ax1, 'power (dB/Hz)');
xlabel(ax2, 'Frequency'); ylabel(ax2, 'power (db/Hz)');
xlim(ax1, bandpass)
xlim(ax2, bandpass)
title(ax1, 'Non-oscillatory');
title(ax2, 'Oscillatory');
colors = [[0.9290 0.6940 0.1250], 'r'];
sgtitle(['Trial average'])

% Loop through the real and sham data and plot components
for ii = 1:size(combinedData,1)
    data = [];
    data.trial{1,1} = combinedData{ii}';
    data.time{1,1} = t;
    data.label{1} = 'EMG';
    data.trialinfo(1,1) = 1;

    % chunk into trial segments for long/continuous trials
    cfg           = [];
    cfg.length    = trialLength{1}; % freqency resolution = 1/2^floor(log2(cfg.length*0.9))
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
    plot(ax1, fractal.freq, log(fractal.powspctrm), colors(ii)); 
    plot(ax2, fractal.freq, log(oscillatory.powspctrm), colors(ii));
end
legend(ax1, {'Real', 'Sham'});
legend(ax2, {'Real', 'Sham'});

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

figure()
ax1 = subplot(1,2,1);
ax2 = subplot(1,2,2);
hold(ax1, 'on');
hold(ax2, 'on');
xlabel(ax1, 'Frequency'); ylabel(ax1, 'power (dB/Hz)');
xlabel(ax2, 'Frequency'); ylabel(ax2, 'power (db/Hz)');
xlim(ax1, bandpass)
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
    cfg.length    = trialLength{1}; % freqency resolution = 1/2^floor(log2(cfg.length*0.9))
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
    plot(ax1, fractal.freq, log(fractal.powspctrm), colors(ii)); 
    plot(ax2, fractal.freq, log(oscillatory.powspctrm), colors(ii));
end
legend(ax1, {'Real', 'Sham'});
legend(ax2, {'Real', 'Sham'});

end