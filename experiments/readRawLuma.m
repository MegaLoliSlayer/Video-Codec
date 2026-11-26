function frames = readRawLuma(file, width, height, frameCount)
%READRAWLUMA Read consecutive row-major 8-bit frames from a raw .y file.

arguments
    file (1, 1) string
    width (1, 1) double {mustBeInteger, mustBePositive}
    height (1, 1) double {mustBeInteger, mustBePositive}
    frameCount (1, 1) double {mustBeInteger, mustBePositive}
end

[fileId, message] = fopen(file, 'rb');
if fileId < 0
    error('codec:RawLumaOpenFailed', 'Could not open %s. %s', file, message);
end
closeFile = onCleanup(@() fclose(fileId)); %#ok<NASGU>

expectedBytes = width * height * frameCount;
samples = fread(fileId, expectedBytes, '*uint8');
if numel(samples) ~= expectedBytes
    error('codec:TruncatedRawLuma', 'Could not read %d frames at %d by %d from %s.', ...
        frameCount, width, height, file);
end
frames = permute(reshape(samples, width, height, frameCount), [2 1 3]);
end
