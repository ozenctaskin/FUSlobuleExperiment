function [out] = setTimer(serialTPO, timerSeconds)
% setTimer sets the treatment timer in 1 second intervals.
%   setTimer(serialTPO, timerSeconds)
%   Returns 0 if operation is succesfull

timerSeconds = round(timerSeconds);
outStr = ['TIME=' num2str(timerSeconds)];
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
