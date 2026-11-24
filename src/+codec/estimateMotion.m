function [vectors, candidateCounts] = estimateMotion(current, reference, blockSize, searchRadius)
%ESTIMATEMOTION Find integer-pixel motion vectors by full-search SAD.
%   CURRENT and REFERENCE are same-size grayscale frames. REFERENCE is the
%   previous reconstructed frame when this function is used in the codec.
%   VECTORS(blockRow, blockCol, :) stores [dy, dx]. Add the offsets to
%   coordinates in CURRENT to locate the matching block in REFERENCE.
%   CANDIDATECOUNTS records how many positions were scored for each block.

if nargin < 3
    blockSize = 16;
end
if nargin < 4
    searchRadius = 8;
end

frameTypes = {'uint8', 'uint16', 'single', 'double'};
validateattributes(current, frameTypes, {'2d', 'nonempty', 'real', 'finite'}, mfilename, 'current');
validateattributes(reference, frameTypes, {'2d', 'nonempty', 'real', 'finite'}, mfilename, 'reference');
validateattributes(blockSize, {'numeric'}, {'scalar', 'integer', 'positive', 'finite'}, mfilename, 'blockSize');
validateattributes(searchRadius, {'numeric'}, {'scalar', 'integer', 'nonnegative', 'finite'}, mfilename, 'searchRadius');
if ~isequal(size(current), size(reference))
    error('codec:FrameSizeMismatch', 'Current and reference frames must have the same size.');
end

current = double(current);
reference = double(reference);
blockSize = double(blockSize);
searchRadius = double(searchRadius);
[height, width] = size(current);
rowStarts = 1:blockSize:height;
colStarts = 1:blockSize:width;
vectors = zeros(numel(rowStarts), numel(colStarts), 2);
candidateCounts = zeros(numel(rowStarts), numel(colStarts));

for blockRow = 1:numel(rowStarts)
    rows = rowStarts(blockRow):min(rowStarts(blockRow) + blockSize - 1, height);
    rowOffsets = max(-searchRadius, 1 - rows(1)):min(searchRadius, height - rows(end));

    for blockCol = 1:numel(colStarts)
        cols = colStarts(blockCol):min(colStarts(blockCol) + blockSize - 1, width);
        colOffsets = max(-searchRadius, 1 - cols(1)):min(searchRadius, width - cols(end));
        target = current(rows, cols);

        bestCost = Inf;
        bestDistance = Inf;
        for dy = rowOffsets
            for dx = colOffsets
                candidate = reference(rows + dy, cols + dx);
                cost = sum(abs(target - candidate), 'all');
                distance = dy ^ 2 + dx ^ 2;
                if cost < bestCost || (cost == bestCost && distance < bestDistance)
                    bestCost = cost;
                    bestDistance = distance;
                    vectors(blockRow, blockCol, 1) = dy;
                    vectors(blockRow, blockCol, 2) = dx;
                end
            end
        end

        candidateCounts(blockRow, blockCol) = numel(rowOffsets) * numel(colOffsets);
    end
end
end
