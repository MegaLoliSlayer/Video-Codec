# Motion estimation

- `estimateMotion.m` checks every valid offset and picks the block with the lowest sum of absolute differences (SAD)
- `estimateDiamond.m` uses large and small diamond patterns to search fewer positions
- `compensateMotion.m` copies blocks from the reference frame using the `[dy, dx]` vectors

## Test in MATLAB

From the repo root, run:

```matlab
addpath('tests');

runMotionBenchmark();
runMotionBenchmark(fullfile('data', 'foreman_qcif.y'), 176, 144, 100);
```

The first run uses a synthetic shift. Both methods should find `[0, 4]` with zero prediction error. The second uses the first 100 Foreman frames and compares prediction PSNR, candidate counts, and runtime. Both runs save summary and per-frame CSVs in `results/`.