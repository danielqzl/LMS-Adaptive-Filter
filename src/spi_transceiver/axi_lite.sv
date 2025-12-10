interface axi_lite;
    logic [6:0] araddr;
    logic arready;
    logic arvalid;
    logic [6:0] awaddr;
    logic awready;
    logic awvalid;
    logic bready;
    logic [1:0] bresp;
    logic bvalid;
    logic [31:0] rdata;
    logic rready;
    logic [1:0] rresp;
    logic rvalid;
    logic [31:0] wdata;
    logic wready;
    logic [3:0] wstrb;
    logic wvalid;

    modport master(
        output araddr,
        input  arready,
        output arvalid,
        output awaddr,
        input  awready,
        output awvalid,
        output bready,
        input  bresp,
        input  bvalid,
        input  rdata,
        output rready,
        input  rresp,
        input  rvalid,
        output wdata,
        input  wready,
        output wstrb,
        output wvalid
    );

    modport slave(
        input  araddr,
        output arready,
        input  arvalid,
        input  awaddr,
        output awready,
        input  awvalid,
        input  bready,
        output bresp,
        output bvalid,
        output rdata,
        input  rready,
        output rresp,
        output rvalid,
        input  wdata,
        output wready,
        input  wstrb,
        input  wvalid
    );

endinterface


// ----------------------------------------------------------------------------
// A Simple module that transmits data via AXI4 Lite protocol
// ----------------------------------------------------------------------------
module axi_lite_transmitter(
    input  logic clk, rst_n,
    input  logic wr_en,
    input  logic [31:0] wr_data,
    input  logic [6:0]  wr_addr,
    output logic wr_done,

    axi_lite.master m_axi
);

    logic load_wr_ch, clr_wr_ch;

    // ----------------------------------------------------
    // Datapath
    // ----------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n | clr_wr_ch) begin
            m_axi.awvalid <= '0;
            m_axi.awaddr  <= '0;
            m_axi.wvalid  <= '0;
            m_axi.wdata   <= '0;
            m_axi.wstrb   <= '0;
            m_axi.bready  <= '0;
        end else if (load_wr_ch) begin
            m_axi.awvalid <= 1'b1;
            m_axi.awaddr  <= wr_addr;
            m_axi.wvalid  <= 1'b1;
            m_axi.wdata   <= wr_data;
            m_axi.wstrb   <= 4'hF;
            m_axi.bready  <= 1'b1;
        end
    end

    // ----------------------------------------------------
    // FSM
    // ----------------------------------------------------
    typedef enum logic [1:0] { 
        IDLE,
        IN_WRITE,
        WAIT_RESP
    } state_t;
    
    state_t state, next_state;

    always_ff @(posedge clk) begin
        if (!rst_n) 
            state <= IDLE;
        else 
            state <= next_state;
    end

    always_comb begin : fsm_logic
        load_wr_ch = '0;
        clr_wr_ch  = '0;
        case(state)
            IDLE: begin
                if (wr_en) begin
                    load_wr_ch = 1'b1;
                    next_state = IN_WRITE;
                end else begin
                    next_state = IDLE;
                end
            end

            IN_WRITE: begin
                if (m_axi.wready & m_axi.awready) begin
                    next_state = WAIT_RESP;
                    clr_wr_ch = 1'b1;
                end else begin
                    next_state = IN_WRITE;
                end
            end

            WAIT_RESP: begin
                if (m_axi.bvalid) begin
                    next_state = IDLE; 
                    wr_done = 1'b1;
                end else begin
                    next_state = WAIT_RESP;
                end
            end
        endcase
    end : fsm_logic


endmodule

