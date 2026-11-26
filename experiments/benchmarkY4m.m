function [summary, perFrame] = benchmarkY4m(files, outputDirectory, frameCount, estimators)
%BENCHMARKY4M Run the motion benchmark on Y4M clips and write two CSVs.

arguments
    files (:, 1) string
    outputDirectory (1, 1) string
    frameCount (1, 1) double {mustBeInteger, mustBeGreaterThanOrEqual(frameCount, 2)} = 31
    estimators (1, 1) struct = struct('FullSearch', @codec.motion.estimateMotion)
end

if isempty(files)
    error('codec:MissingBenchmarkClips', 'Supply at least one Y4M clip.');
end

summaries = cell(numel(files), 1);
measurements = cell(numel(files), 1);
for clip = 1:numel(files)
    [frames, fps] = readY4mLuma(files(clip), frameCount);
    [clipSummary, clipFrames] = benchmarkMotion(frames, estimators);
    [~, name] = fileparts(files(clip));

    methodCount = height(clipSummary);
    summaries{clip} = addvars(clipSummary, repmat(string(name), methodCount, 1), ...
        repmat(size(frames, 2), methodCount, 1), repmat(size(frames, 1), methodCount, 1), ...
        repmat(fps, methodCount, 1), 'Before', 1, 'NewVariableNames', {'Clip', 'Width', 'Height', 'FPS'});
    measurements{clip} = addvars(clipFrames, repmat(string(name), height(clipFrames), 1), ...
        'Before', 1, 'NewVariableNames', 'Clip');
end

summary = vertcat(summaries{:});
perFrame = vertcat(measurements{:});
if ~isfolder(outputDirectory)
    mkdir(outputDirectory);
end
writetable(summary, fullfile(outputDirectory, 'motion-summary.csv'));
writetable(perFrame, fullfile(outputDirectory, 'motion-per-frame.csv'));
end
