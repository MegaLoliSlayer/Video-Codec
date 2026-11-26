# Video Codec

We're Group 5 in ENSC 424. We're building a grayscale video codec in MATLAB to see how motion prediction affects bitrate, picture quality, and encoding time. So far, we have full-search motion estimation and motion compensation.

## Run the demo

From the repository root in MATLAB, add the source and examples folders to your path and run the demo.

```matlab
addpath('src', 'examples');
demoMotion
```

The demo runs in base MATLAB R2022b. It makes two synthetic frames with a known shift and prints the recovered motion vector, how many candidates it checked, and the mean squared prediction error.

Run the tests from the repository root.

```matlab
results = runtests('tests');
assert(~isempty(results));
assertSuccess(results);
```

## Where things live

- [`src/+codec/`](src/+codec/) holds the codec components and is where the top-level encoder and decoder will go.
  - [`+motion/`](src/+codec/+motion/) holds motion estimation and compensation.
  - [`+transform/`](src/+codec/+transform/) is for the forward and inverse 8 × 8 DCT.
  - [`+quantization/`](src/+codec/+quantization/) is for quantizers and dequantizers, starting with uniform scalar quantization.
  - [`+entropy/`](src/+codec/+entropy/) is for the arithmetic encoder and decoder.
- [`examples/`](examples/) holds examples you can run with synthetic inputs.
- [`experiments/`](experiments/) holds the motion and Lab 5 I/P benchmarks, with results on test clips and the course Foreman file.
- [`tests/`](tests/) holds the MATLAB unit tests.

Keep `src` on the MATLAB path when working on any component. A function named `forwardDct` in `+transform` would be called as `codec.transform.forwardDct(...)`.

## Motion prediction

With `src` on the MATLAB path, use the previous reconstructed frame as `reference`. The two grayscale frames must have the same dimensions. The code accepts `uint8`, `uint16`, `single`, and `double` frames.

```matlab
blockSize = 16;
searchRadius = 8;
[prediction, residual, motion] = codec.motion.predictFrame(current, reference, blockSize, searchRadius);
```

The default full search checks positions up to eight pixels away along each axis. It uses 16 × 16 blocks and keeps partial edge blocks at their original size. Each candidate must fit inside the reference frame. The match with the lowest sum of absolute differences wins, and ties favor shorter vectors. `motion.CandidateCounts` records the number of positions checked for each block.

Each entry in `motion.Vectors` is `[dy, dx]` in pixels, from the current block to its match in the reference frame. The decoder can use the transmitted vectors with `codec.motion.compensateMotion`, then add the decoded residual in floating point and clip the result to the sample range.

The [motion benchmark](experiments/README.md) measures prediction PSNR, residual error, candidate counts, and runtime. You can pass in another estimator with the same inputs and outputs as `codec.motion.estimateMotion` to compare it on the same frame pairs.

## What's next

First we'll combine the 8 × 8 DCT, uniform scalar quantizer, and arithmetic coder for intra frames. For inter frames, we'll use that same pipeline to code the residual and transmit the motion vectors alongside it.

Once diamond search uses the same vector convention, we'll compare it with full search on bitrate, PSNR, encoding time, and the number of candidates checked. We'll calculate BD-Rate where the PSNR ranges overlap.
