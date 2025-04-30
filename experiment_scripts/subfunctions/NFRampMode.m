function NFRampMode(NeuroFUS,RampMode)
% Accepts two arguments: 1) NeuroFUS: the serial port object used to
% connect to NeuroFUS and 2) Ramp mode: an integer argument ranging from 0
% to 4. The integer entered under ramp mode determines the model that
% defines how the ramping takes place, which is documented below:

% 0: no ramp.
% 1: linear ramp.
% 2: Tukey ramp.
% 3: log ramp.
% 4: exponential ramp.

if nargin < 1
    error('Not enough input arguments. NFRampMode accepts 2 input arguments: NeuroFUS and RampMode.')
elseif nargin == 2

    if RampMode < 0
        error('Error: Ramp mode integer is less than zero. The integer must be between 0 and 4.');
    elseif RampMode > 4
        error('Error: Ramp mode integer is more than 4. The integer must be between 0 and 4.');
    end

    rampstr = num2str(RampMode);
    fprintf(NeuroFUS,'%s\r',['RAMPMODE=',rampstr]); % send the commands to NeuroFUS.
end
end

