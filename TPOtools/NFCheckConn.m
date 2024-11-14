function NFOK = NFCheckConn(NeuroFUS)
% Function that checks whether the GUI has successfully connected to
% NeuroFUS. If successful, it returns the 

TPOStr = 'TPO'; % string to be found.

nChar = 24;
TPO = fread(NeuroFUS,nChar,'uint8'); % read the answer.
TPOChar = char(TPO); % convert the answer into char.
TPOChar = [TPOChar]';

TPOThere = strfind(TPOChar,TPOStr);

if TPOThere == 1
    NFOK = 1;
else
    NFOK = 0;
end

end

