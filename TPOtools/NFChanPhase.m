function NFChanPhase(NeuroFUS,channel,degrees)
% NFChanPhase enables the phase of each channel to be configured
% independently. The first argument is NeuroFUS, which is the serial port
% object used by NFOpen. 
% This can be set by a value ranging from 0 to 360 in the
% unit of degrees (phase can be set 0.1 degree steps) Changing the phase can introduces a delay to the delivery
% of ultrasound. If the phase value is 0 in every channel, there is no
% delay to the delivery of ultrasound.

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
    DegStr = num2str(degrees);
    
    fprintf(NeuroFUS,'%s\r',['PHASE',ChanStr,'=',DegStr]); % send the data to the device.
end

