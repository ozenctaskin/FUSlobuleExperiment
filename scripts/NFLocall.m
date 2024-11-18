function NFLocal(NeuroFUS,setlocal)
% 
if setlocal == 1
    fprintf(NeuroFUS,'%s\r','LOCAL=1'); % send the data to the device.
    
elseif setlocal == 0
    fprintf(NeuroFUS,'%s\r','LOCAL=0')
    
end

end

