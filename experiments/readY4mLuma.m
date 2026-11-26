function [frames, frameRate] = readY4mLuma(file, frameCount)
%READY4MLUMA Read the first FRAMECOUNT luma planes from 8-bit 4:2:0 Y4M.
%   FRAMERATE is NaN if the stream leaves the rate unspecified.

arguments
    file (1, 1) string
    frameCount (1, 1) double {mustBeInteger, mustBePositive}
end

[fileId, message] = fopen(file, 'rb');
if fileId < 0
    error('codec:Y4mOpenFailed', 'Could not open %s. %s', file, message);
end
closeFile = onCleanup(@() fclose(fileId)); %#ok<NASGU>

header = fgetl(fileId);
if ~ischar(header) || ~startsWith(header, 'YUV4MPEG2 ')
    error('codec:InvalidY4mHeader', 'Expected a YUV4MPEG2 header in %s.', file);
end

width = str2double(headerValue(header, 'W'));
height = str2double(headerValue(header, 'H'));
if ~all(isfinite([width, height])) || any([width, height] <= 0) || ...
        any(mod([width, height], 2) ~= 0)
    error('codec:InvalidY4mHeader', 'Expected positive even dimensions in %s.', file);
end
frameRate = readFrameRate(headerValue(header, 'F'), file);

chroma = headerValue(header, 'C');
if ~isempty(chroma) && ~ismember(chroma, {'420', '420jpeg', '420mpeg2', '420paldv'})
    error('codec:UnsupportedY4mChroma', 'Expected 8-bit 4:2:0 samples in %s.', file);
end

lumaBytes = width * height;
frameBytes = lumaBytes * 3 / 2;
frames = zeros(height, width, frameCount, 'uint8');
for frameIndex = 1:frameCount
    tag = fgetl(fileId);
    if ~ischar(tag) || ~(strcmp(tag, 'FRAME') || startsWith(tag, 'FRAME '))
        error('codec:MissingY4mFrame', 'Expected frame %d in %s.', frameIndex, file);
    end
    samples = fread(fileId, frameBytes, '*uint8');
    if numel(samples) ~= frameBytes
        error('codec:TruncatedY4mFrame', 'Frame %d is incomplete in %s.', frameIndex, file);
    end
    frames(:, :, frameIndex) = reshape(samples(1:lumaBytes), width, height)';
end
end

function frameRate = readFrameRate(rateText, file)
if isempty(rateText) || strcmp(rateText, '0:0')
    frameRate = NaN;
    return;
end

rate = str2double(regexp(rateText, '^(\d+):(\d+)$', 'tokens', 'once'));
if numel(rate) ~= 2 || any(~isfinite(rate)) || any(rate <= 0)
    error('codec:InvalidY4mHeader', 'Expected a positive frame rate in %s.', file);
end
frameRate = rate(1) / rate(2);
end

function value = headerValue(header, tag)
token = regexp(header, [' ' tag '(\S+)'], 'tokens', 'once');
value = '';
if ~isempty(token)
    value = token{1};
end
end
