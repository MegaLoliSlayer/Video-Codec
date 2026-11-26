function summary = runPFrameRoundTrip(clipFile, width, height)
%RUNPFRAMEROUNDTRIP Reconstruct the second frame from its vectors and residual

arguments
    clipFile = fullfile('data', 'foreman_qcif.y')
    width = 176
    height = 144
end

repoRoot = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
restorePath = onCleanup(@() path(originalPath)); 
addpath(fullfile(repoRoot, 'src'));

fid = fopen(fullfile(repoRoot, clipFile), 'rb');
samples = fread(fid, width * height * 2, '*uint8');
fclose(fid);
frames = permute(reshape(samples, width, height, 2), [2 1 3]);

%Use the first frame as the shared reference for this test
reference = frames(:, :, 1);
current = frames(:, :, 2);

blockSize = 16;
searchRadius = 8;
methods = {@codec.motion.estimateMotion, @codec.motion.estimateDiamond};
names = ["FullSearch"; "DiamondSearch"];

candidates = zeros(2, 1);
residualMin = zeros(2, 1);
residualMax = zeros(2, 1);
maxPixelError = zeros(2, 1);

for method = 1:numel(methods)
    [packet, candidates(method)] = encodeMotion(current, reference, ...
        methods{method}, blockSize, searchRadius);

    reconstructed = decodeMotion(reference, packet, blockSize);

    residualMin(method) = min(packet.Residual, [], 'all');
    residualMax(method) = max(packet.Residual, [], 'all');
    maxPixelError(method) = max(abs(double(current) - double(reconstructed)), [], 'all');
end

summary = table(names, candidates, residualMin, residualMax, ...
    maxPixelError, maxPixelError == 0, ...
    'VariableNames', {'Method', 'Candidates', 'ResidualMin', ...
    'ResidualMax', 'MaxPixelError', 'ExactMatch'});

disp(summary);
writetable(summary, fullfile(repoRoot, 'results', 'pframe-roundtrip.csv'));
end

function [packet, candidates] = encodeMotion(current, reference, estimate, blockSize, searchRadius)
[vectors, counts] = estimate(current, reference, blockSize, searchRadius);
prediction = codec.motion.compensateMotion(reference, vectors, blockSize);

%Keep the sign of the residual when storing it
packet.Vectors = int8(vectors);
packet.Residual = int16(double(current) - double(prediction));
candidates = sum(counts, 'all');
end

function reconstructed = decodeMotion(reference, packet, blockSize)
%Build the prediction using only the reference and transmitted vectors
prediction = codec.motion.compensateMotion(reference, packet.Vectors, blockSize);
reconstructed = uint8(double(prediction) + double(packet.Residual));
end