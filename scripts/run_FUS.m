% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %         Ultrasound Neuromodulation MAIN Script.  v1.3  Nov 19, 2018
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% %% Code to connect to TPO .  Do not edit!
global NeuroFUS

%% Set fix parameters.
% Warning. Power below is the globalPower we want to use along with sham
% power which is set to 1. Trials are randomized. See line 71. 
numTrials = 30;
Power = 30000;
Depth = 70;  % in mm
SonicDuration = 500000 ; %in microseconds
xdrCenterFreq = 500000;   % in hertz
PRP = 1000; % Pulse rep period in microseconds( 10us resolution ) MUST BE GREATER than burst length
burstLength = 300;   %  in microseconds( 10us resolution )
%duty cycle = 50%

% % Offline params 
% PRP = 200000;
% burstLength = 20000;
% globalPower = 20000;
% xdrCenterFreq = 500000; 
% Depth = 50;  % in mm
% SonicDuration = 5000000 ; %in microseconds

%% Add path to subfunctions
filePath = matlab.desktop.editor.getActiveFilename;
addpath(fullfile(fileparts(filePath), 'subfunctions'))

%% Get subject info by asking an d create folders in Ozzy's dir
saveDir = 'C:\Ozzy\lobuleExperiment\data';
subjectID = input('Enter subject ID: ', 's');
subjectFolder = fullfile(saveDir, subjectID);
if ~isfolder(subjectFolder)
    mkdir(subjectFolder)
end

% Get stim location
locationID = input('Enter the number for stimulated region \n1-Dentate \n2-Lubule 8 \n3-Lobule 5 : ', 's');
if strcmp(locationID, '1')
    fileName = 'Dentate';
elseif strcmp(locationID, '2')
    fileName = 'Lubule 8';
elseif strcmp(locationID, '3')
    fileName = 'Lubule 5';
else
    error('Number not recognized enter 1 for dentate, 2 for lobule8, or 3 for lobule5') 
end

% Get today's date time
x = datetime(now,'ConvertFrom','datenum');
fileTime = [num2str(x.Day), '-', num2str(x.Month), '-', num2str(x.Year), '_', num2str(x.Hour) num2str(x.Minute)];

%% Connect to TPO
disp('Connecting to TPO....');
NFOpen('COM8',1,1);

%% Set up white noise and trial randomization
% White noise if we need it
freq = 44100;
duration = 1;
whiteNoise = randn(1, freq*duration);
 
% Trial randomization
trials = [ones(numTrials/2,1); zeros(numTrials/2,1)];
trials = trials(randperm(length(trials)));

%% START Treatment
for ii = 1:length(trials)
    if isequal(trials(ii), 0)
        globalPower = 1;
    else
        globalPower = Power;
    end
    NFGlobalFrequency(NeuroFUS,xdrCenterFreq)
    NFGlobalPower(NeuroFUS,globalPower);
    NFBurstLength(NeuroFUS,burstLength);
    NFPulseRepPeriod(NeuroFUS,PRP);
    NFDuration(NeuroFUS,SonicDuration);
    NFDepth(NeuroFUS,Depth);
    pause(1)
    fprintf(['Starting trial: ' num2str(ii) ' globalPower:' num2str(globalPower)  '\n']);
    sound(whiteNoise, freq)
    NFStart(NeuroFUS);
    pause(2)
    NFStop(NeuroFUS);
    pause(1)
end

% Save trial order
save(fullfile(subjectFolder, ['trialOrder_', subjectID, '_' fileName, '_', fileTime]), 'trials') 