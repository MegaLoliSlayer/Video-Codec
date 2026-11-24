function prediction = compensateMotion(varargin)
%COMPENSATEMOTION Forward the original API to codec.motion.compensateMotion.
%   See also codec.motion.compensateMotion.

prediction = codec.motion.compensateMotion(varargin{:});
end
