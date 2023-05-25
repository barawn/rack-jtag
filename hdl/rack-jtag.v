`timescale 1ns / 1ps
// generic JTAG multiplexer
// by default port 0 is enabled

module rack_jtag(
    output [6:0] TCK,
    output [6:0] TMS,
    output [6:0] TDI,
    input [6:0] TDO,
    input TTCK,
    input TTMS,
    input TTDI,
    output TTDO,
    input TCTRL_B,
	 output LED
    );


	reg [7:0] chain_enable = 8'h01;
	
	always @(posedge TTCK) if (!TCTRL_B) chain_enable <= {chain_enable[6:0], TTDI};

	assign LED = chain_enable[7];

	wire [7:0] tdi_chain;

	wire int_tck = (!TCTRL_B || TTCK);
	wire int_tms = (!TCTRL_B || TTMS);
	wire int_tdi = (!TCTRL_B || TTDI);
	
	// OK, so here's the way this works.
	// Pretend ALL of them are connected.
	// Now tdi_chain[i] is the input to device i
	// and tdo_chain[i] is the output from device i
	//
	// So with 2 devices,
	// TDI[0] = tdi_chain[0] = TTDI
	// TDI[1] = tdi_chain[1] = TDO[0]
	// tdi_chain[2] = TDO[1] = TTDO
	//
	// To *bypass* a device we just hook up tdi_chain[i+1] = tdi_chain[i]
	assign tdi_chain[0] = int_tdi;
	assign TTDO = tdi_chain[7];
	generate
		genvar i;
		for (i=0;i<7;i=i+1) begin : CH
			assign TCK[i] = (chain_enable[i]) ? int_tck: 1'bZ;
			assign TMS[i] = (chain_enable[i]) ? int_tms : 1'bZ;
			assign TDI[i] = (chain_enable[i]) ? tdi_chain[i] : 1'bZ;
			assign tdi_chain[i+1] = (chain_enable[i]) ? TDO[i] : tdi_chain[i];
		end
	endgenerate

endmodule
