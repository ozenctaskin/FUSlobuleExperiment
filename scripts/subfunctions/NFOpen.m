function [NeuroFUS, NFOK] = NFOpen(COM,trigger,advanced)
% This creates a COM port object to communicate with the NeuroFUS device. 
% The address can be found in the device manager under 'Ports (COM & LPT)'
% under the name 'Arduino Due Programming Port', next to this in brackets
% it says COM followed by a number (e.g. 'COM5'). This is what it used as 
% the input for this function. For example, if COM5 is listed here, then
% NFOpen('COM5') should be entered. The address should be entered as a
% string.

% trigger is an optional argument, which can be 0 or 1. The trigger = 1,
% this means that the ultrasound protocol will start after a TTL pulse is
% sent into the 'trigger' port of the NeuroFUS device. The default is 0.

% the third argument 'advanced' is the third, optional arugment. If
% advanced is 1, this enables the power, frequency and phase of each
% element of the NeuroFUS transducer to be configured independently.

% NOTE: Make sure pause(1) is called after this function, otherwise 
% subsequent commands are not received by the device.

% Find a serial port object.
global NeuroFUS
NeuroFUS = instrfind('Type', 'serial', 'Port', COM, 'Tag', '');

% Create the serial port object if it does not exist
% otherwise use the object that was found.
if isempty(NeuroFUS)
    NeuroFUS = serial(COM);
else
    fclose(NeuroFUS);
    NeuroFUS = NeuroFUS(1);
end

set(NeuroFUS,'BaudRate',115200);
set(NeuroFUS,'DataBits',8);
set(NeuroFUS,'StopBits',1.0);
set(NeuroFUS,'Terminator','CR/LF');

% connect to the NeuroFUS
fopen(NeuroFUS);
NFOK = NFCheckConn(NeuroFUS);

pause(3)

if trigger == 1
     fprintf(NeuroFUS,'%s\r','TRIGGERMODE=1'); % send the data to the device.
     'External triggering enabled'
end

if advanced == 1
    fprintf(NeuroFUS,'%s\r','LOCAL=0'); % send the data to the device.
    'Advanced remote control enabled. Phase, power and frequency of each element can be independently configured.'
end
     

end

