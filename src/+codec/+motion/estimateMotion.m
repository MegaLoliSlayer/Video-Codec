function [vectors, candidateCounts] = estimateMotion(current, reference, blockSize, searchRadius)
%ESTIMATEMOTION Find [dy, dx] motion vectors using full-search SAD.

arguments
    current
    reference
    blockSize = 16
    searchRadius = 8
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
    firstRow = rowStarts(blockRow);
    rows = firstRow:min(firstRow + blockSize - 1, height);
    rowOffsets = max(-searchRadius, 1 - rows(1)):min(searchRadius, height - rows(end));

    for blockCol = 1:numel(colStarts)
        firstCol = colStarts(blockCol);
        cols = firstCol:min(firstCol + blockSize - 1, width);
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