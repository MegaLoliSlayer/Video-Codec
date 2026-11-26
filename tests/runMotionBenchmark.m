function [summary, perFrame] = runMotionBenchmark(clipFile, width, height, frameCount)
%RUNMOTIONBENCHMARK Compare full search and diamond search
%With no arguments, test a synthetic block shifted four pixels
%For a raw .y clip, pass its path relative to the repository root

arguments
    clipFile = ""
    width = 176
    height = 144
    frameCount = 100
end

repoRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
restorePath = onCleanup(@() path(originalPath)); 
addpath(fullfile(repoRoot, 'src'));

synthetic = strlength(clipFile) == 0;
if synthetic
    reference = repmat(uint8(1:48), 48, 1);
    current = reference;
    current(17:32, 17:32) = reference(17:32, 21:36);
    frames = cat(3, reference, current);
    clipName = "synthetic";
else
    fid = fopen(fullfile(repoRoot, clipFile), 'rb');
    samples = fread(fid, width * height * frameCount, '*uint8');
    fclose(fid);
    frames = permute(reshape(samples, width, height, frameCount), [2 1 3]);
    [~, clipName] = fileparts(string(clipFile));
end

blockSize = 16;
searchRadius = 8;
methods = {@codec.motion.estimateMotion, @codec.motion.estimateDiamond};
names = ["FullSearch"; "DiamondSearch"];

pairCount = size(frames, 3) - 1;
methodCount = numel(methods);
mse = zeros(pairCount, methodCount);
mae = zeros(pairCount, methodCount);
candidates = zeros(pairCount, methodCount);
searchMs = zeros(pairCount, methodCount);
motionMs = zeros(pairCount, methodCount);

for method = 1:methodCount
    estimate = methods{method};

    % Warm up the estimator and compensator before timing.
    vectors = estimate(frames(:, :, 2), frames(:, :, 1), blockSize, searchRadius);
    codec.motion.compensateMotion(frames(:, :, 1), vectors, blockSize);

    for pair = 1:pairCount
        reference = frames(:, :, pair);
        current = frames(:, :, pair + 1);

        motionTimer = tic;
        searchTimer = tic;
        [vectors, counts] = estimate(current, reference, blockSize, searchRadius);
        searchMs(pair, method) = 1000 * toc(searchTimer);

        prediction = codec.motion.compensateMotion(reference, vectors, blockSize);
        residual = double(current) - double(prediction);
        motionMs(pair, method) = 1000 * toc(motionTimer);

        mse(pair, method) = mean(residual .^ 2, 'all');
        mae(pair, method) = mean(abs(residual), 'all');
        candidates(pair, method) = sum(counts, 'all');
    end

    if synthetic
        offset = reshape(vectors(2, 2, :), 1, 2);
        fprintf('%s  vector [%d, %d]  expected [0, 4]\n', ...
            char(names(method)), offset(1), offset(2));
    end
end

pooledMSE = mean(mse, 1)';
summary = table(names, pooledMSE, mean(mae, 1)', ...
    10 * log10(255 ^ 2 ./ pooledMSE), ...
    mean(candidates, 1)', mean(searchMs, 1)', mean(motionMs, 1)', ...
    'VariableNames', {'Method', 'ResidualMSE', 'ResidualMAE', ...
    'PredictionPSNRdB', 'CandidatesPerPair', 'MeanSearchMs', 'MeanMotionMs'});

perFrame = table(repelem(names, pairCount), ...
    repmat((2:size(frames, 3))', methodCount, 1), ...
    mse(:), mae(:), 10 * log10(255 ^ 2 ./ mse(:)), ...
    candidates(:), searchMs(:), motionMs(:), ...
    'VariableNames', {'Method', 'Frame', 'ResidualMSE', 'ResidualMAE', ...
    'PredictionPSNRdB', 'Candidates', 'SearchMs', 'MotionMs'});

resultsFolder = fullfile(repoRoot, 'results');
prefix = "motion-" + clipName;
disp(summary);
writetable(summary, fullfile(resultsFolder, prefix + "-summary.csv"));
writetable(perFrame, fullfile(resultsFolder, prefix + "-per-frame.csv"));
end