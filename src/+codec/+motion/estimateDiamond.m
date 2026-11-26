function [vectors, candidateCounts] = estimateDiamond(current, reference, blockSize, searchRadius)
%ESTIMATEDIAMOND Find [dy, dx] motion vectors using diamond-search SAD.
%   Uses the large and small patterns from Zhu and Ma, doi:10.1109/83.821744.

arguments
    current
    reference
    blockSize = 16
    searchRadius = 8
end

largeDiamond = [0 0; -2 0; -1 -1; -1 1; 0 -2; 0 2; 1 -1; 1 1; 2 0];
smallDiamond = [0 0; -1 0; 0 -1; 0 1; 1 0];

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
    rowLimits = [max(-searchRadius, 1 - rows(1)), min(searchRadius, height - rows(end))];

    for blockCol = 1:numel(colStarts)
        firstCol = colStarts(blockCol);
        cols = firstCol:min(firstCol + blockSize - 1, width);
        colLimits = [max(-searchRadius, 1 - cols(1)), min(searchRadius, width - cols(end))];
        target = current(rows, cols);

        costs = nan(diff(rowLimits) + 1, diff(colLimits) + 1);
        center = [0 0];

        while true
            [best, costs] = scorePattern(center, largeDiamond, target, ...
                reference, rows, cols, rowLimits, colLimits, costs);
            if isequal(best, center)
                break;
            end
            center = best;
        end

        [best, costs] = scorePattern(center, smallDiamond, target, ...
            reference, rows, cols, rowLimits, colLimits, costs);

        vectors(blockRow, blockCol, 1) = best(1);
        vectors(blockRow, blockCol, 2) = best(2);
        candidateCounts(blockRow, blockCol) = nnz(~isnan(costs));
    end
end
end

function [best, costs] = scorePattern(center, offsets, target, ...
    reference, rows, cols, rowLimits, colLimits, costs)

best = center;
bestCost = Inf;
bestDistance = Inf;

for point = 1:size(offsets, 1)
    dy = center(1) + offsets(point, 1);
    dx = center(2) + offsets(point, 2);

    if dy < rowLimits(1) || dy > rowLimits(2) || dx < colLimits(1) || dx > colLimits(2)
        continue;
    end

    rowIndex = dy - rowLimits(1) + 1;
    colIndex = dx - colLimits(1) + 1;
    cost = costs(rowIndex, colIndex);

    if isnan(cost)
        candidate = reference(rows + dy, cols + dx);
        cost = sum(abs(target - candidate), 'all');
        costs(rowIndex, colIndex) = cost;
    end

    distance = dy ^ 2 + dx ^ 2;
    if cost < bestCost || (cost == bestCost && distance < bestDistance)
        best = [dy dx];
        bestCost = cost;
        bestDistance = distance;
    end
end
end