// (C) 2001-2025 Altera Corporation. All rights reserved.
// Your use of Altera Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License Subscription 
// Agreement, Altera IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


`timescale 1 ps / 1 ps

(* altera_attribute = "-name UNCONNECTED_OUTPUT_PORT_MESSAGE_LEVEL OFF" *)
module altera_gpio_one_bit(
	ck,
	ck_in,
	ck_out,
	oe,
	din,
	dout,
	pad,
	pad_b,
	puen,
	terminationcontrol,
	aclr,
	aset,
	sclr,
	sset,
	cke
);

	parameter PIN_TYPE = "output"; 
	parameter BUFFER_TYPE = "single-ended"; 
	parameter PSEUDO_DIFF = "false"; 
	parameter REGISTER_MODE = "none"; 
	parameter SEPARATE_I_O_CLOCKS = "false"; 
	parameter ARESET_MODE = "none"; 
	parameter SRESET_MODE = "none"; 
	parameter BUS_HOLD = "false"; 
	parameter OPEN_DRAIN = "false"; 
	parameter ENABLE_CKE = "false"; 
	parameter ENABLE_OE = "false"; 
	parameter ENABLE_TERM = "false"; 
	parameter DDIO_WITH_DELAY = "false"; 
	parameter DYNAMIC_PULL_UP_ENABLE = "false"; 

	localparam OE_SIZE = 1;
	localparam DATA_SIZE = (REGISTER_MODE == "ddr") ? 2: 1;
    localparam REG_MODE_IN = REGISTER_MODE == "ddr" && DDIO_WITH_DELAY == "true" ? "MODE_DDR_W_DLY" : REGISTER_MODE == "ddr" ? "MODE_DDR" : REGISTER_MODE == "sdr" ? "MODE_SDR" : "MODE_NONE";
    localparam REG_MODE_OUT = REGISTER_MODE == "ddr" ? "MODE_DDR" : REGISTER_MODE == "sdr" ? "MODE_SDR" : "MODE_NONE";
	localparam BUS_HOLD_PH2 = BUS_HOLD == "true" ? "BUS_HOLD_ON" : "BUS_HOLD_OFF";
	localparam OPEN_DRAIN_PH2 = OPEN_DRAIN == "true" ? "OPEN_DRAIN_ON" : "OPEN_DRAIN_OFF";
	localparam ARESET_MODE_PH2 = ARESET_MODE == "preset" ? "ASCLR_ENA_PRESET" : ARESET_MODE == "clear" ? "ASCLR_ENA_CLEAR" : "ASCLR_ENA_NONE";
	localparam SRESET_MODE_PH2 = SRESET_MODE == "preset" ? "SCLR_ENA_PRESET" : SRESET_MODE == "clear" ? "SCLR_ENA_CLEAR" : "SCLR_ENA_NONE";
	localparam DYNAMIC_PULL_UP_ENABLE_PH2 = DYNAMIC_PULL_UP_ENABLE == "true" ? "TRUE" : "FALSE";

    input ck;
	input ck_in;
	input ck_out;
	input [OE_SIZE - 1:0] oe;
	input [DATA_SIZE - 1:0] din;
	output [DATA_SIZE - 1:0] dout;
	inout pad;	
	inout pad_b;
	input puen;
	input terminationcontrol;
	input aclr;
	input aset;
	input sclr;
	input sset;
	input cke;

	wire hr_out_clk;
	wire fr_out_clk;
	wire hr_in_clk;
	wire fr_in_clk;

	wire din_ddr;
	wire buf_in;

	wire areset;
	wire sreset;


	generate
		if(ARESET_MODE == "preset") begin
			assign areset = ~aset;
		end
		else begin
			assign areset = ~aclr;
		end
	endgenerate

	generate
		if(SRESET_MODE == "preset") begin
			assign sreset = sset;
		end
		else begin
			assign sreset = sclr;
		end
	endgenerate

	generate
		if(SEPARATE_I_O_CLOCKS == "true") begin
			assign fr_out_clk = ck_out;
			assign fr_in_clk = ck_in;
		end
		else begin
			assign fr_out_clk = ck;
			assign fr_in_clk = ck;
		end
	endgenerate

	generate
	    if (PIN_TYPE == "output" || PIN_TYPE == "bidir") begin: out_path
			wire [1:0] din_fr;

	        assign din_fr[DATA_SIZE - 1:0] = din;

	        if (REGISTER_MODE == "ddr") begin: out_path_fr
	            tennm_ph2_ddio_out
	            #(
	            	.mode(REG_MODE_OUT),
	            	.asclr_ena(ARESET_MODE_PH2),
					.sclr_ena(SRESET_MODE_PH2)
	            ) fr_out_data_ddio (	
	    			.ena(cke),
	    			.areset(areset),
	    			.sreset(sreset),
	            	.datainhi(din_fr[1]),
	            	.datainlo(din_fr[0]),
	            	.dataout(din_ddr),
	            	.clk (fr_out_clk)
	            );
	        end
	        else if (REGISTER_MODE == "sdr") begin: out_path_reg
	            reg reg_data_out;
	            always @(posedge fr_out_clk)
	                reg_data_out <= din_fr[0];

	            assign din_ddr = reg_data_out;
	        end
	        else  
	        begin: out_path_byp
	            assign din_ddr = din_fr[0];
	        end
	    end
	endgenerate

	generate
		wire oe_fr;
		wire oe_ddr;
	    if (PIN_TYPE == "bidir" || ENABLE_OE == "true") begin: oe_path
	        
	        assign oe_fr = oe[0];

	        if (REGISTER_MODE == "ddr") begin: oe_path_fr
	            tennm_ph2_ddio_oe
	            #(
	                .mode(REG_MODE_OUT),
	                .asclr_ena("ASCLR_ENA_NONE"),
				    .sclr_ena("SCLR_ENA_NONE")
	            ) fr_oe_data_ddio (	
	    		    .ena(cke),
	                .oe(oe_fr),
	                .dataout(oe_ddr),
	                .clk (fr_out_clk)
	            );
	        end
	        else if (REGISTER_MODE == "sdr") begin: oe_path_reg
	            reg oe_reg;
	            always @(posedge fr_out_clk) oe_reg <= oe_fr;
	            assign oe_ddr = oe_reg;
	        end
	        else 
	        begin: oe_path_byp
	            assign oe_ddr = oe_fr;
	        end
	    end
	    else if (PIN_TYPE == "output")  
	    begin
	        assign oe_ddr = 1'b1;
	    end
	    else    
	    begin
	        assign oe_ddr = 1'b0;
	    end
	endgenerate

	generate
	    if (PIN_TYPE == "input" || PIN_TYPE == "bidir") begin : input_path
	        wire [1:0] buf_in_fr;

	        if (REGISTER_MODE == "ddr") begin: in_path_fr
	            tennm_ph2_ddio_in
	            #(
	                .mode(REG_MODE_IN),
	                .asclr_ena(ARESET_MODE_PH2),
	                .sclr_ena(SRESET_MODE_PH2)
	            ) buffer_data_in_fr_ddio (
	                .ena(cke),
	                .areset(areset),
	                .sreset(sreset),
	                .datain(buf_in),
	                .clk (fr_in_clk),
	                .regouthi(buf_in_fr[1]),
	                .regoutlo(buf_in_fr[0])
	            );
	        end
	        else if (REGISTER_MODE == "sdr") begin: in_path_reg
	            reg ro;
	            always @(posedge fr_in_clk) begin
	                ro <= buf_in;
	            end
	            assign buf_in_fr[0] = ro;
	        end
	        else begin: in_byp
	            assign buf_in_fr[0] = buf_in;
	        end
	        
	        begin: in_path_hr_byp
	            assign dout[DATA_SIZE - 1:0] = buf_in_fr[DATA_SIZE - 1:0];
	        end
	    end
	endgenerate

	generate
	    if (PIN_TYPE == "output" || PIN_TYPE == "bidir") begin : output_buffer
            `define IO_OBUF_PARAMS                                              \
                .open_drain(OPEN_DRAIN_PH2),                                    \
                .buffer_usage("REGULAR"),                                       \
                .dynamic_pull_up_enabled(DYNAMIC_PULL_UP_ENABLE_PH2),           \
                .equalization("EQUALIZATION_OFF"),                              \
                .io_standard("IO_STANDARD_IOSTD_OFF"),                          \
                .rzq_id("RZQ_ID_RZQ0"),                                         \
                .slew_rate("SLEW_RATE_SLOW"),                                   \
                .termination("TERMINATION_SERIES_OFF"),                         \
                .toggle_speed("TOGGLE_SPEED_SLOW"),                             \
                .usage_mode("USAGE_MODE_GPIO")      
	        
	        if(BUFFER_TYPE == "differential") begin
	            wire obuf_din_b; 
	            wire obuf_oe_b;
	            wire pos_neg_buf; 

	            if(PSEUDO_DIFF == "true") begin
	                if (PIN_TYPE == "output" && ENABLE_OE == "false") begin : oe_path
	                    tennm_ph2_pseudo_diff_out pseudo_diff_out(
	                        .i(din_ddr),
	                        .obar(obuf_din_b)
	                    );
	                    
	                    tennm_ph2_io_obuf #(
	                        `IO_OBUF_PARAMS
	                    ) obuf_0 (
	                        .i(din_ddr),
	                        .posbuf_out(pos_neg_buf), 
	                        .o(pad)
	                    );      
	                    
	                    tennm_ph2_io_obuf #(
	                        `IO_OBUF_PARAMS
	                    ) obuf_1 (
	                        .i(obuf_din_b),
	                        .negbuf_in(pos_neg_buf), 
	                        .o(pad_b)
	                    );  
	                end
	                else begin
	                    tennm_ph2_pseudo_diff_out pseudo_diff_out(
	                        .i(din_ddr),
	                        .oein(oe_ddr),
	                        .obar(obuf_din_b),
	                        .oebout(obuf_oe_b)
	                    );
	                   
	                    tennm_ph2_io_obuf #(
	                        `IO_OBUF_PARAMS
	                    ) obuf_0 (
	                        .i(din_ddr), 
	                        .oe(oe_ddr),
	                        .posbuf_out(pos_neg_buf),
	                        .o(pad)
	                    );
	                    
	                    tennm_ph2_io_obuf #(
	                        `IO_OBUF_PARAMS
	                    ) obuf_1 (
	                        .i(obuf_din_b), 
	                        .oe(obuf_oe_b),
	                        .negbuf_in(pos_neg_buf),
	                        .o(pad_b)
	                    );  
	                end
	            end
	            else begin 
	                tennm_ph2_pseudo_diff_out pseudo_diff_out(
	                    .i(din_ddr),
	                    .obar(obuf_din_b)
	                );
	                    
	                tennm_ph2_io_obuf #(
                        `IO_OBUF_PARAMS
	                ) obuf_0 (
	                    .i(din_ddr),
	                    .posbuf_out(pos_neg_buf), 
	                    .o(pad)
	                );      
	                
	                tennm_ph2_io_obuf #(
                        `IO_OBUF_PARAMS
	                ) obuf_1 (
	                    .i(obuf_din_b),
	                    .negbuf_in(pos_neg_buf), 
	                    .o(pad_b)
	                );  
	            end
	        end
	        else begin
	            if (PIN_TYPE == "bidir" || ENABLE_OE == "true") begin
                    if (DYNAMIC_PULL_UP_ENABLE == "true") begin
                        tennm_ph2_io_obuf #(
                        `IO_OBUF_PARAMS
                        ) obuf (
                            .i(din_ddr), 
                            .oe(oe_ddr),
                            .o(pad),
                            .pull_up_enable(puen)
                        );
                    end
                    else begin 
                        tennm_ph2_io_obuf #(
                        `IO_OBUF_PARAMS
                        ) obuf (
                            .i(din_ddr), 
                            .oe(oe_ddr),
                            .o(pad)
                        );
                    end 
	            end
	            else begin
	                tennm_ph2_io_obuf #(
                        `IO_OBUF_PARAMS
	                ) obuf (
	                    .i(din_ddr), 
	                    .o(pad)
	                ); 
	            end
	        end
	    end
	endgenerate

	generate
		if (PIN_TYPE == "input" || PIN_TYPE == "bidir") begin : input_buffer
            `define IO_IBUF_PARAMS                          \
                .bus_hold(BUS_HOLD_PH2),                    \
                .buffer_usage("REGULAR"),                   \
                .equalization("EQUALIZATION_OFF"),          \
                .io_standard("IO_STANDARD_IOSTD_OFF"),      \
                .rzq_id("RZQ_ID_RZQ0"),                     \
                .schmitt_trigger("SCHMITT_TRIGGER_OFF"),    \
                .termination("TERMINATION_RT_OFF"),         \
                .toggle_speed("TOGGLE_SPEED_SLOW"),         \
                .usage_mode("USAGE_MODE_GPIO"),             \
                .vref("VREF_OFF"),                          \
                .weak_pull_down("WEAK_PULL_DOWN_OFF"),      \
                .weak_pull_up("WEAK_PULL_UP_OFF")           
                      
		    if(BUFFER_TYPE == "differential") begin
		        tennm_ph2_io_ibuf 
		        #(
		            `IO_IBUF_PARAMS
		        ) ibuf (
		            .i(pad),
		            .ibar(pad_b),
		            .o(buf_in)
		        );         
		    end
		    else begin
		        tennm_ph2_io_ibuf 
		        #(
		            `IO_IBUF_PARAMS
		        ) ibuf (
		            .i(pad),
		            .o(buf_in)
		        );  
		    end
		end
	endgenerate

