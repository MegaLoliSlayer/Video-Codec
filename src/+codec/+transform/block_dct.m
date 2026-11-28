function coef = block_dct(frame)
% 8x8 block DCT. Returns one row per block, 64 coefficients in zig-zag order.

    [rows, cols] = size(frame);
    if mod(rows, 8) ~= 0 || mod(cols, 8) ~= 0
        error('block_dct:size', 'Frame dimensions must be multiples of 8.');
    end

    %fix: revised based on quantizer interface
    [~, zag] = codec.quantization.init_jpegWithBlockSize(8, 50);
    frame = double(frame);

    coef = zeros((rows/8) * (cols/8), 64);
    k = 0;
    for r = 1:8:rows
        for c = 1:8:cols
            blk = dct2(frame(r:r+7, c:c+7));
            v = zeros(1, 64);
            v(zag(:)) = blk(:);
            k = k + 1;
            coef(k, :) = v;
        end
    end
end
