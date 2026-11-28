function frame = block_idct(coef, rows, cols)
% Inverse of block_dct.

    if size(coef, 1) ~= (rows/8) * (cols/8) || size(coef, 2) ~= 64
        error('block_idct:size', 'coef size does not match rows x cols.');
    end

    %Fix: revised based on quantizer interface
    [~, zag] = codec.quantization.init_jpegWithBlockSize(8, 50);

    frame = zeros(rows, cols);
    k = 0;
    for r = 1:8:rows
        for c = 1:8:cols
            k = k + 1;
            v = coef(k, :);
            frame(r:r+7, c:c+7) = idct2(v(zag));
        end
    end
end
