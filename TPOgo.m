% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %         Ultrasound Neuromodulation MAIN Script.  v1.3  Nov 19, 2018
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% %% Code to connect to TPO .  Do not edit!
global NeuroFUS

disp('Connecting to TPO....');
NFOpen('COM8',1,1)


%% FIXED SONICATION PARAMETERS
% 
Depth = 50;  % in mm
SonicDuration = 500000 ; %in microseconds
xdrCenterFreq = 500000;   % in hertz
PRP = 1000; % Pulse rep period in microseconds( 10us resolution ) MUST BE GREATER than burst length
burstLength = 300;   %  in microseconds( 10us resolution )
globalPower = 1; % 30000
%duty cycle = 50%

% % Offline 
% PRP = 200000;
% burstLength = 20000;
% globalPower = 20000;
% SonicDuration = 1000000;
% xdrCenterFreq = 500000; 
% Depth = 50;  % in mm
% SonicDuration = 5000000 ; %in microseconds

%% Sets burst parameter commands to TPO
% NFGlobalFrequency(NeuroFUS,xdrCenterFreq); % 
NFGlobalPower(NeuroFUS,globalPower);             % always set power after frequency or you may limit TPO
NFBurstLength(NeuroFUS,burstLength);
NFPulseRepPeriod(NeuroFUS,PRP);             % in Hz
NFDuration(NeuroFUS,SonicDuration);              % Timer, also adjusts for the 10 ms error of TPO
NFDepth(NeuroFUS,Depth);
% NFRampMode(NeuroFUS,rampmode);
% NFRampLength(NeuroFUS,200);
pause(1);                           % slight delay for TPO to update parameters

%% Display calculated parameters of burst
disp(['Sonication #' num2str(i) ' :'])
disp(' ');
disp(['Fund. Frequency: ' num2str(xdrCenterFreq) ' kHz']);
disp(['Depth: ' num2str(Depth) ' mm']);
disp(['Power: 20000  milliWatts']);
disp(['Sonication Duration: ' num2str(SonicDuration) ' seconds']);
disp(['Burst Duration: ' num2str(burstLength) ' us']);
disp(['PRP: ' num2str(PRP) ' us']);
disp(' ');
disp(' ');

% %% Set up some stuff we might not use
% % White noise if we need it
% freq = 44100;
% duration = 1;
% whiteNoise = randn(1, freq*duration);
% 
% % Trial randomization
% numTrials = 20;
% trials = [ones(numTrials/2,1); zeros(numTrials/2,1)];
% trials = trials(randperm(length(trials)));


%% START Treatment
for ii = 1:20
    fprintf(['Starting trial: ' num2str(ii) '\n']);
    NFStart(NeuroFUS);
    pause(2)
    NFStop(NeuroFUS);
    pause(3)
 end
