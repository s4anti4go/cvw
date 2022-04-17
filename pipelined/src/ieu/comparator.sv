///////////////////////////////////////////
// comparator.sv
//
// Written: David_Harris@hmc.edu 8 December 2021
// Modified: 
//
// Purpose: Branch comparison
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// MIT LICENSE
// Permission is hereby granted, free of charge, to any person obtaining a copy of this 
// software and associated documentation files (the "Software"), to deal in the Software 
// without restriction, including without limitation the rights to use, copy, modify, merge, 
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons 
// to whom the Software is furnished to do so, subject to the following conditions:
//
//   The above copyright notice and this permission notice shall be included in all copies or 
//   substantial portions of the Software.
//
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
//   INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
//   PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
//   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
//   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE 
//   OR OTHER DEALINGS IN THE SOFTWARE.
////////////////////////////////////////////////////////////////////////////////////////////////

`include "wally-config.vh"

module comparator #(parameter WIDTH=32) (
  input  logic [WIDTH-1:0] a, b,
  output logic [2:0]       flags);

  logic [WIDTH-1:0] bbar, diff;
  logic             carry, eq, neg, overflow, lt, ltu;
/*
  // Subtractor implementation

  // subtraction
  assign bbar = ~b;
  assign {carry, diff} = a + bbar + 1;

  // condition code flags based on add/subtract output
  assign eq = (diff == 0);
  assign neg  = diff[WIDTH-1];
  // overflow occurs when the numbers being subtracted have the opposite sign 
  // and the result has the opposite sign fron the first
  assign overflow = (a[WIDTH-1] ^ b[WIDTH-1]) & (a[WIDTH-1] ^ diff[WIDTH-1]);
  assign lt = neg ^ overflow;
  assign ltu = ~carry;
  assign flags = {eq, lt, ltu};
*/

  /* verilator lint_off UNOPTFLAT */
  // prefix implementation
  localparam levels=$clog2(WIDTH);
  genvar i;
  genvar level;
  logic [WIDTH-1:0] e[levels:0];
  logic [WIDTH-1:0] l[levels:0];
  logic eq2, lt2, ltu2;

  // Bitwise logic
  assign e[0] = a ~^ b; // bitwise equality
  assign l[0] = ~a & b; // bitwise less than unsigned: A=0 and B=1

  // Recursion
  for (level = 1; level<=levels; level++) begin
    for (i=0; i<WIDTH/(2**level); i++) begin
      assign e[level][i] = e[level-1][i*2+1] & e[level-1][i*2];  // group equal if both parts equal
      assign l[level][i] = l[level-1][i*2+1] | e[level-1][i*2+1] & l[level-1][i*2]; // group less if upper is les or upper equal and lower less
    end
  end

  // Output logic
  assign eq2 = e[levels][0];  // A = B if all bits are equal
  assign ltu2 = l[levels][0]; // A < B if group is less (unsigned)
  // A < B signed if less than unsigned and msb is not < unsigned, or if A negative and B positive
  assign lt2 = ltu2 & ~l[0][WIDTH-1] | a[WIDTH-1] & ~b[WIDTH-1]; 
  assign flags = {eq2, lt2, ltu2};
  /* verilator lint_on UNOPTFLAT */
endmodule

