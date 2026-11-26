function prediction = compensateMotion(reference, vectors, blockSize)
%COMPENSATEMOTION Build a prediction from the reference frame and [dy, dx] vectors

arguments
    reference
    vectors
    blockSize = 16
end

[height, width] = size(reference);
%Keep the reference frame's size and pixel type
prediction = zeros(size(reference), 'like', reference);

%Clip the block rows and columns at the frame edges
for blockRow = 1:size(vectors, 1)
    top = (blockRow - 1) * blockSize + 1;
    rows = top:min(top + blockSize - 1, height);

    for blockCol = 1:size(vectors, 2)
        left = (blockCol - 1) * blockSize + 1;
        cols = left:min(left + blockSize - 1, width);

        %Add the offsets to find the matching block in the reference frame
        dy = double(vectors(blockRow, blockCol, 1));
        dx = double(vectors(blockRow, blockCol, 2));
        prediction(rows, cols) = reference(rows + dy, cols + dx);
    end
end
end