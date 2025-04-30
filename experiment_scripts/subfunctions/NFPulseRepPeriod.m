function NFPulseRepPeriod(NeuroFUS,PRP)
    % Sets the pulse repetition frequency. This sets the frequency that each
    % burst (set using NFBurstLength) of ultrasound is repeated at during an
    % ultrasound protocol.

    % NFPulseRepFrequency accepts two arguments: NeuroFUS, which is the serial
    % port object used to communicate with NeuroFus, created using NFOpen. The
    % second argument is PRP, which is a number set in the unit of
    % microseconds. The minimum value is 10 microseconds and the maximum value
    % is 10ms. The PRP argument cannot be lower than the burst length set using
    % NFBurstLength.

    % evaluate the input arguments.
    if nargin < 2
        error('Not enough input arguments. NFBurstLength requires two arguments: The NeuroFUS COM Port object and the pulse repetition frequency (PRP)')
    elseif nargin == 2 % enough input arguments, now check if they are ok.
        if ~isobject(NeuroFUS) % check if the NeuroFUS object exists.
        error('Serial port object for NeuroFUS must be provided (e.g. COM5). See NFOpen for more details');
        end
        
        PRPStr = num2str(PRP); % convert the frequency input to a string.
        fprintf(NeuroFUS,'%s\r',['PERIOD=',PRPStr]); % send the data to the device.
    end

end

