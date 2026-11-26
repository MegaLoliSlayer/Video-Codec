# Video Codec

The baseline uses full search to find matching blocks. The optimized version uses diamond search to check fewer positions. Both share the same motion compensation and residual coding pipeline so we can compare the effect of changing the search method.

## Where things go

- `data/` holds the raw luminance clips we test with, including `foreman_qcif.y`
- `tests/` holds the MATLAB scripts we use to run tests and benchmarks
- `results/` holds the CSVs those tests generate
- `src/+codec/` holds the codec code
  - `+motion/` has full search, diamond search, and motion compensation
  - `+transform/` is for the forward and inverse 8 × 8 DCT
  - `+quantization/` is for quantizing and reconstructing transform coefficients
  - `+entropy/` is for the arithmetic encoder and decoder