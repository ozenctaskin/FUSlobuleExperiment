function NFDuration(NeuroFUS,Duration)
    % NFDuration sets the overall duration of a NeuroFUS protocol. NFDuration
    % accepts two arugments: 1) NeuroFUS: the serial port object used to communicate
    % with NeuroFus, created using NFOpen. 2) The duration of the FUS
    % protocol set in the unit of microseconds. This ranges from 1 second to 600 seconds 
    % and can be set in increments of 10 microseconds between these two values. Duration is
    % set in the unit of microseconds.
    
    % evaluate the input arguments.
    if nargin < 2
        error('Not enough input arguments. NFBurstLength requires two arguments: The NeuroFUS COM Port object and the duration of the FUS protocol.')
    elseif nargin == 2 % enough input arguments, now check if they are ok.
        if ~isobject(NeuroFUS) % check if the NeuroFUS object exists.
            error('Serial port object for NeuroFUS must be provided (e.g. COM5). See NFOpen for more details');
        end
        
        DurStr = num2str(Duration); % convert the frequency input to a string.
        fprintf(NeuroFUS,'%s\r',['TIMER=',DurStr]); % send the data to the device.
    end
end

