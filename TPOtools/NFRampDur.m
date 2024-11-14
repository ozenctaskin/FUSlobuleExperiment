function NFRampDur(NeuroFUS,RampDur)
% this function sets the duration of the ramping up and down of the acoustic wave.
% NFRampDur accepts two input arguments: 1) NeuroFUS, the serial port
% object created by NFOpen and 2) RampDur, which specifies the duration of
% the ramp up and ramp down. This is entered in the unit of microseconds
% and has a lower limit of 10 microseconds and an upper limit of 20000
% microseconds (20 seconds).

if nargin < 1
    error('Not enough input arguments. NFRampDur accepts 2 input arguments: NeuroFUS and RampDur.')
elseif nargin == 2

    if RampDur < 10
        error('Error: Ramp mode integer is less than 10 microseconds. The integer must be between 10 and 20000 microseconds (20 ms).');
    elseif RampDur > 20000
        error('Error: Ramp mode integer is more than 20000 microseconds (20 seconds). The integer must be between 10 and 20000 microseconds (20 ms).');
    end

    rampdurstr = num2str(RampDur);
    fprintf(NeuroFUS,'%s\r',['RAMPLENGTH=',rampdurstr]); % send the commands to NeuroFUS.
end
end


