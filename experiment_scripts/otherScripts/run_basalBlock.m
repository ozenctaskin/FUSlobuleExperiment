% Add subfunctions to path 
filePath = matlab.desktop.editor.getActiveFilename;
addpath(fullfile(fileparts(filePath), 'subfunctions'));
addpath(fullfile(fileparts(filePath), 'subfunctions_2ch'));

% Configure 2ch and 4ch
global NeuroFUS
global serialTPO

numTrials = 30;
Power4ch = 30000;
SonicDuration = 500000 ; %in microseconds
xdrCenterFreq = 500000;   % in hertz
PRP = 1000; % Pulse rep period in microseconds( 10us resolution ) MUST BE GREATER than burst length
burstLength = 300;   %  in microseconds( 10us resolution )

realOrSham = input('\n1-Real or 2-Sham: ');
Depth_2ch = input('\nEnter the depth for 2 channel: ');
Depth_4ch = input('\nEnter the depth for 4 channel: ');

if isequal(realOrSham, 1)
    Power2Ch = 40;
elseif isequal(realOrSham, 2)
    Power2Ch = 0;
else
    error('Enter 1 or 2');
end

% Connect to 4ch
disp('\nConnecting to 4ch TPO....');
NFOpen('COM8',1,1);

NFGlobalFrequency(NeuroFUS,xdrCenterFreq)
NFGlobalPower(NeuroFUS,Power4ch);
NFBurstLength(NeuroFUS,burstLength);
NFPulseRepPeriod(NeuroFUS,PRP);
NFDuration(NeuroFUS,SonicDuration);
NFDepth(NeuroFUS,Depth_4ch);
NFTrigger(NeuroFUS,1)
pause(1)

%% Connect to 2ch
disp('\nConnecting to 2ch TPO....');
serialTPO = serial('COM4');
set(serialTPO,'BaudRate',9600);
set(serialTPO,'DataBits',8);
set(serialTPO,'StopBits',1.0);
set(serialTPO,'Terminator','CR/LF');
fopen(serialTPO);
pause(3);

setLocal(serialTPO,0);
setFreq(serialTPO,0,xdrCenterFreq/1000);
setPower(serialTPO,Power2Ch);
setBurst(serialTPO,burstLength);
setPRF(serialTPO,1/(PRP/1000000));
setTimer(serialTPO, 50);
setDepth(serialTPO,Depth_2ch);
pause(1)

% Run treatment 
for ii = 1:numTrials
    fprintf(['Starting trial: ' num2str(ii) ' 2chPow:' num2str(Power2Ch) 'and 4chPow ' num2str(Power4ch) '\n']);
    startTPO(serialTPO);
    pause(1)
    stopTPO(serialTPO);
    pause(4)
end

fclose(instrfind);  % Close if anything is open
delete(instrfind);  % Delete all instrument objects
clear instrfind     % Clear from memory
