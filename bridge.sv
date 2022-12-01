module bridge(input clk, INF.bridge_inf inf);

//================================================================
// logic 
//================================================================
parameter STATE_IDLE         = 3'd0 ;
parameter STATE_R_WAIT_READY = 3'd1 ;
parameter STATE_R_WAIT_VALID = 3'd2 ;
parameter STATE_W_WAIT_READY = 3'd3 ;
parameter STATE_W_WAIT_VALID = 3'd4 ;
parameter STATE_OUTPUT       = 3'd5 ;
logic [2:0] currunet_state, next_state;
logic [16:0] addr;
logic [63:0] data;
//================================================================
// state 
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin 
	if(!inf.rst_n)	inf.B_READY <= 0 ;
    else if(next_state == STATE_IDLE) inf.B_READY <= 0 ;
	else 			inf.B_READY <= 1 ;
end	
// MODE_READ
assign inf.AR_VALID = (currunet_state==STATE_R_WAIT_READY) ;//if give dram read address data r_valif=1

assign inf.AR_ADDR  = (currunet_state==STATE_R_WAIT_READY) ? addr : 0 ;	

assign inf.R_READY  = (currunet_state==STATE_R_WAIT_VALID) ;//if take from dram ready=1

// MODE_WRITE
assign inf.AW_VALID = (currunet_state==STATE_W_WAIT_READY) ;//if give dram write address data aw_valid=1

assign inf.AW_ADDR  = (currunet_state==STATE_W_WAIT_READY) ? addr : 0 ;	

//assign inf.W_DATA   = data ;
always_ff @(posedge clk or  negedge inf.rst_n) begin
	if (!inf.rst_n) 	inf.W_DATA <= 0 ;
	else if( next_state == STATE_IDLE ) inf.W_DATA <= 0 ;
    else inf.W_DATA <= data;
end
assign inf.W_VALID  = (currunet_state==STATE_W_WAIT_VALID) ;//if give dram write data w_valid=1

//================================================================
//   INPUT
//================================================================
always_ff @(posedge clk or  negedge inf.rst_n) begin
	if (!inf.rst_n) 	addr <= 0 ;
	else begin
		if (inf.C_in_valid==1)	addr <= 'd65536+(inf.C_addr<<3) ;
	end
end
always_ff @(posedge clk or  negedge inf.rst_n) begin
	if (!inf.rst_n) 	data <= 0 ;
	else begin
		if (inf.C_in_valid==1 && inf.C_r_wb==MODE_WRITE)	data <= inf.C_data_w ;
	end
end
//================================================================
//   OUTPUT
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) 	inf.C_out_valid <= 0 ;
	else begin
		if (next_state==STATE_OUTPUT)	inf.C_out_valid <= 1 ;
		else 							inf.C_out_valid <= 0 ;
	end
end
always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) 	inf.C_data_r <= 0 ;
	else begin
		if (inf.R_VALID==1) 	inf.C_data_r <= inf.R_DATA ;//AXI give read data axi input rvalid
		// if (inf.R_VALID==1) 	inf.C_data_r <= { inf.R_DATA[7:0] , inf.R_DATA[15:8] , inf.R_DATA[23:16] , inf.R_DATA[31:24] };
		else 					inf.C_data_r <= 0 ;
	end
end

//================================================================
//   FSM
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) 	currunet_state <= STATE_IDLE ;
	else 				currunet_state <= next_state ;
end
always_comb begin
	next_state = currunet_state ;
	case(currunet_state)
		STATE_IDLE: begin
			if (inf.C_in_valid==1) begin
				if (inf.C_r_wb==MODE_READ)	next_state = STATE_R_WAIT_READY ;
				else 						next_state = STATE_W_WAIT_READY ;
			end
		end
		STATE_R_WAIT_READY: if (inf.AR_READY==1)	next_state = STATE_R_WAIT_VALID ;
		STATE_R_WAIT_VALID: if (inf.R_VALID==1)		next_state = STATE_OUTPUT ;
		STATE_W_WAIT_READY: if (inf.AW_READY==1)	next_state = STATE_W_WAIT_VALID ;
		STATE_W_WAIT_VALID: if (inf.B_VALID==1)		next_state = STATE_OUTPUT ;
		STATE_OUTPUT:	next_state = STATE_IDLE ;
	endcase 
end
//=================

endmodule