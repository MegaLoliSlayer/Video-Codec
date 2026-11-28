function results = runVideoBenchmark(clipFile, width, height, frameCount, qualities)

arguments
    clipFile = fullfile('data', 'foreman_qcif.y')
    width = 176
    height = 144
    frameCount = 3
    qualities = 30
end

repoRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(repoRoot, 'src'));
inputFile = fullfile(repoRoot, clipFile);

fid = fopen(inputFile, 'rb');
samples = fread(fid, width * height * frameCount, '*uint8');
fclose(fid);
original = permute(reshape(samples, width, height, frameCount), [2 1 3]);

scratch = tempname;
mkdir(scratch);
cleanup = onCleanup(@() rmdir(scratch, 's')); 

methods = {@codec.motion.estimateMotion, @codec.motion.estimateDiamond};
names = ["FullSearch"; "DiamondSearch"];
n = numel(methods) * numel(qualities);

methodColumn = repelem(names, numel(qualities));
qualityColumn = repmat(qualities(:), numel(methods), 1);
bits = zeros(n, 1);
psnrDb = zeros(n, 1);
encodeSeconds = zeros(n, 1);
candidates = zeros(n, 1);
framesMatch = false(n, 1);

row = 0;
for method = 1:numel(methods)
    for quality = qualities(:).'
        row = row + 1;
        folder = fullfile(scratch, sprintf('run_%d', row));

        [stats, encoderFrames] = codec.encodeVideo(inputFile, width, height, ...
            frameCount, folder, quality, methods{method});
        decodedFrames = codec.decodeVideo(folder);

        err = double(original) - double(decodedFrames);
        bits(row) = stats.Bits;
        psnrDb(row) = 10 * log10(255^2 / mean(err.^2, 'all'));
        encodeSeconds(row) = stats.EncodeSeconds;
        candidates(row) = stats.Candidates;
        framesMatch(row) = isequal(encoderFrames, decodedFrames);
    end
end

results = table(methodColumn, qualityColumn, bits, bits / numel(original), ...
    psnrDb, encodeSeconds, candidates, framesMatch, ...
    'VariableNames', {'Method', 'Quality', 'TotalBits', 'BitsPerPixel', ...
    'DecodedPSNRdB', 'EncodeSeconds', 'MotionCandidates', 'EncoderDecoderMatch'});

disp(results);
[~, name] = fileparts(clipFile);
name = regexprep(char(name), sprintf('^(.+)_%d$', frameCount), '$1');
csvName = sprintf('%s-%d-frames.csv', name, frameCount);
writetable(results, fullfile(repoRoot, 'results', csvName));