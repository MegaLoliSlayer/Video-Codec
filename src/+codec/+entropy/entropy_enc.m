function Nbits = entropy_enc(data, outfile)
% Arithmetic-encode an integer array. Nbits includes header and histogram.

    if isempty(data)
        error('entropy_enc:empty', 'Input data is empty.');
    end
    if any(data(:) ~= round(data(:)))
        error('entropy_enc:notInteger', 'Input must be integers.');
    end

    sz      = size(data);
    x       = double(data(:)).';
    min_val = min(x);
    symbols = x - min_val + 1;
    M       = max(2, max(symbols));

    counts = accumarray(symbols.', 1, [M 1]).';
    counts(counts == 0) = 1;

    maxc = max(counts);
    if maxc <= intmax('uint8')
        cbytes = 1;  ctype = 'uint8';
    elseif maxc <= intmax('uint16')
        cbytes = 2;  ctype = 'uint16';
    else
        cbytes = 4;  ctype = 'uint32';
    end

    code = arithenco(symbols, counts);

    fid = fopen(outfile, 'wb');
    if fid < 0
        error('entropy_enc:fopen', 'Cannot open %s.', outfile);
    end
    fwrite(fid, numel(sz), 'uint8');
    fwrite(fid, sz,        'uint32');
    fwrite(fid, min_val,   'int32');
    fwrite(fid, M,         'uint32');
    fwrite(fid, cbytes,    'uint8');
    fwrite(fid, counts,    ctype);
    fwrite(fid, code,      'ubit1');
    fclose(fid);

    info  = dir(outfile);
    Nbits = info.bytes * 8;
end
