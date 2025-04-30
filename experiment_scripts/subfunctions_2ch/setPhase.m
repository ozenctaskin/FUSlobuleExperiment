function [out] = setPhase(serialTPO, channel, phase)
    % setPhase set the phase of a particular TPO channel
    %   setPhase(serialTPO, channel, Theta) sets phase angle of Chan
    %   Returns 0 if operation is succesfull

    while phase < 0
        phase = phase + 2*pi;
    end

    while phase > 2*pi
        phase = phase - 2*pi;
    end

    phaseReg = phase*4095/(2*pi);

    outStr = ['PHASE' num2str(channel) '=' num2str(phaseReg)];
    fprintf(serialTPO,outStr);
    reply = fscanf(serialTPO);
    switch reply
        case 'OK'
            out = 0;
        otherwise
            % Error condition
            out = 1;
    end
    %pause(0.01)
end
