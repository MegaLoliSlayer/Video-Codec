repoRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(repoRoot, 'src'));
img = double(imread(fullfile(repoRoot, 'data', 'lena512.bmp')));
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

%Fix: request size 16 table instead of 8
[qt_16, zag_16] = codec.quantization.init_jpegWithBlockSize(16, 30);

for row = 1:16:(height - 15)
    for col = 1:16:(width - 15)
        block = img(row:row+15, col:col+15);

        coeffs = dct2(block);
        
        %Fix: added codec.quantization to both of these calls so Matlab
        %knows where to find the functions
        quantizedVector = codec.quantization.quantizeCoeffBlock(coeffs, qt_16, zag_16, 16);

        dequantizedBlock = codec.quantization.dequantizeCoeffVector(quantizedVector, qt_16, zag_16, 16);

    end
end