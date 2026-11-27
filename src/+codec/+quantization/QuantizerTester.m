img = double(imread("lena512.bmp"));
[height, width, channels] = size(img);

[qt_8, zag_8] = codec.quantization.init_jpegWithBlockSize(8, 30);

for row = 1:8:(height - 7)
    for col = 1:8:(width - 7)
        block = img(row:row+7, col:col+7);

        coeffs = dct2(block);

        quantizedVector = codec.quantization.quantizeCoeffBlock(coeffs, qt_8, zag_8, 8);

        dequantizedBlock = codec.quantization.dequantizeCoeffVector(quantizedVector, qt_8, zag_8, 8);

    end
end

[qt_16, zag_16] = codec.quantization.init_jpegWithBlockSize(8, 30);

for row = 1:16:(height - 15)
    for col = 1:16:(width - 15)
        block = img(row:row+15, col:col+15);

        coeffs = dct2(block);

        quantizedVector = quantizeCoeffBlock(coeffs, qt_16, zag_16, 16);

        dequantizedBlock = dequantizeCoeffVector(quantizedVector, qt_16, zag_16, 16);

    end
end