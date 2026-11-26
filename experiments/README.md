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

The later rate–distortion runs will use decoder-output PSNR, total coded bits including side information, and end-to-end encoding time. That will let us compare bitrate at similar quality and calculate BD-Rate where the curves overlap.
