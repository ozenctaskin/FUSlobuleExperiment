function NFVolume(NeuroFUS,Volume)

if nargin < 1
    error('Not enough input arguments. NFRampMode accepts 2 input arguments: NeuroFUS and RampMode.')
elseif nargin == 2

    if Volume < 0
        error('Error: Ramp mode integer is less than zero. The integer must be between 0 and 3.');
    elseif Volume > 3
        error('Error: Ramp mode integer is more than 3. The integer must be between 0 and 3.');
    end

    volumestr = num2str(Volume);
    fprintf(NeuroFUS,'%s\r',['VOLUME=',volumestr]); % send the commands to NeuroFUS.
end
end

