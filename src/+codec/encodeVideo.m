function [stats, reconstructed] = encodeVideo(inputFile, width, height, ...
    frameCount, outputFolder, quality, estimateMotion, groupSize)
%Encode an 8-bit luminance clip as one I-frame followed by P-frames

if nargin < 8
    groupSize = 20;
end

motionBlockSize = 16;
searchRadius = 8;
transformSize = 8;
coeffCount = transformSize^2;
bandEdges = [1 2 7 22 65];
[quantSteps, ~] = codec.quantization.init_jpegWithBlockSize(transformSize, quality);

%Repeat edge pixels to fill partial transform blocks
paddedHeight = transformSize * ceil(height / transformSize);
paddedWidth = transformSize * ceil(width / transformSize);
padRows = min(1:paddedHeight, height);
padCols = min(1:paddedWidth, width);
blocksPerFrame = paddedHeight * paddedWidth / coeffCount;

motionBlockRows = ceil(height / motionBlockSize);
motionBlockCols = ceil(width / motionBlockSize);
motionColumns = 2 * motionBlockRows * motionBlockCols;

encodeTimer = tic;
mkdir(outputFolder);

header = struct('Width', width, 'Height', height, ...
    'FrameCount', frameCount, 'Quality', quality, 'BlockSize', motionBlockSize, ...
    'GroupSize', groupSize, 'BandEdges', bandEdges);
save(fullfile(outputFolder, 'header.mat'), 'header');

inputId = fopen(inputFile, 'rb');
reconstructed = zeros(height, width, frameCount, 'uint8');
motionRows = zeros(frameCount - 1, motionColumns, 'int8');
groupCoefficients = zeros(groupSize * blocksPerFrame, coeffCount);
coefficientBits = 0;
candidateCount = 0;

for frameIndex = 1:frameCount
    samples = fread(inputId, width * height, '*uint8');
    current = reshape(samples, width, height).';

    %Use zero prediction for the I-frame and the previous reconstruction for P-frames
    prediction = zeros(height, width);
    if frameIndex > 1
        reference = reconstructed(:, :, frameIndex - 1);
        [vectors, counts] = estimateMotion(current, reference, motionBlockSize, searchRadius);
        motionRows(frameIndex - 1, :) = reshape(int8(vectors), 1, []);
        candidateCount = candidateCount + sum(counts, 'all');
        prediction = double(codec.motion.compensateMotion(reference, vectors, motionBlockSize));
    end

    residual = double(current) - prediction;
    coeffRows = codec.transform.block_dct(residual(padRows, padCols));
    quantizedRows = round(coeffRows ./ quantSteps);

    %Buffer coefficient rows so each band shares a model across the group
    groupPosition = mod(frameIndex - 1, groupSize) + 1;
    frameRows = (groupPosition - 1) * blocksPerFrame + (1:blocksPerFrame);
    groupCoefficients(frameRows, :) = quantizedRows;

    %Write complete groups and the final partial group
    if groupPosition == groupSize || frameIndex == frameCount
        groupIndex = ceil(frameIndex / groupSize);
        usedRows = 1:(groupPosition * blocksPerFrame);

        for bandIndex = 1:(numel(bandEdges) - 1)
            columns = bandEdges(bandIndex):(bandEdges(bandIndex + 1) - 1);
            bandFile = fullfile(outputFolder, ...
                sprintf('coeff_%06d_band%d.bin', groupIndex, bandIndex));
            coefficientBits = coefficientBits + codec.entropy.entropy_enc( ...
                groupCoefficients(usedRows, columns), bandFile);
        end
    end

    %Reconstruct the same frame the decoder will use as its next reference
    decodedResidual = codec.transform.block_idct( ...
        quantizedRows .* quantSteps, paddedHeight, paddedWidth);
    reconstructed(:, :, frameIndex) = ...
        uint8(prediction + decodedResidual(1:height, 1:width));
end

fclose(inputId);

motionBits = 0;
if frameCount > 1
    motionFile = fullfile(outputFolder, 'motion.bin');
    motionBits = codec.entropy.entropy_enc(motionRows, motionFile);
end

%Count every file needed by the decoder
headerFile = dir(fullfile(outputFolder, 'header.mat'));
stats.Bits = coefficientBits + motionBits + 8 * headerFile.bytes;
stats.EncodeSeconds = toc(encodeTimer);
stats.Candidates = candidateCount;
end