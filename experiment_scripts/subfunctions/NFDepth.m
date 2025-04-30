function NFDepth(NeuroFUS,depth,utx)
% Function that configures NeuroFUS to adjust the focus depth, which
% determines the point in the brain where the intensity of ultrasound is
% greatest. Accepts two arguments: NeuroFUS, a COM port objected created
% using NFOpen, and depth. Depth is entered in the unit of millmeters and
% accepts arguments with up to 1 decimal point. If a uTx transducer is
% used, enter a third argument as a 1, indicating that the uTx transducer
% with a different steering range is used.

if nargin == 2
    if depth < 30
        error('Error: Depth value is too low and outside the steering range of NeuroFUS. Please enter a value more than 30mm and less than 70mm.')
    elseif depth > 80.51
        error('Error: Depth value is too high (> 80.51mm) and outside the steering range of NeuroFUS. Please enter a value less than 80.51mm.')
    end
elseif nargin == 3
    if depth > 10
        error('Error: Depth value is too high and outside the steering range of NeuroFUS. Please enter a value less than 10mmm.');
    end
end

depth = num2str(depth*1000); % convert it to micrometers.
fprintf(NeuroFUS,'%s\r',['FOCUS=',depth]); % send the commands to NeuroFUS.
end

