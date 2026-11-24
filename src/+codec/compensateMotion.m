function prediction = compensateMotion(reference, vectors, blockSize)
%COMPENSATEMOTION Rebuild a prediction from a reference frame and motion.
%   VECTORS stores [dy, dx] offsets from each output block into REFERENCE.
%   Use the same BLOCKSIZE as in the estimator. The default is 16.

if nargin < 3
    blockSize = 16;
end

frameTypes = {'uint8', 'uint16', 'single', 'double'};
validateattributes(reference, frameTypes, {'2d', 'nonempty', 'real', 'finite'}, mfilename, 'reference');
validateattributes(vectors, {'numeric'}, {'integer', 'real', 'finite'}, mfilename, 'vectors');
validateattributes(blockSize, {'numeric'}, {'scalar', 'integer', 'positive', 'finite'}, mfilename, 'blockSize');

blockSize = double(blockSize);
[height, width] = size(reference);
rowStarts = 1:blockSize:height;
colStarts = 1:blockSize:width;
if ~isequal(size(vectors), [numel(rowStarts), numel(colStarts), 2])
    error('codec:MotionGridSizeMismatch', 'Motion vectors must provide [dy, dx] for each block.');
end

prediction = zeros(size(reference), 'like', reference);
for blockRow = 1:numel(rowStarts)
    rows = rowStarts(blockRow):min(rowStarts(blockRow) + blockSize - 1, height);

    for blockCol = 1:numel(colStarts)
        cols = colStarts(blockCol):min(colStarts(blockCol) + blockSize - 1, width);
        sourceRows = rows + double(vectors(blockRow, blockCol, 1));
        sourceCols = cols + double(vectors(blockRow, blockCol, 2));
        if sourceRows(1) < 1 || sourceRows(end) > height || ...
                sourceCols(1) < 1 || sourceCols(end) > width
            error('codec:MotionVectorOutOfBounds', ...
                'Motion vector for block (%d, %d) points outside the reference frame.', blockRow, blockCol);
        end
        prediction(rows, cols) = reference(sourceRows, sourceCols);
    end
end
end
