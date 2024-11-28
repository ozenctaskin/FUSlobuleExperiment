function NFChannelFrequency(NeuroFUS,channel,frequency)
% NFChannelFrequency enables the acoustic frequency of each element to be set
% independently. NFChannelFrequency accepts 3 arguments. The first argument
% is the serial port object used to communicate with NeuroFUS, created using NFOpen.
% The second argument is the channel being programmed, which is an integer
% between 1 and 4. The third argument is the desired acoustic frequency of
% the channel being configured. The unit that frequency is set in is in
% Hz.

if nargin < 2
    error('Not enough input arguments. Requires 3 inputs: NeuroFUS serial port object, the channel and the phase.')
elseif nargin == 3 % proceed
    if ~isobject(NeuroFUS) % check if the NeuroFUS object exists.
        error('Serial port object for NeuroFUS must be provided (e.g. COM5). See NFOpen for more details');
    end
    
    % check the channel argument is ok.
    if channel > 4
        error('Channel argument not valid. Input needs to be an integer between 1 and 4, corresponding to the element of the NeuroFUS transducer being configured')
    elseif channel < 1
        error('Channel argument not valid. Input needs to be an integer between 1 and 4, corresponding to the element of the NeuroFUS transducer being configured')
    end
    
    % check the acoustic frequency argument
    
    % all is ok - proceed
    
    ChanStr = num2str(channel); % convert the channel to a string.
    FreqStr = num2str(frequency);
    
    fprintf(NeuroFUS,'%s\r',['FREQ',ChanStr,'=',FreqStr]); % send the data to the device.
end

