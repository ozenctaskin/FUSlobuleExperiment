function NFChannelPower(NeuroFUS,channel,power)
% NFChannelPower enables the power of each element within the NeuroFUS
% transducer to be configured independently. The unit of this input is
% milliwatts. The first argument is NeuroFUS, which is the serial port object 
% used to communicate with NeuroFUS, created using NFOpen. The second
% argument is channel, which needs to be an integer between 1 and 4. The
% third argument is the acoustic power of the channel being configured. The
% unit of acoustic power is milliwatts (mW), and can be set in 0.1 mW
% increments.

if nargin < 3
    error('Not enough input arguments. Requires 3 inputs: NeuroFUS serial port object, the channel and the power')
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
    
    % check the power 
    
    
    % all is ok - proceed
    
    ChanStr = num2str(channel); % convert the channel to a string.
    PowStr = num2str(power);
    
    fprintf(NeuroFUS,'%s\r',['POWER',ChanStr,'=',PowStr]); % send the data to the device.
    
end

