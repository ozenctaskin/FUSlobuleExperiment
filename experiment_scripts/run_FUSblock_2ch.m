% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %         Ultrasound Neuromodulation MAIN Script.  v1.3  Nov 19, 2018
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% %% Code to connect to TPO .  Do not edit!
%% Code to connect to TPO .  Do not edit!
disp('Connecting to TPO....');
addpath('TPOcommands') % adds functions for issuing TPO commands to workspace
if exist('serialTPO', 'var') % Code to clear com port if code was aborted
    try
        fclose(serialTPO);
        delete(serialTPO);
    catch
        delete(serialTPO);
        
    end
end
newobjs = instrfind;
if ~isempty(newobjs)
    fclose(newobjs);
end
try
    COMports = comPortSniff; % cell containing string identifier of com port
catch
    error('No COM ports found, please check TPO');
end
% Removes any empty cells
COMports = COMports(~cellfun('isempty',COMports));
len = length(COMports(:));
COMports = reshape(COMports,[len/2 2]);
tempInd = strfind(COMports(:,1), 'Arduino Due');
indTPO = find(not(cellfun('isempty', tempInd)));
if isempty(indTPO)
    error( 'No TPO detected, please check your USB and power connections')
end
indTPO = indTPO(1);
disp(['COM port: ' num2str(indTPO) '-' COMports{indTPO,1}]);
serialTPO = serial(['COM' num2str(COMports{indTPO,2})],'BaudRate', 9600,'DataBits', 8, 'Terminator', 'CR');
fopen(serialTPO);
pause(3)
%%java.lang.Thread.sleep(3*1000)  % in mysec!
reply = fscanf(serialTPO);
disp(reply)
reply = fscanf(serialTPO);
disp(reply)
setLocal(serialTPO,0); %% Changes TPO control to script commands. Wont respond to most front panel parameters

%% Set fix parameters.
% Warning. Power below is the globalPower we want to use along with sham
% power which is set to 1. The script asks whether you need real or sham.
% If sham is selected, globalPower is 1, otherwise globalPower=Power. See
% line 34.
numTrials = 5;
Power = 30;
SonicDuration = .5 ; %in microseconds
xdrCenterFreq = 500;   % in hertz
PRF = 1000; % Pulse rep period in microseconds( 10us resolution ) MUST BE GREATER than burst length
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
condition = input('\nWhat is the condition, r or s (Enter r for real, s for sham):', 's');
if strcmp(condition, 'r')
    globalPower = Power;
elseif strcmp(condition, 's')
    globalPower = 1;
else
    error('Enter r for real, s for sham') 
end

% Setup
setFreq(serialTPO,0,xdrCenterFreq); % with '0' as the second argument, freq is assigned to all channels
setPower(serialTPO,globalPower);             % always set power after frequency or you may limit TPO
setBurst(serialTPO,burstLength);
setPRF(serialTPO,PRF);             % in Hz
setTimer(serialTPO,((SonicDuration*100)));              % Timer, also adjusts for the 10 ms error of TPO
setDepth(serialTPO,Depth);
pause(3)

%% START Treatment
for ii = 1:numTrials
    fprintf(['Starting trial: ' num2str(ii) ' globalPower:' num2str(globalPower)  '\n']);
    startTPO(serialTPO);
    pause(1)
    stopTPO(serialTPO);
    pause(4)
end