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
numTrials = 20;
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

% Check if we are doing real or sham. Set the globalPower accordingly
condition = input('\nSelect your stimulation location \n1-DN 0w sham\n2-DN 30w sham\n3-DN\n4-V1\n5-Lobule 8\n6-Lobule 5\nEnter a number:');
if isequal(condition, 1)
    globalPower = 1;
elseif ~isequal(condition, 1)
    globalPower = Power;
elseif ~isnumeric(condition)
    error('Please enter the number in the beginning of the condition instead of its name');
else
    error('Unknown input') 
end

% Get the depth measurement for the condition
Depth = input('\nEnter the depth measurement from modelling for this region: ');

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