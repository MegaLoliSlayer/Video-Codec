function x = quantizeCoeffBlock(block, qt, zag, blockSize)
%Function takes as input the 8x8 or 16x16 DCT coefficient matrix
%Function Returns a flattened 1D Quantized array of the coefficient block
x = zeros(1, blockSize*blockSize);

for i = 1:blockSize
    for j = 1:blockSize
        x(zag(i,j)) = block(i,j);
    end
end

x = round(x ./ qt);
end
