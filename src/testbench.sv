
// Testbench for Noise Filter using the standard FIR Filter
/*
module noise_filer_tb_std_fir;
    parameter NUM_TAPS = 4;
    parameter DATA_WIDTH = 16;
    parameter CLK_CYCLE = 8;

    parameter string DIR = "../../../../../test_vector/";

    logic clk, rst_n;
    logic signed [DATA_WIDTH-1:0] in, ref_s;
    logic signed [DATA_WIDTH-1:0] out;
    logic signed [DATA_WIDTH-1:0] step_size;

    // queues to hold test vectors 
    logic signed [DATA_WIDTH-1:0] test_in  [$]; 
    logic signed [DATA_WIDTH-1:0] test_ref [$];
    logic signed [DATA_WIDTH-1:0] test_out [$];
    logic signed [DATA_WIDTH-1:0] dut_out  [$];
    int num_samples = 0;


    // ----------------------------------------------------
    // clk gen
    // ----------------------------------------------------
    always begin
        clk <= 1; # 5; clk <= 0; # 5;
    end
    logic clk_en;


    // ----------------------------------------------------
    // Load Test Vectors 
    // ----------------------------------------------------
    initial begin
        int file;
        logic signed [DATA_WIDTH-1:0] d, n, e;
        
        $display("Test unit: LMS Noise Filter");

        $display("Loading test vectors from file...");
        file = $fopen({DIR,"testvector.txt"}, "r");
        if (file == 0) begin
            $display("Error: Cannot open testvector.txt");
            $stop;
        end

        while(!$feof(file)) begin
            // Read input signal, noise and expected output
            $fscanf(file, "%d %d %d\n", d, n, e);
            test_in.push_back(d);
            test_ref.push_back(n);
            test_out.push_back(e);
            num_samples++;
        end

        step_size = 655;

        $fclose(file);
        $display("Test Vectors loaded.");
    end


    // ----------------------------------------------------
    // Init DUT
    // ----------------------------------------------------
    noise_filter #(.N(NUM_TAPS), .DATA_WIDTH(DATA_WIDTH)) dut (
        .clk(clk), .rst_n(rst_n), 
        .lms_en(enable),
        .clk_en(clk_en),
        .step_size(step_size),
        .d(in),
        .ref_s(ref_s), 
        .out(out)
    );


    // ----------------------------------------------------
    // Feed input signals
    // ----------------------------------------------------
    initial begin
        clk_enable = 0;
        in = '0;
        ref_s = '0;
        rst_n = 1'b0;
        #20;
        rst_n = 1'b1;

        enable <= 1'b1;
        @(posedge clk);
        for(int i = 0; i < num_samples; i++) begin
            in <= test_in.pop_front();
            ref_s <= test_ref.pop_front();
            @(posedge clk);
        end
        enable <= 1'b0;
    end


    // ----------------------------------------------------
    // Collect filter output 
    // ----------------------------------------------------
    initial begin
        @(posedge rst_n);
        repeat(2) @(posedge clk);
        record_output();
        compare_queues(test_out, dut_out, "Expected", "DUT");
    end

    task record_output();
        for (int i = 0; i <  num_samples; i++) begin
            dut_out.push_back(out);
            @(posedge clk);
        end
    endtask

    task automatic compare_queues (
        input  logic signed [DATA_WIDTH-1:0] q1[],     // first queue
        input  logic signed [DATA_WIDTH-1:0] q2[],     // second queue
        input  string name1 = "q1",
        input  string name2 = "q2"
    );
        int size1, size2;
        bit equal = 1;

        size1 = q1.size();
        size2 = q2.size();

        if (size1 != size2) begin
            $display("ERROR: Queue size mismatch (%s=%0d, %s=%0d)", 
                    name1, size1, name2, size2);
            equal = 0;
        end

        // Compare elements up to min(size1, size2)
        for (int i = 0; i < (size1 < size2 ? size1 : size2); i++) begin
            if (q1[i] !== q2[i]) begin
                equal = 0;
            end
        end

        if (equal)
            $display("PASS: Queues %s and %s are equal", name1, name2);
        else
            $display("FAIL: Queues %s and %s not equal", name1, name2);
    endtask

endmodule
*/

