function NFGlobalPower(NeuroFUS,Power)
    % sets the power of all elements of the NeuroFUS transducer in Watts
    % (W). NeuroFUS is a 'COM' port object created using the 'NFOpen'
    % function (See the NFOpen function for more details). Power is an
    % integer, with a maximum of 60 and a minimum of (???)
    
    % evaluate the input arguments.
    if nargin < 2
        error('Not enough input arguments. NFGlobalPower requires two arguments: The NeuroFUS COM Port object and the global acoustic power')
    elseif nargin == 2 % enough input arguments, now check if they are ok.
        if ~isobject(NeuroFUS) % check if the NeuroFUS object exists.
        error('Serial port object for NeuroFUS must be provided (e.g. COM5). See NFOpen for more details');
        end
        
        PowStr = num2str(Power); % convert the frequency input to a string.
        fprintf(NeuroFUS,'%s\r',['GLOBALPOWER=',PowStr]); % send the data to the device.
    end
    
end

