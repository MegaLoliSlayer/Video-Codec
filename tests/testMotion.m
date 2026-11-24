function tests = testMotion
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
projectRoot = fileparts(fileparts(mfilename('fullpath')));
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(projectRoot, 'src')));
end

function testKnownTranslation(testCase)
reference = makeTexture(48, 48);
current = reference;
current(17:32, 17:32) = reference(14:29, 22:37);

[vectors, counts] = codec.estimateMotion(current, reference);
verifyEqual(testCase, reshape(vectors(2, 2, :), 1, 2), [-3, 5]);
verifyEqual(testCase, counts(2, 2), 17 ^ 2);
verifyEqual(testCase, counts(1, 1), 9 ^ 2);

prediction = codec.compensateMotion(reference, vectors);
verifyEqual(testCase, prediction, current);
end

function testFlatFramePrefersZeroMotion(testCase)
reference = uint8(ones(32, 32) * 128);
vectors = codec.estimateMotion(reference, reference);
verifyEqual(testCase, vectors, zeros(2, 2, 2));
end

function testPartialEdgeBlocks(testCase)
reference = makeTexture(19, 21);
current = reference;
current(17:19, 17:21) = reference(15:17, 14:18);

[vectors, counts] = codec.estimateMotion(current, reference, 16, 3);
verifySize(testCase, vectors, [2, 2, 2]);
verifyEqual(testCase, reshape(vectors(2, 2, :), 1, 2), [-2, -3]);
verifyEqual(testCase, counts(2, 2), 16);
verifyEqual(testCase, codec.compensateMotion(reference, vectors, 16), current);
end

function testZeroSearchRadiusAndCustomBlockSize(testCase)
reference = makeTexture(7, 11);
[vectors, counts] = codec.estimateMotion(reference, reference, 5, 0);
verifyEqual(testCase, vectors, zeros(2, 3, 2));
verifyEqual(testCase, counts, ones(2, 3));
verifyEqual(testCase, codec.compensateMotion(reference, vectors, 5), reference);
end

function testRejectsIncompatibleInputs(testCase)
reference = zeros(16, 16, 'uint8');
verifyError(testCase, @() codec.estimateMotion(reference, reference(:, 1:8)), ...
    'codec:FrameSizeMismatch');
verifyError(testCase, @() codec.compensateMotion(reference, zeros(2, 1, 2)), ...
    'codec:MotionGridSizeMismatch');
verifyError(testCase, @() codec.compensateMotion(reference, reshape([-1, 0], 1, 1, 2)), ...
    'codec:MotionVectorOutOfBounds');
end

function frame = makeTexture(height, width)
stream = RandStream('mt19937ar', 'Seed', 424);
frame = uint8(randi(stream, [0, 255], height, width));
end
