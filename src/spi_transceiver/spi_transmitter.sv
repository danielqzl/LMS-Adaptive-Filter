// ----------------------------------------------------------------------------
// A Transmit Driver for Vivado AXI SPI IP Core
// ----------------------------------------------------------------------------

module spi_driver (
    input  logic clk, rst_n,
    input  logic [31:0] tx_data,
    input  logic tx_en,

    axi_lite.master m_axi
);

    logic axi_wr_en;
    logic [31:0] axi_wdata;
    logic [6:0]  axi_waddr;
    logic axi_wr_done;    

    axi_lite_transmitter u_axi (
        .clk(clk), .rst_n(rst_n),
        .wr_en(axi_wr_en),
        .wr_data(axi_wdata),
        .wr_addr(axi_waddr),
        .wr_done(axi_wr_done),
        .m_axi(m_axi)
    );


    // ----------------------------------------------------
    // FSM
    // ----------------------------------------------------
    typedef enum logic [2:0] { 
        START,
        CONFIG_SPICR,
        // CONFIG_IPIER,
        IDLE,
        SEND_DATA
    } state_t;
    
    state_t state, next_state;

    always_ff @(posedge clk) begin
        if (!rst_n) 
            state <= START;
        else 
            state <= next_state;
    end

    always_comb begin : fsm_logic
        axi_wr_en = '0;
        axi_wdata = '0;
        axi_waddr = '0; 
        case(state)
            START: begin
                if (rst_n) begin 
                    next_state = CONFIG_SPICR;
                    // Master, Manual SS disabled, 
                    axi_wr_en  = 1'b1;
                    axi_waddr  = 7'h60;
                    axi_wdata  = 32'h0004;
                end else begin
                    next_state = START;
                end
            end
            
            CONFIG_SPICR: begin
                if (axi_wr_done) begin
                    next_state = IDLE;
                end else begin
                    next_state = CONFIG_SPICR;
                end 
            end

            IDLE : begin
                if (tx_en) begin
                    next_state = SEND_DATA;
                    axi_wr_en  = 1'b1;
                    axi_waddr  = 7'h68;
                    axi_wdata  = tx_data;
                end else begin
                    next_state = IDLE;
                end
            end
            
            SEND_DATA : begin
                if (axi_wr_done) begin
                    next_state = IDLE;
                end else begin
                    next_state = SEND_DATA;
                end 
            end
        endcase
    end : fsm_logic

endmodule

