function NFChannelPhase(NeuroFUS,channel,degrees)
% NFChanPhase enables the phase of each channel to be configured
% independently. This can be set by a value ranging from 0 to 360 in the
% unit of degrees. Changing the phase can introduces a delay to the delivery
% of ultrasound. Phase is entered as an integer but in reality, a decimal
% place is between the third a fourth digit in this integer so bear this in
% mind when programming the device.
% If the phase value is 0 in every channel, there is no
% delay to the delivery of ultrasound. NFChannelPhase acccepts 3 arguments.
% 1) NeuroFUS is a serial port object created by the NFOpen function 2) is
% the channel being configured and argument 3) is the phase which is set in
% degrees.

if nargin < 3
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
    
    % check the phase argument
    if degrees < 0 
        error('Phase argument less than zero. Phase needs to be between 0 and 360 degrees')
    elseif degrees > 360
        error('Phase argument more than 360. Phase needs to be between 0 and 360 degrees')
    end
    
    % all is ok - proceed
    
    ChanStr = num2str(channel); % convert the channel to a string.
    PhaseStr = num2str(degrees);
    
    fprintf(NeuroFUS,'%s\r',['PHASE',ChanStr,'=',PhaseStr]); % send the data to the device.
end

