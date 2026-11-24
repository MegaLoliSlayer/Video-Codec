# ENSC 424 MATLAB Video Codec

Group 5 is building a grayscale video codec in MATLAB to measure how motion prediction affects bitrate, picture quality, and encoding time. The starter implements full-search motion estimation and compensation using MATLAB R2022b and base MATLAB functions.

## Run the starter

Open the repository root as the current folder in MATLAB.

```matlab
demoMotion
results = runtests('tests');
assert(~isempty(results));
assertSuccess(results);
```

The demo generates two reproducible frames with a known block displacement and reports the recovered vector, candidate comparisons, and prediction mean squared error. It requires no video files.

## Motion component

```matlab
blockSize = 16;
searchRadius = 8;
[vectors, candidateCounts] = codec.estimateMotion(current, reference, blockSize, searchRadius);
prediction = codec.compensateMotion(reference, vectors, blockSize);
residual = double(current) - double(prediction);
```

- `current` and `reference` are equally sized grayscale frames of type `uint8`, `uint16`, `single`, or `double`. Use the previous reconstructed frame as `reference` when integrating the encoder and decoder.
- Each vector is `[dy, dx]` in pixels, measured from the current block to its match in the reference frame. Partial edge blocks are matched at their original size.
- The estimator minimizes the sum of absolute differences over in-frame candidates. Equal costs favor the shortest vector. `candidateCounts` gives the number of positions evaluated per block.
- The decoder can call `codec.compensateMotion` with the transmitted vectors, then add the decoded residual in floating point before clipping to the supported sample range.

## Integration milestones

1. Combine the 8 × 8 DCT, uniform scalar quantizer, and arithmetic coder for intra frames.
2. Use the same residual coding pipeline for inter frames and transmit their motion vectors.
3. Implement diamond search with the same vector convention. Compare full search and diamond search on bitrate, PSNR, encoding time, and candidate comparisons. Compute BD-Rate where the PSNR ranges overlap.
