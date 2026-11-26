function [summary, perFrame] = benchmarkLab5Codec(frames, qualities)
%BENCHMARKLAB5CODEC Measure an I/P baseline with the external Lab 5 coder.
%   Add the Lab 5 MATLAB folder to the path before calling this experiment.
%   The temporary encoded files are decoded again to measure output quality.

arguments
    frames
    qualities (1, :) double {mustBeInteger, mustBeInRange(qualities, 1, 100)} = [10 30 50 70 90]
end

if ~isa(frames, 'uint8') || isempty(frames) || ndims(frames) > 3
    error('codec:InvalidBenchmarkFrames', 'Supply 8-bit grayscale frames in an H-by-W-by-N array.');
end
if isempty(qualities)
    error('codec:MissingQualityFactors', 'Supply at least one quality factor.');
end
originalFolder = pwd;
scratch = tempname;
[created, message] = mkdir(scratch);
if ~created
    error('codec:BenchmarkWorkspaceFailed', 'Could not create the benchmark workspace. %s', message);
end
cleanup = onCleanup(@() cleanScratch(originalFolder, scratch)); %#ok<NASGU>
cd(scratch);
if isempty(which('image_dct_enc')) || isempty(which('image_dct_dec'))
    error('codec:MissingLab5Codec', 'Add the Lab 5 MATLAB folder to the path.');
end
sourceBmp = fullfile(scratch, 'input.bmp');
decodedBmp = fullfile(scratch, 'decoded.bmp');

[height, width, frameCount] = size(frames);
sequence = struct('Height', height, 'Width', width, 'FrameCount', frameCount, 'BlockSize', 16);
perQuality = cell(numel(qualities), 1);
sequenceBytes = zeros(numel(qualities), 1);
for run = 1:numel(qualities)
    sequenceFolder = fullfile(scratch, sprintf('run-%d', run));
    mkdir(sequenceFolder);
    sequenceFile = fullfile(sequenceFolder, 'sequence.mat');
    save(sequenceFile, 'sequence');
    metadata = dir(sequenceFile);
    sequenceBytes(run) = metadata.bytes;

    [encoderReconstructions, measurements] = encodeSequence( ...
        frames, sequence, sequenceFolder, qualities(run), sourceBmp, decodedBmp);
    decoded = decodeSequence(sequenceFile, decodedBmp);
    if ~isequal(encoderReconstructions, decoded)
        error('codec:ReferenceMismatch', 'Encoder and decoder references differ at quality %d.', qualities(run));
    end

    distortion = (double(frames) - double(decoded)) .^ 2;
    measurements.ReconstructionMSE = reshape(mean(distortion, [1 2]), [], 1);
    measurements.ReconstructionPSNRdB = 10 * log10(255 ^ 2 ./ measurements.ReconstructionMSE);
    perQuality{run} = addvars(measurements, repmat(qualities(run), frameCount, 1), ...
        'Before', 1, 'NewVariableNames', 'Quality');
end

perFrame = vertcat(perQuality{:});
summary = table(qualities(:), 'VariableNames', {'Quality'});
summary.SequenceMetadataBytes = sequenceBytes;
summary.CodedBytes = sequenceBytes + sum(reshape(perFrame.CodedBytes, frameCount, []), 1)';
summary.MotionBytes = sum(reshape(perFrame.MotionBytes, frameCount, []), 1)';
summary.BitsPerPixel = 8 * summary.CodedBytes / numel(frames);
summary.ReconstructionMSE = mean(reshape(perFrame.ReconstructionMSE, frameCount, []), 1)';
summary.ReconstructionPSNRdB = 10 * log10(255 ^ 2 ./ summary.ReconstructionMSE);
summary.MeanFramePSNRdB = mean(reshape(perFrame.ReconstructionPSNRdB, frameCount, []), 1)';
summary.EncodeSeconds = sum(reshape(perFrame.EncodeSeconds, frameCount, []), 1)';
summary.MotionSearchSeconds = sum(reshape(perFrame.MotionSearchSeconds, frameCount, []), 1)';
end

function [reconstructed, measurements] = encodeSequence(frames, sequence, folder, quality, sourceBmp, decodedBmp)
frameCount = sequence.FrameCount;
reconstructed = zeros(size(frames), 'uint8');
measurements = table((1:frameCount)', ["I"; repmat("P", frameCount - 1, 1)], ...
    'VariableNames', {'Frame', 'FrameType'});
measurements.CodedBytes = zeros(frameCount, 1);
measurements.MotionBytes = zeros(frameCount, 1);
measurements.EncodeSeconds = zeros(frameCount, 1);
measurements.MotionSearchSeconds = zeros(frameCount, 1);

for index = 1:frameCount
    directory = frameFolder(folder, index);
    mkdir(directory);
    cd(directory);
    timer = tic;
    current = frames(:, :, index);
    prediction = [];
    if index == 1
        codedImage = current;
    else
        [prediction, residual, motion] = codec.motion.predictFrame( ...
            current, reconstructed(:, :, index - 1), sequence.BlockSize);
        vectors = int8(motion.Vectors);
        save('motion.mat', 'vectors');
        codedImage = uint8(min(max(round(residual / 2) + 128, 0), 255));
        measurements.MotionSearchSeconds(index) = motion.SearchMs / 1000;
    end

    imwrite(padForLab5(codedImage), sourceBmp, 'bmp');
    image_dct_enc(sourceBmp, 'frame.bin', quality);
    decodedImage = image_dct_dec('frame.bin', decodedBmp);
    reconstructed(:, :, index) = reconstructFrame(decodedImage, prediction, sequence);
    measurements.EncodeSeconds(index) = toc(timer);

    files = dir;
    measurements.CodedBytes(index) = sum([files(~[files.isdir]).bytes]);
    if index > 1
        motionFile = dir('motion.mat');
        measurements.MotionBytes(index) = motionFile.bytes;
    end
end
end

function reconstructed = decodeSequence(sequenceFile, decodedBmp)
metadata = load(sequenceFile, 'sequence');
sequence = metadata.sequence;
folder = fileparts(sequenceFile);
reconstructed = zeros(sequence.Height, sequence.Width, sequence.FrameCount, 'uint8');
for index = 1:sequence.FrameCount
    cd(frameFolder(folder, index));
    prediction = [];
    if index > 1
        motion = load('motion.mat', 'vectors');
        prediction = codec.motion.compensateMotion( ...
            reconstructed(:, :, index - 1), motion.vectors, sequence.BlockSize);
    end
    decodedImage = image_dct_dec('frame.bin', decodedBmp);
    reconstructed(:, :, index) = reconstructFrame(decodedImage, prediction, sequence);
end
end

function frame = reconstructFrame(decodedImage, prediction, sequence)
decodedImage = decodedImage(1:sequence.Height, 1:sequence.Width);
frame = decodedImage;
if ~isempty(prediction)
    decodedResidual = 2 * (double(decodedImage) - 128);
    frame = uint8(min(max(double(prediction) + decodedResidual, 0), 255));
end
end

function image = padForLab5(image)
[height, width] = size(image);
rows = min(1:(8 * ceil(height / 8)), height);
cols = min(1:(8 * ceil(width / 8)), width);
image = image(rows, cols);
end

function directory = frameFolder(sequenceFolder, index)
directory = fullfile(sequenceFolder, sprintf('frame-%06d', index));
end

function cleanScratch(originalFolder, scratch)
cd(originalFolder);
rmdir(scratch, 's');
end
