

module noise_filer_ip_tb;
    parameter NUM_TAPS = 4;
    parameter DATA_WIDTH = 16;
    parameter CLK_C = 4;
    parameter STEP_SIZE = 655;

    parameter string DIR = "../../../../../test_vector/";

    logic clk, rst_n;
    logic lms_en;
    logic clk_en;
    logic [11:0] in, ref_s;
    logic signed [DATA_WIDTH-1:0] out;

    // queues to hold test vectors 
    logic [11:0] test_in  [$]; 
    logic [11:0] test_ref [$];
    logic signed [DATA_WIDTH-1:0] test_out [$];

    logic signed [DATA_WIDTH-1:0] dut_out  [$];

    int num_samples = 0;

    // Interface 
    drp_if i_drp_d();
    drp_if i_drp_n();


    // clk gen
    always begin
        clk <= 1; # 5; clk <= 0; # 5;
    end

    // Load Test Vectors 
    initial begin
        int file;
        logic [11:0] adc_d, adc_n;
        logic signed [DATA_WIDTH-1:0] e;
        
        $display("Test unit: LMS Noise Filter");

        $display("Loading test vectors from file...");
        file = $fopen({DIR,"testvector_ip.txt"}, "r");
        if (file == 0) begin
            $display("Error: Cannot open testvector.txt");
            $stop;
        end

        while(!$feof(file)) begin
            // Read input signal, noise and expected output
            $fscanf(file, "%h %h %d\n", adc_d, adc_n, e);
            test_in.push_back(adc_d);
            test_ref.push_back(adc_n);
            test_out.push_back(e);
            num_samples++;
        end

        $fclose(file);
        $display("Test Vectors loaded.");
    end

    // Init DUT
    noise_filter_ip #(
        .N_TAPS(NUM_TAPS), 
        .CLK_CYCLE(CLK_C),
        .STEP_SIZE(STEP_SIZE),
        .DRP_ADDR_D (7'h10),
        .DRP_ADDR_N(7'h11)
    ) dut (
        .clk(clk), .rst_n(rst_n), 
        .lms_en(lms_en),
        .drp_d(i_drp_d),
        .drp_n(i_drp_n), 
        .out_s(out),
        .out_valid()
    );

    // adc sim
    adc_sim u_adc_d(.clk(clk), .adc_data(in), .drp(i_drp_d));
    adc_sim u_adc_n(.clk(clk), .adc_data(ref_s), .drp(i_drp_n));


    // Feed input signals
    initial begin
        lms_en = 0;
        in = '0;
        ref_s = '0;
        rst_n = 1'b0;
        #20;
        rst_n = 1'b1;

        //Feed input signals    
        repeat(CLK_C) @(posedge clk);
        for(int i = 0; i < num_samples; i++) begin
            in <= test_in.pop_front();
            ref_s <= test_ref.pop_front();
            repeat(CLK_C) @(posedge clk);
        end
        repeat(3 * CLK_C - 2) @(posedge clk);
        lms_en <= 1'b0;        
    end


    initial begin
        @(posedge rst_n);
        repeat(4 * CLK_C - 2) @(posedge clk);
        lms_en <= 1'b1;
        repeat(2) @(posedge clk);
        record_output();
        // repeat(2) @(posedge clk);
        compare_queues(test_out, dut_out, "Expected", "DUT");
    end

    // Collect filter output 
    task record_output();
        for (int i = 0; i <  num_samples; i++) begin
            dut_out.push_back(out);
            repeat(CLK_C) @(posedge clk);
        end
    endtask


    // Compare two queues
    task automatic compare_queues (
        input  logic signed [DATA_WIDTH-1:0] q1[],     // first queue
        input  logic signed [DATA_WIDTH-1:0] q2[],     // second queue
        input  string name1 = "q1",
        input  string name2 = "q2",
        input  int start_idx = 0
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
        for (int i = start_idx; i < (size1 < size2 ? size1 : size2); i++) begin
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


// ----------------------------------------------------------------------------
// Simulate ADC behavior 
// Use in Simulation only 
// ----------------------------------------------------------------------------
module adc_sim(
    input logic clk,
    input logic [11:0] adc_data,
    drp_if.slave drp 
);

    initial begin
        drp.rd_data = '0;
        drp.data_rdy = 1'b0;
        run();
    end 

    task run();
        forever begin
            @(posedge clk);
            if (drp.rd_en) begin
                repeat(1) @(posedge clk);
                drp.rd_data <= {4'b0, adc_data};
                drp.data_rdy <= 1'b1;
                @(posedge clk);
                drp.data_rdy <= 1'b0;
            end
        end
    endtask

endmodule

