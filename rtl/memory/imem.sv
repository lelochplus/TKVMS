`timescale 1ns/1ps

module imem #(
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 32
)(
    input  logic [31:0] addr,
    output logic [DATA_WIDTH-1:0] rdata
);

    localparam DEPTH = 1 << ADDR_WIDTH;

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    assign rdata = mem[addr[ADDR_WIDTH+1:2]];

endmodule
