function [out] = setPRF(serialTPO,pulseRepetitionFrequency)
% setPRF sets the pulse repetition frequency in 1Hz increments.
%   setPRF(serialTPO, pulseRepetitionFrequency)
%   Returns 0 if operation is succesfull

PRF = round(pulseRepetitionFrequency);
outStr = ['RATE=' num2str(PRF)];
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
