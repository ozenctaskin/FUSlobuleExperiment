function [out] = setLocal(serialTPO,local)
% setFreq sets the TPO into either local mode(1) or remote(0)
%   setLocal(serialTPO, local)
%   Returns 0 if operation is succesful

if local == 0
    outStr = ['LOCAL=NO'];
    fprintf(serialTPO,outStr);
    reply = fscanf(serialTPO);
    switch reply(2:3)
        case 'NO'
            out = 0;
        otherwise
            % Error condition
            out = 1;
    end
    
else
    outStr = ['LOCAL=YES'];
    
    fprintf(serialTPO,outStr);
    reply = fscanf(serialTPO);
    switch reply(2:4)
        case 'YES'
            out = 0;
        otherwise
            % Error condition
            out = 1;
    end
end
end
