/*
module fir_pipelined_T #(
    parameter N = 10,
    parameter DATA_WIDTH = 16
)(
    input  logic clk, rst_n,
    input  logic signed [DATA_WIDTH-1:0] x_in,
    input  logic signed [DATA_WIDTH-1:0] weights [N],
    output logic signed [DATA_WIDTH-1:0] y
);

    // Pipeline array to hold partial accs
    logic signed [2*DATA_WIDTH-1:0] acc_pipeline [N];
    logic signed [2*DATA_WIDTH-1:0] acc_final;
    logic signed [DATA_WIDTH-1:0] x_in;


    always_ff @(posedge clk) begin
        if (!rst_n) begin
            acc_pipeline <= '{default: '0};
        end  
        else begin
            // Stage 0 partial acc: multiply newest sample by weights[0]
            acc_pipeline[0] <= ((x_in * weights[0]) >>> (DATA_WIDTH-1));
            // For i>0: acc_pipeline[i] = acc_pipeline[i-1] + (x * weights[i])
            for (int i = 1; i < N; i++) begin
                acc_pipeline[i] <= acc_pipeline[i-1] + ((x_in * weights[i]) >>> (DATA_WIDTH-1));
            end
        end
    end

    assign acc_final = acc_pipeline[N-1];
    assign y = acc_final[DATA_WIDTH-1:0];

endmodule
*/

module fir #(
    parameter N = 10,
    parameter DATA_WIDTH = 16
)(
    input  logic clk, rst_n,
    input  logic en,
    input  logic signed [DATA_WIDTH-1:0] x_in,
    input  logic signed [DATA_WIDTH-1:0] weights [N],
    output logic signed [DATA_WIDTH-1:0] y
);

    // array to hold partial accs
    logic signed [2*DATA_WIDTH-1:0] acc_p [N];
    logic signed [DATA_WIDTH-1:0] acc [N];
    
    logic signed [DATA_WIDTH-1:0] x [N];

    always_ff @(posedge clk) begin
        if (!rst_n)
            x <= '{default: '0};
        else if (en) begin 
            x[0] <= x_in;
            for (int i = 1; i < N; i++) 
                x[i] <= x[i-1]; 
        end     
    end

    always_comb begin
        acc_p[0] = x_in * weights[0];
        for (int i = 1; i < N; i++) acc_p[i] = x[i-1] * weights[i];
        
        for (int i = 0; i < N; i++)
            acc[i] = acc_p[i] >>> (DATA_WIDTH-1);
        
        // add all product 
        y = 0;
        for (int i = 0; i < N; i++)
            y = y + acc[i];  
        
    end

endmodule


module fir_mac #(
    parameter N = 10,
    parameter DATA_WIDTH = 16
)(
    input  logic clk, rst_n,
    input  logic en, 
    input  logic signed [DATA_WIDTH-1:0] x_in,
    input  logic signed [DATA_WIDTH-1:0] weights [N],
    output logic signed [DATA_WIDTH-1:0] y
);

    logic signed [DATA_WIDTH-1:0] x [N];
    logic signed [DATA_WIDTH-1:0] w [N];

    // register to hold intermediate product
    logic signed [2*DATA_WIDTH-1:0] acc_p;   
    logic signed [DATA_WIDTH-1:0] acc, new_acc; 

    // control signals 
    logic [$clog2(N)-1:0] cntr;
    logic acc_en, acc_clr, load_y;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            x <= '{default: '0};
            w <= '{default: '0};
        end else if (en) begin 
            x[0] <= x_in;
            for (int i = 1; i < N; i++) 
                x[i] <= x[i-1]; 
            w <= weights;
        end     
    end

    always_ff @(posedge clk) begin
        if (!rst_n | acc_clr) 
            cntr <= '0;
        else if (acc_en) 
            cntr <= cntr + 1;
    end

    always_ff @(posedge clk) begin
        if (!rst_n | acc_clr)
            acc <= '0;
        else if (acc_en) begin 
            acc_p = x[cntr] * w[cntr];
            new_acc = (acc_p >>> (DATA_WIDTH-1));
            acc <= acc + new_acc;
        end     
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            y <= '0;
        end else if (load_y) begin
            y <= acc;
        end 
    end 


       // ----------------------------------------------------
    // FSM
    // ----------------------------------------------------
    typedef enum logic [1:0] { 
        IDLE,
        ACCUMULATE,
        DONE
    } state_t;
    
    state_t state, next_state;

    always_ff @(posedge clk) begin
        if (!rst_n) 
            state <= IDLE;
        else 
            state <= next_state;
    end

    always_comb begin : fsm_logic
        acc_en  = '0;
        acc_clr = '0;
        load_y  = '0; 
        case(state)
            IDLE: begin
                acc_clr = 1'b1; 
                if (en) begin     
                    next_state = ACCUMULATE;
                end else begin
                    next_state = IDLE;
                end
            end
            
            ACCUMULATE: begin
                acc_en = 1'b1;
                if (cntr == (N-1)) begin
                    next_state = DONE;
                end else begin
                    next_state = ACCUMULATE;
                end 
            end

            DONE : begin
                load_y = 1'b1;
                next_state = IDLE;
            end
        endcase
    end : fsm_logic

endmodule



/*
module fir_pipelined #(
    parameter N = 10,
    parameter DATA_WIDTH = 16
)(
    input  logic clk, rst_n, x_valid,
    input  logic signed [DATA_WIDTH-1:0] x,
    input  logic signed [DATA_WIDTH-1:0] weights [N],
    output logic signed [DATA_WIDTH-1:0] y,
    output logic y_valid,
    output logic signed [DATA_WIDTH-1:0] x_pipeline [2*N]
);
 
    integer i;

    // Pipeline array to hold input and partial accs
    logic valid_pipe [2*N];

    logic signed [DATA_WIDTH-1:0] x_in;
    logic signed [DATA_WIDTH-1:0] x_pipe [2*N];

    logic signed [2*DATA_WIDTH-1:0] acc_pipe [N];
    logic signed [2*DATA_WIDTH-1:0] acc_final;

    always_comb begin
        if (x_valid)
            x_in = x;
        else
            x_in = 0;     
    end

    always_ff @(posedge clk) begin : u_input_pipepline
        if (!rst_n) begin
            x_pipe <= '{default:'0};
        end else begin
            x_pipe[0] <= x_in;
            for (i = 1; i < 2*N; i++) begin
                x_pipe[i] <= x_pipe[i-1];
            end
        end
    end

    always_ff @(posedge clk) begin : u_valid_pipeline
        if (!rst_n) begin
            valid_pipe <= '{default:'0};
        end else begin
            valid_pipe[0] <= x_valid;
            for (i = 1; i < N; i++) begin
                valid_pipe[i] <= valid_pipe[i-1];
            end
        end
    end

    always_ff @(posedge clk) begin : u_acc_pipeline
        if (!rst_n) begin
            acc_pipe <= '{default:'0};
        end else begin
            acc_pipe[0] <= (x_in * weights[0]) >>> (DATA_WIDTH-1);
            for (i = 1; i < N; i++) begin
                acc_pipe[i] <= acc_pipe[i-1] + ((x_pipe[2*i-1] * weights[i]) >>> (DATA_WIDTH-1));
            end
        end
    end

    assign acc_final = acc_pipe[N-1];
    assign y = acc_final[DATA_WIDTH-1:0];

    assign y_valid = valid_pipe[N-1];

    assign x_pipeline = x_pipe;
endmodule

*/