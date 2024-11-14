function NFGlobalFrequency(NeuroFUS,Frequency)
% NFGlobalFrequencey sets the acoustic frequency of all elements within the
% NeuroFUS transducer. NeuroFUS is a 'COM' port object created using the 'NFOpen'
% function. Frequency is an integer entered in units of Hz. For example, if the
% desired acoustic frequency is 1500.000 kHz, then the frequency argument
% for this function would be 1500000.
nChar = 32;

% evaluate the input arguments.
    if nargin < 2
        error('Not enough input arguments. NFGlobalFrequency requires two arguments: The NeuroFUS COM Port object and the global acoustic frequency')
    elseif nargin == 2 % enough input arguments, now check if they are ok.
        if ~isobject(NeuroFUS) % check if the NeuroFUS object exists.
            error('Serial port object for NeuroFUS must be provided (e.g. COM5). See NFOpen for more details');
        end
        
        FreqStr = num2str(Frequency); % convert the frequency input to a string.
        fprintf(NeuroFUS,'%s\r',['GLOBALFREQ=',FreqStr]); % send the data to the device 
        params = char(fread(NeuroFUS,nChar,'uint8')); % read the answer.
    end

end

