# crc
Dynamically configurable CRC (Verilog)

## Parameters:
* `DATA_WIDTH`     - Data width
* `CRC_WIDTH`      - Max CRC width

Example: if `CRC_WIDTH` set to 32, it is possible to implement any CRC algorithm with polynomial degree up to 32 (CRC4, CRC8, CRC9, CRC16, etc.).

## Ports

* `clk`           - Input clock
* `resetn`        - Asynchronous reset (active-LOW)
* `clear`         - CRC Clear/Initialization
* `init_in`       - Init State
* `poly_in`       - Polinomial (full notation* needs for correct calculation of polynomial degree)
* `data_reverse`  - Data Bit-Reverse
* `crc_reverse`   - CRC Bit-Reverse
* `xorout_in`     - CRC Output XOR Mask
* `data_in`       - Input Data
* `data_in_valid` - Valid Data Flag
* `crc_out`       - Output CRC

Note: Full notation - for example if needs to implement CRC8 (x^8+x^2+x^1+1), then poly_in will be 'b1_0000_0111 or 'h107.

## Simple (not configurable) 8-bit Galois LFSR, 1-bit Data width
![LFSR8_1](/img/crc_glfsr8_1.png)

## Simple (not configurable) 8-bit Galois LFSR, 4-bit Data width
![LFSR8_4](/img/crc_glfsr8_4.png)

## Configurable 8-bit Galois LFSR, 3-bit Data width
![LFSR8_3](/img/crc_glfsr8_3d.png)

`P` - input polynomial (`poly_in`)
