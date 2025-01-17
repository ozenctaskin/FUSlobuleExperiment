function [out] = startTPO(serialTPO)
% startTPO(serialTPO) initiates TPO output
%   Returns 0 if operation is succesfull

outStr = 'START';
fprintf(serialTPO,outStr);
reply = fscanf(serialTPO);
    switch reply
        case 'OK'
            out = 0;
        otherwise
            % Error condition
            out = 1;
    end
end
