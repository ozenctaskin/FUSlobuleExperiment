% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %         Ultrasound Neuromodulation MAIN Script.  v1.3  Nov 19, 2018
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% %% Code to connect to TPO .  Do not edit!
global NeuroFUS

%% Set fix parameters.
% Warning. Power below is the globalPower we want to use along with sham
% power which is set to 1. The script asks whether you need real or sham.
% If sham is selected, globalPower is 1, otherwise globalPower=Power. See
% line 34.
numTrials = 15;
Power = 30000;
SonicDuration = 500000 ; %in microseconds
xdrCenterFreq = 500000;   % in hertz
PRP = 1000; % Pulse rep period in microseconds( 10us resolution ) MUST BE GREATER than burst length
burstLength = 300;   %  in microseconds( 10us resolution )

%% Add path to subfunctions
filePath = matlab.desktop.editor.getActiveFilename;
addpath(fullfile(fileparts(filePath), 'subfunctions'))

% %% Get subject info by asking and create folders in Ozzy's dir
% saveDir = 'C:\Ozzy\lobuleExperiment\data';
% subjectID = input('Enter subject ID: ', 's');
% subjectFolder = fullfile(saveDir, subjectID);
% if ~isfolder(subjectFolder)
%     mkdir(subjectFolder)
% end

% Get the depth measurement for the condition
Depth = input('\nEnter the depth measurement from modelling for this region: ');

% Check if we are doing real or sham. Set the globalPower accordingly
condition = input('\nWhat is the condition, r or s:', 's');
if strcmp(condition, 'r')
    globalPower = Power;
elseif strcmp(condition, 's')
    globalPower = 1;
else
    error('Enter r for real, s for sham') 
end

%% Connect to TPO
disp('\nConnecting to TPO....');
NFOpen('COM8',1,1);

% Setup variables 
NFGlobalFrequency(NeuroFUS,xdrCenterFreq)
NFGlobalPower(NeuroFUS,globalPower);
NFBurstLength(NeuroFUS,burstLength);
NFPulseRepPeriod(NeuroFUS,PRP);
NFDuration(NeuroFUS,SonicDuration);
NFDepth(NeuroFUS,Depth);
pause(3)

%% START Treatment
for ii = 1:numTrials
    fprintf(['Starting trial: ' num2str(ii) ' globalPower:' num2str(globalPower)  '\n']);
    NFStart(NeuroFUS);
    pause(1)
    NFStop(NeuroFUS);
    pause(4)
end