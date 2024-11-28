function NFStop(NeuroFUS)
% aborts a NeuroFUS protocol.
fprintf(NeuroFUS,'%s\r','ABORT'); % send the data to the device.
end

