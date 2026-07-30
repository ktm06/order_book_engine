module CDC_Input_Synchronizer #(
    parameter SYNC_REG_LENGTH = 2
) (
    input logic async_in,
    output logic sync_out,
    input CLK,
    input RESET
);

// quartus setup/time hold override
(* altera_attribute = {"-name SDC_STATEMENT \"set_false_path -to [get_registers {*|CDC_Input_Synchronizer:*|sync_reg[0]}]\""} *)

logic [SYNC_REG_LENGTH-1:0] sync_reg;

always_ff @(posedge CLK) begin
    sync_reg <= {sync_reg[SYNC_REG_LENGTH-2:0], async_in};
end

assign sync_out = sync_reg[SYNC_REG_LENGTH-1];

endmodule