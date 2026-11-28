function reconstructed = decodeVideo(inputFolder)
%Reconstruct a luminance clip from its header, coefficients, and motion vectors

data = load(fullfile(inputFolder, 'header.mat'), 'header');
header = data.header;

width = header.Width;
height = header.Height;
frameCount = header.FrameCount;
motionBlockSize = header.BlockSize;
transformSize = 8;
[quantSteps, ~] = codec.quantization.init_jpegWithBlockSize(transformSize, header.Quality);

paddedHeight = transformSize * ceil(height / transformSize);
paddedWidth = transformSize * ceil(width / transformSize);
blocksPerFrame = paddedHeight * paddedWidth / transformSize^2;

motionBlockRows = ceil(height / motionBlockSize);
motionBlockCols = ceil(width / motionBlockSize);
motionColumns = 2 * motionBlockRows * motionBlockCols;

%Older streams store raw motion vectors and one coefficient file per frame
usesBands = isfield(header, 'BandEdges');
motionFile = fullfile(inputFolder, 'motion.bin');

if ~usesBands
    motionId = fopen(motionFile, 'rb');
elseif frameCount > 1
    motionRows = codec.entropy.entropy_dec(motionFile);
end

reconstructed = zeros(height, width, frameCount, 'uint8');

for frameIndex = 1:frameCount
    %Build the P-frame prediction from the previous decoded frame
    prediction = zeros(height, width);
    if frameIndex > 1
        if usesBands
            values = motionRows(frameIndex - 1, :);
        else
            values = fread(motionId, motionColumns, '*int8');
        end

        vectors = reshape(values, motionBlockRows, motionBlockCols, 2);
        reference = reconstructed(:, :, frameIndex - 1);
        prediction = double(codec.motion.compensateMotion(reference, vectors, motionBlockSize));
    end

    if usesBands
        groupPosition = mod(frameIndex - 1, header.GroupSize) + 1;

        %Read each group once and put its bands back in zigzag order
        if groupPosition == 1
            groupIndex = ceil(frameIndex / header.GroupSize);
            bands = cell(1, numel(header.BandEdges) - 1);

            for bandIndex = 1:numel(bands)
                bandFile = fullfile(inputFolder, ...
                    sprintf('coeff_%06d_band%d.bin', groupIndex, bandIndex));
                bands{bandIndex} = codec.entropy.entropy_dec(bandFile);
            end

            groupCoefficients = horzcat(bands{:});
        end

        frameRows = (groupPosition - 1) * blocksPerFrame + (1:blocksPerFrame);
        quantizedRows = groupCoefficients(frameRows, :);
    else
        coeffFile = fullfile(inputFolder, sprintf('frame_%06d.bin', frameIndex));
        quantizedRows = codec.entropy.entropy_dec(coeffFile);
    end

    %Remove transform padding before adding the prediction
    residual = codec.transform.block_idct( ...
        quantizedRows .* quantSteps, paddedHeight, paddedWidth);
    reconstructed(:, :, frameIndex) = uint8(prediction + residual(1:height, 1:width));
end

if ~usesBands
    fclose(motionId);
end
end