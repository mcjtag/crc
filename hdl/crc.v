`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Dmitry Matyunin (https://github.com/mcjtag)
// 
// Create Date: 12.07.2024 14:05:46
// Design Name: crc
// Description: Dynamically Configurable CRC
// License: MIT
//  Copyright (c) 2024 Dmitry Matyunin
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
// 
//////////////////////////////////////////////////////////////////////////////////

module crc #(
	parameter DATA_WIDTH = 32,				// Width of Data
	parameter CRC_WIDTH = 32				  // Max Width of CRC
)
(
	input wire clk,							          // Clock
	input wire resetn,						        // Active-Low Reset
	input wire clear,						          // CRC Initialization
	input wire [CRC_WIDTH-1:0]init_in,	  // Init State
	input wire [CRC_WIDTH:0]poly_in,		  // Polinomial (full notation)
	input wire data_reverse,				      // Data Bit-Reverse
	input wire crc_reverse,					      // CRC Bit-Reverse
	input wire [CRC_WIDTH-1:0]xorout_in,	// CRC Output XOR Mask
	input wire [DATA_WIDTH-1:0]data_in,		// Data
	input wire data_in_valid,				      // Valid Data
	output wire [CRC_WIDTH-1:0]crc_out		// CRC
);

reg [CRC_WIDTH-1:0]state;
reg [CRC_WIDTH-1:0]crc, crc_next;
wire [CRC_WIDTH-1:0]state_out;
reg [DATA_WIDTH-1:0]data;
integer i;

assign crc_out = crc;

// Main FSM
always @(posedge clk or negedge resetn) begin
	if (resetn == 1'b0) begin
		state <= 'd0;
		crc <= 'd0;
	end else begin
		if (clear == 1'b1) begin
			state <= init_in;
			crc <= 'd0;
		end else begin
			if (data_in_valid) begin
				state <= state_out;
				crc <= crc_next;
			end
		end
	end
end

// Data Reverse
always @(*) begin
	data = data_in;
	if (data_reverse == 1'b1) begin
		for (i = 0; i < DATA_WIDTH; i = i + 1) begin
			data[i] = data_in[DATA_WIDTH-1-i];
		end
	end
end

// CRC Reverse & XOR
always @(*) begin
	crc_next = state_out;
	if (crc_reverse == 1'b1) begin
		for (i = 0; i < CRC_WIDTH; i = i + 1) begin
			crc_next[i] = state_out[CRC_WIDTH-1-i];
		end
	end
	crc_next = crc_next ^ xorout_in;
end

crc_lfsr #(
	.DATA_WIDTH(DATA_WIDTH),
	.POLY_WIDTH(CRC_WIDTH)
) crc_lfsr_inst (
	.state_in(state),
	.data_in(data),
	.poly_in(poly_in),
	.state_out(state_out)
);

endmodule

//
// LFSR (Galois Style)
//
module crc_lfsr #(
	parameter DATA_WIDTH = 4,		// Data Width
	parameter POLY_WIDTH = 4		// Polynomial Width
)
(
	input wire [POLY_WIDTH-1:0]state_in,	// Init State
	input wire [DATA_WIDTH-1:0]data_in,		// Input Data
	input wire [POLY_WIDTH  :0]poly_in,		// Polynomial
	output wire [POLY_WIDTH-1:0]state_out	// Output State
);

reg [POLY_WIDTH-1:0]c_state[DATA_WIDTH  :0];
reg [POLY_WIDTH-1:0]r_state[DATA_WIDTH-1:0];
reg [POLY_WIDTH  :0]t_state[DATA_WIDTH-1:0];
reg [$clog2(POLY_WIDTH+1)-1:0]deg_p;
reg [POLY_WIDTH-1:0]r_mask;

integer i, j;

assign state_out = c_state[DATA_WIDTH] & r_mask;

always @(*) begin
	deg_p = 'd0;
	for (i = 0; i < POLY_WIDTH+1; i = i + 1)begin
		if (poly_in[i] & 1'b1) begin
			deg_p = i;
		end	 
	end
	for (i = 0; i < POLY_WIDTH; i = i + 1) begin
		r_mask[i] = 1'b0;
		if (i < deg_p) begin
			r_mask[i] = 1'b1;
		end
	end
end

always @(*) begin
	c_state[0] = state_in;
	for (i = 0; i < DATA_WIDTH; i = i + 1) begin
		t_state[i][0] = 1'b0; 
		for (j = 1; j < POLY_WIDTH+1; j = j + 1) begin
			t_state[i][j] = c_state[i][j-1];
		end
		for (j = 0; j < POLY_WIDTH; j = j + 1) begin
			r_state[i][j] = t_state[i][j] ^ (poly_in[j] & (t_state[i][deg_p] ^ data_in[DATA_WIDTH-1-i]));
		end
		c_state[i+1] = r_state[i];
	end
end

endmodule