endmodule

(* altera_attribute = "-name UNCONNECTED_OUTPUT_PORT_MESSAGE_LEVEL OFF" *)
module altera_gpio(
	ck,
	ck_in,
	ck_out,
	oe,
	din,
	dout,
	pad_io,
	pad_io_b,
	pad_in,
	pad_in_b,
	pad_out,
	pad_out_b,
	puen,
	terminationcontrol,
	aclr,
	aset,
	sclr,
	sset,
	cke
);

	parameter PIN_TYPE = "output"; 
	parameter BUFFER_TYPE = "single-ended"; 
	parameter PSEUDO_DIFF = "false"; 
	parameter REGISTER_MODE = "none"; 
	parameter HALF_RATE = "false"; 
	parameter SEPARATE_I_O_CLOCKS = "false"; 
	parameter SIZE = 4;
	parameter ARESET_MODE = "none"; 
	parameter SRESET_MODE = "none"; 
	parameter BUS_HOLD = "false"; 
	parameter OPEN_DRAIN = "false"; 
	parameter ENABLE_CKE = "false"; 
	parameter ENABLE_OE = "false"; 
	parameter ENABLE_TERM = "false"; 
	parameter DDIO_WITH_DELAY = "false"; 
	parameter DYNAMIC_PULL_UP_ENABLE = "false"; 


	localparam OE_SIZE = 1;
	localparam DATA_SIZE = (REGISTER_MODE == "ddr") ? 2 : 1;

	input ck;
	input ck_in;
	input ck_out;
	input [SIZE * OE_SIZE - 1:0] oe;
	input [SIZE * DATA_SIZE - 1:0] din;
	output [SIZE * DATA_SIZE - 1:0] dout;
	input terminationcontrol;
	inout [SIZE - 1:0] pad_io;	
	inout [SIZE - 1:0] pad_io_b;
	input [SIZE - 1:0] pad_in;	
	input [SIZE - 1:0] pad_in_b;
	output [SIZE - 1:0] pad_out;	
	output [SIZE - 1:0] pad_out_b;		
	input [SIZE - 1:0] puen;
	input aclr;
	input aset;
	input sclr;
	input sset;
	input cke;

	wire [SIZE * OE_SIZE - 1:0] oe_reordered;
	wire [SIZE * DATA_SIZE - 1:0] din_reordered;
	wire [SIZE * DATA_SIZE - 1:0] dout_reordered;
	wire [SIZE - 1:0] pad_io;	
	wire [SIZE - 1:0] pad_io_b;
	
	generate
		if (PIN_TYPE == "input")
		begin
			assign pad_io = pad_in;
			assign pad_io_b = pad_in_b;
		end
		else if (PIN_TYPE == "output")
		begin
			assign pad_out = pad_io;
			assign pad_out_b = pad_io_b;
		end
	endgenerate

	genvar j, k;
	generate
			for(j = 0; j < SIZE ; j = j + 1) begin : j_loop
				for(k = 0; k < DATA_SIZE; k = k + 1) begin : k_d_loop
					assign din_reordered[j * DATA_SIZE + k] = din[j + k * SIZE];
					assign dout[j + k * SIZE] = dout_reordered[j * DATA_SIZE + k];
				end
				for(k = 0; k < OE_SIZE; k = k + 1) begin : k_oe_loop
					assign oe_reordered[j * OE_SIZE + k] = oe[j + k * SIZE];
				end
			end
	endgenerate

	genvar i;
	generate
			for(i = 0 ; i < SIZE ; i = i + 1) begin : i_loop
				altera_gpio_one_bit #(
					.PIN_TYPE(PIN_TYPE),
					.BUFFER_TYPE(BUFFER_TYPE),
					.PSEUDO_DIFF(PSEUDO_DIFF),
					.REGISTER_MODE(REGISTER_MODE),
					.DDIO_WITH_DELAY(DDIO_WITH_DELAY),
					.SEPARATE_I_O_CLOCKS(SEPARATE_I_O_CLOCKS),
					.ARESET_MODE(ARESET_MODE),
					.SRESET_MODE(SRESET_MODE),
					.BUS_HOLD(BUS_HOLD),
					.OPEN_DRAIN(OPEN_DRAIN),
					.ENABLE_CKE(ENABLE_CKE),
					.ENABLE_OE(ENABLE_OE),
					.ENABLE_TERM(ENABLE_TERM),
					.DYNAMIC_PULL_UP_ENABLE(DYNAMIC_PULL_UP_ENABLE)
				) altera_gpio_bit_i (
					.ck(ck),
					.ck_in(ck_in),
					.ck_out(ck_out),
					.oe(oe_reordered[(i + 1) * OE_SIZE - 1 : i * OE_SIZE]),
					.din(din_reordered[(i + 1) * DATA_SIZE - 1 : i * DATA_SIZE]),
					.dout(dout_reordered[(i + 1) * DATA_SIZE - 1 : i * DATA_SIZE]),
					.pad(pad_io[i]),
					.pad_b(pad_io_b[i]),
					.puen(puen[i]),
					.terminationcontrol(terminationcontrol),
					.aclr(aclr),
					.aset(aset),
					.sclr(sclr),
					.sset(sset),
					.cke(cke)
				);
			end
	endgenerate

endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "hbb5PQi7E6LnSxGa+rkFgVOwHdCqTifXQIsk8A1OZoUpiLfDuN64o1DFCKdKXADyY8mmTDb5Y98V+QfffQq77oDRw/xdccNW80opW7HiIZwn5m0PsqO72sidm+t9M6k1Q3JLs09/QGEZxglravIjQGwRp71BAdB6nlrqAxXkxTerNpHCTM0ec+NkZxKJiOmH/ze7sVQuwK05pb+Cvk9vQJqTEavYUGe/NffqsaBDKv1zAmc4nb75+Mxd2YuaTBqI52qmKXrRsOuPe5B35xY+V6197cZntAqU3WGbEsKtMoCSy2XvBdlZHSGHbEV3FDejiUregZsUauZCmSqxDRyIlEmServFMLSy/OqVBBMXOgQxP2sKqtstURiC7Vok/TZuwuxo1g/ckcaau+LCTdGIpmbKWS5CUUGCEHDbPwKGs6xS3T/0G56QRlHqnwpSVZEIUsQU1jAB23sdWisS2qpkkBLj+YkegWgr3MexUCr1Nv5+pTRkknVzBD4lNzg/utMYxb4Qx90odI5Ewl795+Dl3PsAcU+4r7y5GTf7ypzFP9VtBEXxOQ1Allmpe6MtcCPuzGoE6C/JtWN+/0qje6n3uHnKyT12SAbAQxxV7bupZLp9sg+6IVrl1k0fv27GjZ6oVCCfX9Kk1F9uyz/GVGMAAb4F1Tealz1mf4OoAiOOOOfokRql+OXW58REIrRxnKFgWnufvy2mubjyK17UJz8LTkmmEePSA1Kjs/gQWQ/E20tHo9bK55mKGDzZrl44eSnyMpy4xOtG2N0/DwM1GlteFbsi9mSVrGrQSMrNnK521HqHBTD+YQmprOGNAuX6sC9DTBU9qHigkbyHH8C2wqy2LzVDY+pJlUoiieIT9R3uoXEOiu/XSr33TfQoQR0JVhNsRjhXsvrPsJKZiZ/jiDgIUnWn2vyWhCaY7z/JG0XxC1PY5AQY31WVY77epUqHSTe20Tj1ZjVQnZSaTYdsI3Qw2sU2Mda/SDSBTjzvkKeJgjQknBjYlWFqGJSf1aal0iK6"
`endif