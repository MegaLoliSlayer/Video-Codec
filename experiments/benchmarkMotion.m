function [summary, perFrame] = benchmarkMotion(frames, estimators, blockSize, searchRadius)
%BENCHMARKMOTION Compare named motion estimators on consecutive luma frames.
%   FRAMES is an H-by-W-by-N uint8 array. Each method uses the preceding
%   original frame as its reference. The codec instead uses reconstructed
%   references when encoding an inter-frame bitstream.

arguments
    frames
    estimators (1, 1) struct = struct('FullSearch', @codec.motion.estimateMotion)
    blockSize (1, 1) double {mustBeInteger, mustBePositive} = 16
    searchRadius (1, 1) double {mustBeInteger, mustBeNonnegative} = 8
end

if ~isa(frames, 'uint8') || isempty(frames) || ndims(frames) ~= 3 || size(frames, 3) < 2
    error('codec:InvalidBenchmarkFrames', 'Supply at least two uint8 grayscale frames in an H-by-W-by-N array.');
end

names = fieldnames(estimators);
if isempty(names) || isfield(estimators, 'ZeroMotion') || ...
        ~all(structfun(@(f) isa(f, 'function_handle'), estimators))
    error('codec:InvalidEstimators', 'Supply named estimator handles and reserve ZeroMotion for the baseline.');
end
names = ["ZeroMotion"; string(names)];
estimators.ZeroMotion = @zeroMotion;

pairCount = size(frames, 3) - 1;
frameIndices = (2:size(frames, 3))';
rowCount = numel(names) * pairCount;
perFrame = table(repelem(names, pairCount), repmat(frameIndices, numel(names), 1), ...
    'VariableNames', {'Method', 'Frame'});
perFrame.ResidualMSE = zeros(rowCount, 1);
perFrame.ResidualMAE = zeros(rowCount, 1);
perFrame.Candidates = zeros(rowCount, 1);
perFrame.SearchMs = zeros(rowCount, 1);
perFrame.MotionStageMs = zeros(rowCount, 1);

for methodIndex = 1:numel(names)
    estimator = estimators.(names(methodIndex));
    codec.motion.predictFrame(frames(:, :, 2), frames(:, :, 1), blockSize, searchRadius, estimator);

    for pair = 1:pairCount
        row = (methodIndex - 1) * pairCount + pair;
        [~, residual, motion] = codec.motion.predictFrame( ...
            frames(:, :, pair + 1), frames(:, :, pair), blockSize, searchRadius, estimator);
        perFrame.ResidualMSE(row) = mean(residual .^ 2, 'all');
        perFrame.ResidualMAE(row) = mean(abs(residual), 'all');
        perFrame.Candidates(row) = sum(motion.CandidateCounts, 'all');
        perFrame.SearchMs(row) = motion.SearchMs;
        perFrame.MotionStageMs(row) = motion.MotionStageMs;
    end
end

perFrame.PredictionPSNRdB = 10 * log10(255 ^ 2 ./ perFrame.ResidualMSE);
summary = table(names, repmat(pairCount, numel(names), 1), 'VariableNames', {'Method', 'FramePairs'});
summary.ResidualMSE = mean(reshape(perFrame.ResidualMSE, pairCount, []), 1)';
summary.ResidualMAE = mean(reshape(perFrame.ResidualMAE, pairCount, []), 1)';
summary.PredictionPSNRdB = 10 * log10(255 ^ 2 ./ summary.ResidualMSE);
summary.TotalCandidates = sum(reshape(perFrame.Candidates, pairCount, []), 1)';
summary.MeanCandidates = summary.TotalCandidates / pairCount;
summary.MeanSearchMs = mean(reshape(perFrame.SearchMs, pairCount, []), 1)';
summary.MeanMotionStageMs = mean(reshape(perFrame.MotionStageMs, pairCount, []), 1)';
end

function [vectors, candidateCounts] = zeroMotion(~, reference, blockSize, ~)
blockRows = ceil(size(reference, 1) / blockSize);
blockCols = ceil(size(reference, 2) / blockSize);
vectors = zeros(blockRows, blockCols, 2);
candidateCounts = zeros(blockRows, blockCols);
end
