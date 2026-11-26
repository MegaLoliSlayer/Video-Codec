# Motion benchmark

The benchmark compares full-search block matching with a zero-motion baseline that simply predicts each frame from the previous one. Both methods get the same original reference frame for every pair. The codec will use reconstructed references once inter-frame encoding is connected.

## Reproduce the run

Use the QCIF Y4M clips from Xiph.org's video test media collection. The recorded run used the first 31 frames of each clip at 176 × 144 pixels, giving 30 frame pairs per method. Download the clips into a local folder. [Xiph.org test media collection](https://media.xiph.org/video/derf/)

- [Akiyo](https://media.xiph.org/video/derf/y4m/akiyo_qcif.y4m)
- [Foreman](https://media.xiph.org/video/derf/y4m/foreman_qcif.y4m)
- [Football at 15 fps](https://media.xiph.org/video/derf/y4m/football_qcif_15fps.y4m)

Run this from the repository root in MATLAB. Set `clipFolder` to the folder holding the downloads.

```matlab
addpath('src', 'experiments');
clipFolder = "path/to/clips";
clips = fullfile(clipFolder, ["akiyo_qcif.y4m"; "foreman_qcif.y4m"; "football_qcif_15fps.y4m"]);
[summary, perFrame] = benchmarkY4m(clips, "experiments/results", 31);
```

To compare another method, pass a struct of names and function handles as the fourth argument to `benchmarkY4m`. Each handle must accept `(current, reference, blockSize, searchRadius)` and return `[vectors, candidateCounts]` with the same conventions as `codec.motion.estimateMotion`. Score only in-frame positions within the supplied radius. The runner adds `ZeroMotion` automatically. It uses 16 × 16 motion blocks and a ±8-pixel search radius.

## Read the results

The [summary CSV](results/motion-summary.csv) has one row per clip and method. The [per-frame CSV](results/motion-per-frame.csv) contains each measured prediction. `Frame` is the one-based index of the frame being predicted.

- `ResidualMSE` and `ResidualMAE` measure error between the input frame and its prediction. Summary values pool pixels across the frame pairs. Prediction PSNR uses that pooled MSE and an 8-bit peak value of 255. An exact prediction has infinite PSNR.
- `Candidates` counts the reference positions scored, summed across blocks. The zero-motion baseline scores zero positions.
- `SearchMs` times the estimator call. `MotionStageMs` adds motion compensation and residual calculation. Each clip and method gets one warm-up pair before timing. The recorded run used MATLAB R2022b on Windows. Timing depends on the machine and MATLAB session.

To compare full codecs, measure decoder-output PSNR, total coded bits including side information, and end-to-end encoding time. Use the overlapping PSNR range when calculating BD-Rate.

## Run on raw luminance files

Raw `.y` clips store one byte per luminance sample and carry no dimensions in the file. Pass the original width and height explicitly. This example uses the first 100 frames of the course's 176 × 144 Foreman clip.

```matlab
addpath('src', 'experiments');
frames = readRawLuma("path/to/foreman_qcif.y", 176, 144, 100);
[motionSummary, motionPerFrame] = benchmarkMotion(frames);
```

## Run the Lab 5 I/P baseline

Add the folder containing the Lab 5 MATLAB image encoder, decoder, and their helpers to your path. This experiment needs the MATLAB toolboxes used by the lab for the DCT and arithmetic coding.

```matlab
addpath("path/to/lab5/Matlab");
[codecSummary, codecPerFrame] = benchmarkLab5Codec(frames, [10 30 50 70 90]);
```

The first frame is intra-coded. The other frames use 16 × 16 full-search blocks, a ±8-pixel window, and the previous decoded frame as the reference. The image coder accepts only uint8, so the benchmark rounds each signed residual after dividing by two and offsets it by 128. The decoder reverses the scale and offset. The runner pads images to multiples of eight and crops all reconstructions to the original dimensions.

The rate counts the stored image payloads, arithmetic models, image headers, motion-vector MAT files, and sequence metadata. Bits per pixel uses the original luminance pixel count, including the I-frame. The runner decodes the saved files again, checks that both sides reconstructed the same frames, and reports both pooled PSNR and mean frame PSNR. Encoding time includes the local decoding required to keep the encoder's reference in sync and the temporary image I/O. The files are written to a temporary directory and cleaned up after the run.

Results for the course Foreman clip are in the [codec summary](results/foreman-100-lab5-summary.csv), [codec per-frame measurements](results/foreman-100-lab5-per-frame.csv), and [motion-only summary](results/foreman-100-motion-summary.csv).
