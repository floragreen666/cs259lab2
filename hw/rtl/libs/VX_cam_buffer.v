`include "VX_platform.vh"

module VX_cam_buffer #(
    parameter DATAW    = 1,
    parameter SIZE     = 1,
    parameter RPORTS   = 1,
    parameter ADDRW  = `LOG2UP(SIZE)
) (
    input  wire clk,
    input  wire reset,
    input  wire [DATAW-1:0] write_data,        
    output wire [ADDRW-1:0] write_addr,
    input  wire acquire_slot,
    input  wire [RPORTS-1:0][ADDRW-1:0] read_addr,
    output reg [RPORTS-1:0][DATAW-1:0] read_data,
    input  wire [RPORTS-1:0] release_slot,        
    output wire full
);
    reg [DATAW-1:0] entries [SIZE-1:0];
    reg [SIZE-1:0] free_slots, free_slots_n;
    reg [ADDRW-1:0] write_addr_r;
    reg full_r;
        
    wire free_valid;
    wire [ADDRW-1:0] free_index;

    VX_priority_encoder #(
        .N(SIZE)
    ) free_slots_encoder (
        .data_in   (free_slots_n),
        .data_out  (free_index),
        .valid_out (free_valid)
    );  

    integer i;

    always @(*) begin
        free_slots_n = free_slots;
        if (acquire_slot)  begin
            free_slots_n[write_addr_r] = 0;
        end            
        for (i = 0; i < RPORTS; i++) begin 
            if (release_slot[i]) begin
                free_slots_n[read_addr[i]] = 1;                
            end
            read_data[i] = entries[read_addr[i]];            
        end
    end    

    always @(posedge clk) begin
        if (reset) begin
            free_slots   <= {SIZE{1'b1}};
            full_r       <= 1'b0;
            write_addr_r <= ADDRW'(1'b0);
        end else begin
            if (acquire_slot) begin
                assert(1 == free_slots[write_addr]); 
                entries[write_addr] <= write_data;                
            end
            for (i = 0; i < RPORTS; i++) begin 
                if (release_slot[i]) begin
                    assert(0 == free_slots[read_addr[i]]);
                end
            end
            free_slots   <= free_slots_n;
            write_addr_r <= free_index;
            full_r       <= ~free_valid;
        end
    end

    assign write_addr = write_addr_r;
    assign full       = full_r;

endmodule