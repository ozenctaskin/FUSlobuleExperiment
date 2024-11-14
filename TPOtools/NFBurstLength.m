function NFBurstLength(NeuroFUS,Burst)
    % FUS consists of a series of bursts of ultrasound. These bursts are of the
    % set acoustic frequency and set acoustic power. NFBurstLength, sets the
    % duration of each burst of ultrasound. Each burst of ultrasound is repeated
    % at the pulse repetition period, set using the NFPulseRep function.
    % NFBurstLength accepts two arguments, NeuroFUS, which is the serial port
    % object created by NFOpen to connect to the NeuroFUS device. 

    % The second  argument is 'Burst', which is set in the unit of microseconds. 
    % The lowest burst length is 10 microsecons and the maximum burst length is
    % 10ms. NB: The burst argument cannot be longer than the pulse repetition
    % period set by NFPulseRep. The unit that burst is set in is
    % microseconds.

    % evaluate the input arguments.
    if nargin < 2
        error('Not enough input arguments. NFBurstLength requires two arguments: The NeuroFUS COM Port object and the burst duration')
    elseif nargin == 2 % enough input arguments, now check if they are ok.
        if ~isobject(NeuroFUS) % check if the NeuroFUS object exists.
        error('Serial port object for NeuroFUS must be provided (e.g. COM5). See NFOpen for more details');
        end
        
        BurstStr = num2str(Burst); % convert the frequency input to a string.
        fprintf(NeuroFUS,'%s\r',['BURST=',BurstStr]); % send the data to the device.
    end

end

