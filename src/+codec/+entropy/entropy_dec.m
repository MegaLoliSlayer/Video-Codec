function data = entropy_dec(infile)
% Decode a file written by entropy_enc.

    fid = fopen(infile, 'rb');
    if fid < 0
        error('entropy_dec:fopen', 'Cannot open %s.', infile);
    end
    nd      = fread(fid, 1,  'uint8');
    sz      = fread(fid, nd, 'uint32').';
    min_val = fread(fid, 1,  'int32');
    M       = fread(fid, 1,  'uint32');
    cbytes  = fread(fid, 1,  'uint8');

    switch cbytes
        case 1, ctype = 'uint8';
        case 2, ctype = 'uint16';
        case 4, ctype = 'uint32';
        otherwise, fclose(fid); error('entropy_dec:header', 'Bad header.');
    end
    counts = fread(fid, M, ctype).';
    code   = fread(fid, inf, 'ubit1');
    fclose(fid);

    symbols = arithdeco(code, counts, prod(sz));
    data    = reshape(symbols + min_val - 1, sz);
end
