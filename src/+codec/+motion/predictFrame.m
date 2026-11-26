function [prediction, residual, motion] = predictFrame(current, reference, blockSize, searchRadius, estimator)
%PREDICTFRAME Form an inter-frame prediction and its signed residual.
%   Use the previous reconstructed frame as REFERENCE in the codec.
%   ESTIMATOR can be any function with the estimateMotion input and output
%   signature and the same search bounds. MOTION carries the vectors,
%   search counts, and elapsed times.

arguments
    current
    reference
    blockSize (1, 1) double {mustBeInteger, mustBePositive} = 16
    searchRadius (1, 1) double {mustBeInteger, mustBeNonnegative} = 8
    estimator (1, 1) function_handle = @codec.motion.estimateMotion
end

validateattributes(current, {'uint8', 'uint16', 'single', 'double'}, ...
    {'2d', 'nonempty', 'real', 'finite'}, mfilename, 'current');
if ~isequal(size(current), size(reference))
    error('codec:FrameSizeMismatch', 'Current and reference frames must have the same size.');
end

searchTimer = tic;
[vectors, candidateCounts] = estimator(current, reference, blockSize, searchRadius);
searchMs = toc(searchTimer) * 1000;

if any(abs(double(vectors)) > searchRadius, 'all')
    error('codec:MotionVectorOutsideSearchWindow', 'The estimator returned a vector outside the search radius.');
end

predictionTimer = tic;
prediction = codec.motion.compensateMotion(reference, vectors, blockSize);
residual = double(current) - double(prediction);
predictionMs = toc(predictionTimer) * 1000;

validateattributes(candidateCounts, {'numeric'}, {'2d', 'real', 'finite', 'integer', 'nonnegative'}, ...
    mfilename, 'candidateCounts');
if ~isequal(size(candidateCounts), [size(vectors, 1), size(vectors, 2)])
    error('codec:CandidateGridSizeMismatch', 'The estimator must return one candidate count per motion vector.');
end

motion = struct('Vectors', vectors, 'CandidateCounts', candidateCounts, ...
    'SearchMs', searchMs, 'MotionStageMs', searchMs + predictionMs);
end
