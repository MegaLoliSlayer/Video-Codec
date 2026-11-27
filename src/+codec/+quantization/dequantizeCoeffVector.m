function coeffs = dequantizeCoeffVector(vec, qt, zag, blockSize)
    %Takes as input the blockSize*blockSize input vector, dequantizes it, and
    %reshapes it into a blockSize*blockSize matrix

    for row = 1:blockSize
        for col = 1:blockSize
            rowVec = vec .* qt;
    
        end
    end
    
    % Undo the encoder's zigzag ordering
    coeffs = reshape(rowVec(zag(:)), blockSize, blockSize);
end