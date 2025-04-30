function NFTrigger(NeuroFUS,triggering)
% Function that enables external triggering of NeuroFUS. Requires two
% arguments 'NeuroFUS', a COM port object created using 'NFOpen'.
% Triggering is a boolean: 0 means no external triggering; and 1 means
% extternal triggering is on, meaning that a stimulation protocol will
% begin when a TTL pulse is send to the 'trigger' port of NeuroFUS.
if triggering == 1
    fprintf(NeuroFUS,'%s\r','TRIGGERMODE=1'); % send the data to the device.
    'External triggering enabled'
elseif triggering == 0
    fprintf(NeuroFUS,'%s\r','TRIGGERMODE=0')
    'External triggering disabled'
end

end

