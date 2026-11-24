function [vectors, candidateCounts] = estimateMotion(varargin)
%ESTIMATEMOTION Forward the original API to codec.motion.estimateMotion.
%   See also codec.motion.estimateMotion.

[vectors, candidateCounts] = codec.motion.estimateMotion(varargin{:});
end
