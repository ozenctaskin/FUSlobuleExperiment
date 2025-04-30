function [out] = setFreq(serialTPO, channel, frequency)
% setFreq sets the frequency of a particular TPO channel in kHz
%   setFreq(serialTPO, channel, frequency)
%   Returns 0 if operation is succesful
frequency = round(frequency);
if channel == 0
    outStr = ['FREQ=' num2str(frequency)];
else
    outStr = ['FREQ' num2str(channel) '=' num2str(frequency)];
end
fprintf(serialTPO,outStr);
reply = fscanf(serialTPO);
switch reply
    case 'OK'
        out = 0;
    otherwise
        % Error condition
        out = 1;
end
%pause(0.05)
end
