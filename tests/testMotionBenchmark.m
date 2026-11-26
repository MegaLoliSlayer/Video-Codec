function tests = testMotionBenchmark
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
projectRoot = fileparts(fileparts(mfilename('fullpath')));
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(projectRoot, 'src')));
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(projectRoot, 'experiments')));
end

function testReportsPooledPredictionMetrics(testCase)
reference = uint8([0 10; 20 30]);
current = uint8([4 6; 30 26]);
frames = cat(3, reference, current, current);
methods = struct('RadiusZero', @codec.motion.estimateMotion);

[summary, perFrame] = benchmarkMotion(frames, methods, 2, 0);

verifyEqual(testCase, summary.Method, ["ZeroMotion"; "RadiusZero"]);
verifyEqual(testCase, summary.FramePairs, [2; 2]);
verifyEqual(testCase, summary.ResidualMSE, [18.5; 18.5]);
verifyEqual(testCase, summary.ResidualMAE, [2.75; 2.75]);
verifyEqual(testCase, summary.PredictionPSNRdB, repmat(10 * log10(255 ^ 2 / 18.5), 2, 1), 'AbsTol', 1e-12);
verifyEqual(testCase, summary.TotalCandidates, [0; 2]);
verifyEqual(testCase, perFrame.Frame, [2; 3; 2; 3]);
verifyEqual(testCase, perFrame.Candidates, [0; 0; 1; 1]);
verifyEqual(testCase, perFrame.PredictionPSNRdB([2, 4]), [Inf; Inf]);
verifyGreaterThanOrEqual(testCase, perFrame.MotionStageMs, perFrame.SearchMs);
end

function testReadY4mLumaSkipsChroma(testCase)
folder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
file = fullfile(folder.Folder, 'test.y4m');
fileId = fopen(file, 'wb');
fwrite(fileId, sprintf('YUV4MPEG2 W4 H2 F30000:1001 Ip\n'), 'char');
fwrite(fileId, sprintf('FRAME\n'), 'char');
fwrite(fileId, [1:8 200:203], 'uint8');
fwrite(fileId, sprintf('FRAME\n'), 'char');
fwrite(fileId, [11:18 210:213], 'uint8');
fclose(fileId);

[frames, frameRate] = readY4mLuma(file, 2);

verifyEqual(testCase, frames(:, :, 1), uint8([1 2 3 4; 5 6 7 8]));
verifyEqual(testCase, frames(:, :, 2), uint8([11 12 13 14; 15 16 17 18]));
verifyEqual(testCase, frameRate, 30000 / 1001);
end

function testReadY4mWithUnknownFrameRate(testCase)
folder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
file = fullfile(folder.Folder, 'unknown-fps.y4m');
fileId = fopen(file, 'wb');
fwrite(fileId, sprintf('YUV4MPEG2 W2 H2 F0:0\nFRAME\n'), 'char');
fwrite(fileId, [1:4 200 201], 'uint8');
fclose(fileId);

[frames, frameRate] = readY4mLuma(file, 1);

verifyEqual(testCase, frames, uint8([1 2; 3 4]));
verifyTrue(testCase, isnan(frameRate));
end
