interface drp_if ();

    logic [6:0] addr;
    logic rd_en;
    logic [15:0] rd_data;
    logic data_rdy;
    logic wr_en;
    logic [15:0] wr_data;

    modport slave (
        output rd_data,
        output data_rdy,
        input  rd_en,
        input  wr_en,
        input  addr,
        input  wr_data
    ); 

    modport master (
        input rd_data,
        input data_rdy,
        output rd_en,
        output wr_en,
        output addr,
        output wr_data
    ); 

endinterface


module drp_transceiver (
    input  logic clk, rst_n, clk_en,
    input  logic rd_req,
    input  logic [6:0] addr,
    output logic rd_data_rdy,
    output logic [15:0] rd_data, 

    input  logic wr_en,
    input  logic [15:0] wr_data,

    drp_if.master drp
);

    always_ff @(posedge clk) begin
        if (rst_n && clk_en) begin
            drp.rd_en   <= rd_req;
            drp.wr_en   <= wr_en;
            drp.addr    <= addr;
            drp.wr_data <= wr_data;
        end else begin
            drp.wr_en   <= '0;
            drp.rd_en   <= '0;
            drp.addr    <= '0;
            drp.wr_data <= '0;
        end
    end

    // pass through  
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            rd_data_rdy <= '0;
            rd_data     <= '0;
        end else begin
            rd_data_rdy <= drp.data_rdy;
            rd_data     <= drp.rd_data;
        end 
    end
    
endmodule