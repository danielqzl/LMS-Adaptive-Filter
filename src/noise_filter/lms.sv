module lms #(
    parameter N = 50,
    parameter DATA_WIDTH = 16
) (
    input  logic clk, rst_n, clk_en,
    input  logic enable,
    input  logic signed [DATA_WIDTH-1:0] step_size,
    input  logic signed [DATA_WIDTH-1:0] e,
    input  logic signed [DATA_WIDTH-1:0] x_in, 
    output logic signed [DATA_WIDTH-1:0] weights [N]
);

    logic signed [DATA_WIDTH-1:0] x [N];
    logic signed [DATA_WIDTH-1:0] w [N];
    logic signed [DATA_WIDTH-1:0] delta;
    logic signed [2*DATA_WIDTH-1:0] delta_p;

    logic signed [DATA_WIDTH-1:0] w_update [N];
    logic signed [2*DATA_WIDTH-1:0] w_update_p [N];


    always_ff @(posedge clk) begin : u_x_pipepline
        if (!rst_n) begin
            x <= '{default:'0};
        end else if (clk_en && enable) begin
            x[0] <= x_in;
            for (int i = 1; i < N; i++) begin
                x[i] <= x[i-1];
            end
        end
    end

    always_comb begin : u_weight_update
        delta_p = step_size * e;
        delta = delta_p >>> (DATA_WIDTH-1); 
        for (int i = 0; i < N; i++) begin
            w_update_p[i] = delta * x[i];
            w_update[i] = w_update_p[i] >>> (DATA_WIDTH-1);
            w[i] = weights[i] + w_update[i];
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            weights <= '{default: '0};
        end else if (enable && clk_en) begin
            weights <= w;
        end
    end

endmodule