// ----------------------------------------------------------------------------
// Testbench for for Noise Filter
// ----------------------------------------------------------------------------
module noise_filer_tb;
    parameter NUM_TAPS = 4;
    parameter DATA_WIDTH = 16;
    parameter CLK_CYCLE = 8;

    parameter string DIR = "../../../../../test_vector/";

    logic clk, rst_n;
    logic enable;
    logic signed [DATA_WIDTH-1:0] in, ref_s;
    logic signed [DATA_WIDTH-1:0] out;
    logic signed [DATA_WIDTH-1:0] step_size;

    // queues to hold test vectors 
    logic signed [DATA_WIDTH-1:0] test_in  [$]; 
    logic signed [DATA_WIDTH-1:0] test_ref [$];
    logic signed [DATA_WIDTH-1:0] test_out [$];
    logic signed [DATA_WIDTH-1:0] dut_out  [$];
    int num_samples = 0;


    // ----------------------------------------------------
    // clk gen
    // ----------------------------------------------------
    always begin
        clk <= 1; # 5; clk <= 0; # 5;
    end

    logic [7:0] clk_cntr;
    logic clk_en;
    always_ff @(posedge clk) begin : u_clk_cntr
        if (!rst_n) begin
            clk_en <= 1'b0;
            clk_cntr <= '0;
        end else if (clk_cntr == CLK_CYCLE - 1) begin
            clk_en <= 1'b1;
            clk_cntr <= '0;
        end else if (enable) begin 
            clk_en <= 1'b0;
            clk_cntr <= clk_cntr + 1;
        end
    end

    // ----------------------------------------------------
    // Load Test Vectors 
    // ----------------------------------------------------
    initial begin
        int file;
        logic signed [DATA_WIDTH-1:0] d, n, e;
        
        $display("Test unit: LMS Noise Filter");

        $display("Loading test vectors from file...");
        file = $fopen({DIR,"testvector.txt"}, "r");
        if (file == 0) begin
            $display("Error: Cannot open testvector.txt");
            $stop;
        end

        while(!$feof(file)) begin
            // Read input signal, noise and expected output
            $fscanf(file, "%d %d %d\n", d, n, e);
            test_in.push_back(d);
            test_ref.push_back(n);
            test_out.push_back(e);
            num_samples++;
        end

        step_size = 655;

        $fclose(file);
        $display("Test Vectors loaded.");
    end


    // ----------------------------------------------------
    // Init DUT
    // ----------------------------------------------------
    noise_filter #(.N(NUM_TAPS), .DATA_WIDTH(DATA_WIDTH)) dut (
        .clk(clk), .rst_n(rst_n), 
        .lms_en(enable),
        .clk_en(clk_en),
        .step_size(step_size),
        .d(in),
        .ref_s(ref_s), 
        .out(out)
    );


    // ----------------------------------------------------
    // Feed input signals
    // ----------------------------------------------------
    initial begin
        enable = 0;
        in = '0;
        ref_s = '0;
        rst_n = 1'b0;
        #20;
        rst_n = 1'b1;

        enable <= 1'b1;
        repeat(CLK_CYCLE) @(posedge clk);
        for(int i = 0; i < num_samples; i++) begin
            in <= test_in.pop_front();
            ref_s <= test_ref.pop_front();
            repeat(CLK_CYCLE) @(posedge clk);
        end
        enable <= 1'b0;
    end


    // ----------------------------------------------------
    // Collect filter output 
    // ----------------------------------------------------
    initial begin
        @(posedge rst_n);
        repeat(2 * CLK_CYCLE) @(posedge clk);
        record_output();
        repeat(2) @(posedge clk);
        compare_queues(test_out, dut_out, "Expected", "DUT");
    end

    task record_output();
        for (int i = 0; i <  num_samples; i++) begin
            dut_out.push_back(out);
            repeat(CLK_CYCLE) @(posedge clk);
        end
    endtask

    task automatic compare_queues (
        input  logic signed [DATA_WIDTH-1:0] q1[],     // first queue
        input  logic signed [DATA_WIDTH-1:0] q2[],     // second queue
        input  string name1 = "q1",
        input  string name2 = "q2"
    );
        int size1, size2;
        bit equal = 1;

        size1 = q1.size();
        size2 = q2.size();

        if (size1 != size2) begin
            $display("ERROR: Queue size mismatch (%s=%0d, %s=%0d)", 
                    name1, size1, name2, size2);
            equal = 0;
        end

        // Compare elements up to min(size1, size2)
        for (int i = 0; i < (size1 < size2 ? size1 : size2); i++) begin
            if (q1[i] !== q2[i]) begin
                equal = 0;
            end
        end

        if (equal)
            $display("PASS: Queues %s and %s are equal", name1, name2);
        else
            $display("FAIL: Queues %s and %s not equal", name1, name2);
    endtask

endmodule
