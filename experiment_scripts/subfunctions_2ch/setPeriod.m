function [out] = setPeriod(serialTPO,burstPeriod)
% setPeriod sets the burst period in 1ms increments.
%   setPeriod(serialTPO,burstPeriod)
%   Returns 0 if operation is succesfull

Period = round(burstPeriod);
outStr = ['RATEP=' num2str(Period)];
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
