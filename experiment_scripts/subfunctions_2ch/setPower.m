function [out] = setPower(serialTPO,electricalWatts)
% setPower sets the power of the TPO in 1 watt increments.
%   setPower(serialTPO, electricalWatts)
%   Returns 0 if operation is succesfull

electricalWatts = round(electricalWatts);
outStr = ['POWER=' num2str(electricalWatts)];
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
