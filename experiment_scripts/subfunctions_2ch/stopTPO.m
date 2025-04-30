function [out] = stopTPO(serialTPO)
% stopTPO(serialTPO) stops TPO output
%   Returns 0 if operation is succesfull

outStr = 'ABORT';
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
