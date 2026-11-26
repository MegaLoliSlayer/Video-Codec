function prediction = compensateMotion(reference, vectors, blockSize)
%COMPENSATEMOTION Build a prediction using [dy, dx] motion vectors.

arguments
    reference
    vectors
    blockSize = 16
end

[height, width] = size(reference);
prediction = zeros(size(reference), 'like', reference);

for blockRow = 1:size(vectors, 1)
    top = (blockRow - 1) * blockSize + 1;
    rows = top:min(top + blockSize - 1, height);

    for blockCol = 1:size(vectors, 2)
        left = (blockCol - 1) * blockSize + 1;
        cols = left:min(left + blockSize - 1, width);

        dy = double(vectors(blockRow, blockCol, 1));
        dx = double(vectors(blockRow, blockCol, 2));
        prediction(rows, cols) = reference(rows + dy, cols + dx);
    end
end
end