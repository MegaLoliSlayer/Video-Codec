function demoMotion
%DEMOMOTION Compare zero-motion and full-search predictions on two frames.

stream = RandStream('mt19937ar', 'Seed', 424);
reference = uint8(randi(stream, [0, 255], 64, 64));
current = reference;
rows = 17:48;
cols = 17:48;
current(rows, cols) = reference(rows - 3, cols + 5);

[~, residual, motion] = codec.motion.predictFrame(current, reference);
zeroMotionResidual = double(current) - double(reference);
recoveredOffset = reshape(motion.Vectors(2, 2, :), 1, 2);

fprintf('Motion vector for block (2, 2): [dy, dx] = [%d, %d]\n', recoveredOffset);
fprintf('Full-search candidate comparisons: %d\n', sum(motion.CandidateCounts, 'all'));
fprintf('Zero-motion prediction MSE: %.2f\n', mean(zeroMotionResidual .^ 2, 'all'));
fprintf('Full-search prediction MSE: %.2f\n', mean(residual .^ 2, 'all'));
end
