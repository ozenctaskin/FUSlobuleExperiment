function fingerTappingExperiment()
    
% %% Code to connect to TPO .  Do not edit!
global NeuroFUS

% Add path to subfunctions
filePath = matlab.desktop.editor.getActiveFilename;
addpath(fullfile(fileparts(filePath), 'subfunctions'))    

%% Set fix parameters.
% Warning. Power below is the globalPower we want to use along with sham
% power which is set to 1. The script asks whether you need real or sham.
% If sham is selected, globalPower is 1, otherwise globalPower=Power. See
% line 34.
Power = 30000;
SonicDuration = 500000 ; %in microseconds
xdrCenterFreq = 500000;   % in hertz
PRP = 1000; % Pulse rep period in microseconds( 10us resolution ) MUST BE GREATER than burst length
burstLength = 300;   %  in microseconds( 10us resolution )

% Check if we are doing real or sham. Set the globalPower accordingly
condition = input('\nReal or sham: \n1-Sham \n2-Real:\n');
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
ports = serialportlist;
NFOpen(ports(end),1,1);

% Push variables to device
NFGlobalFrequency(NeuroFUS,xdrCenterFreq)
NFGlobalPower(NeuroFUS,globalPower);
NFBurstLength(NeuroFUS,burstLength);
NFPulseRepPeriod(NeuroFUS,PRP);
NFDuration(NeuroFUS,SonicDuration);
NFDepth(NeuroFUS,Depth);

% Set up experiment variables
darkGray = [0.7 0.7 0.7];
fig = figure('Color', darkGray, 'MenuBar', 'none', 'ToolBar', 'none');
axis off
hold on
set(gca, 'Color', darkGray)
set(gca, 'XTick', [], 'YTick', [])
axis([-1 1 -1 1])

total_duration = 5 * 60; % 5 minutes
flash_duration = 10;     % flashing period in seconds
rest_duration = 20;      % baseline period in seconds

% Show black fixation cross and wait once for "5"
cla
draw_fixation_cross('k')
wait_for_key('5')

% Run the experiment
tic
while toc < total_duration
    % Flash red/white at 2 Hz for 10 seconds
    flash_start = tic;
    while toc(flash_start) < flash_duration
        cla
        draw_fixation_cross('r')
        NFStart(NeuroFUS);
        pause(0.5)
        NFStop(NeuroFUS);
        cla
        draw_fixation_cross('w')
        pause(0.5)
    end
    
    % Black fixation for 20 seconds
    cla
    draw_fixation_cross('k')
    pause(rest_duration)
end

close(fig)
end

% Function for drawing a cross
function draw_fixation_cross(color)
    hold on
    armLength = 0.1;
    line([-armLength armLength], [0 0], 'Color', color, 'LineWidth', 6)  % horizontal
    line([0 0], [-armLength armLength], 'Color', color, 'LineWidth', 6)  % vertical
    hold off
    drawnow
end

% Function for a button press
function wait_for_key(target_key)
    while true
        waitforbuttonpress;
        key = get(gcf, 'CurrentCharacter');
        if strcmp(key, target_key)
            break
        end
    end
end
