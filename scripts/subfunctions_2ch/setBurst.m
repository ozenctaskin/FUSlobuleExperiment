function [out] = setBurst(serialTPO, microseconds)
% setBurst sets the burst length of the TPO in 10 microsecond intervals
%   setBurst(serialTPO, burstMicroseconds)
%   Returns 0 if operation is succesfull

microseconds = round(microseconds/10)*10;
outStr = ['BURST=' num2str(microseconds)];
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
