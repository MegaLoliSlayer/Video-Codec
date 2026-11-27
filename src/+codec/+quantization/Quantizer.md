# Quantization

-The quantizeCoeffBlock function takes as input the 8x8 or 16x16 DCT coefficient matrix (block), the quantization table (qt), zigzag table (zag), and returns a flattened 1D Quantized array of the coefficient block.
-The dequantizeCoeffVector function takes as input the blockSize*blockSize 1D input vector, quantization table (qt), zigzag table (zag), dequantizes it, and reshapes it into a blockSize*blockSize matrix.
-The init_JpegWithBlocksize Takes the blocksize and quality, and creates either a 8x8 or 16x16 quantizer table for JPEG like quantization.

16x16 quantization table from : 
A. Almohammad, G. Ghinea and R. M. Hierons, "JPEG Steganography: A Performance Evaluation of Quantization Tables," 2009 International Conference on Advanced Information Networking and Applications, Bradford, UK, 2009, pp. 471-478, doi: 10.1109/AINA.2009.67. keywords: {Steganography;Quantization;Transform coding;Discrete cosine transforms;Image coding;Pixel;Frequency;Testing;Internet;Image quality},

