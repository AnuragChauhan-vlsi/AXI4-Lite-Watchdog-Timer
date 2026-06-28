`timescale 1ns/1ps

module tb;

    reg         ACLK;
    reg         ARESETN;

    // Write Address Channel
    reg  [31:0] AWADDR;
    reg         AWVALID;
    wire        AWREADY;

    // Write Data Channel
    reg  [31:0] WDATA;
    reg         WVALID;
    wire        WREADY;

    // Write Response Channel
    wire        BVALID;
    reg         BREADY;

    // Read Address Channel
    reg  [31:0] ARADDR;
    reg         ARVALID;
    wire        ARREADY;

    // Read Data Channel
    wire [31:0] RDATA;
    wire        RVALID;
    reg         RREADY;

    wire        timeout;
    wire        reset_out;
    wire system_reset_out;

    axi_lite_watchdog dut (
        .ACLK      (ACLK),
        .ARESETN   (ARESETN),

        .AWADDR    (AWADDR),
        .AWVALID   (AWVALID),
        .AWREADY   (AWREADY),

        .WDATA     (WDATA),
        .WVALID    (WVALID),
        .WREADY    (WREADY),

        .BVALID    (BVALID),
        .BREADY    (BREADY),

        .ARADDR    (ARADDR),
        .ARVALID   (ARVALID),
        .ARREADY   (ARREADY),

        .RDATA     (RDATA),
        .RVALID    (RVALID),
        .RREADY    (RREADY),

        .timeout   (timeout),
      .reset_out (reset_out),
      .system_reset_out(system_reset_out)
    );

    initial
    begin
        ACLK = 0;
        forever #5 ACLK = ~ACLK;
    end


    task axi_write;
        input [31:0] addr;
        input [31:0] data;
        begin

            @(posedge ACLK);

            AWADDR  <= addr;
            AWVALID <= 1;

            WDATA   <= data;
            WVALID  <= 1;

            BREADY  <= 1;

            @(posedge ACLK);

            AWVALID <= 0;
            WVALID  <= 0;

            wait(BVALID);

            @(posedge ACLK);

            BREADY <= 0;

            $display("[%0t] WRITE Addr=%h Data=%0d",
                      $time, addr, data);

        end
    endtask


    task axi_read;
        input [31:0] addr;
        begin

            @(posedge ACLK);

            ARADDR  <= addr;
            ARVALID <= 1;
            RREADY  <= 1;

            @(posedge ACLK);

            ARVALID <= 0;

            wait(RVALID);

            $display("[%0t] READ Addr=%h Data=%0d",
                      $time, addr, RDATA);

            @(posedge ACLK);

            RREADY <= 0;

        end
    endtask

    initial
    begin

        AWADDR  = 0;
        AWVALID = 0;
        WDATA   = 0;
        WVALID  = 0;
        BREADY  = 0;

        ARADDR  = 0;
        ARVALID = 0;
        RREADY  = 0;

        ARESETN = 0;

        repeat(5) @(posedge ACLK);

        ARESETN = 1;

        $display("\n=== TEST 1 : TIMEOUT ===");
      //LOAD 10

        axi_write(32'h04, 10);

        // ENABLE = 1
  

        axi_write(32'h00, 1);

     
        // Wait for timeout
  

        wait(timeout);

        $display("[%0t] TIMEOUT OCCURRED",
                 $time);

        axi_read(32'h0C);

        // TEST 2
  

        $display("\n=== TEST 2 : PERIODIC KICK ===");

        axi_write(32'h04, 20);

        axi_write(32'h00, 1);

        repeat(5)
        begin

            repeat(10)
                @(posedge ACLK);

            axi_write(32'h08, 1);

            $display("[%0t] WATCHDOG KICKED",
                     $time);

        end

        if(timeout)
            $display("FAILED");
        else
            $display("PASSED");

        #100;

        $finish;

    end
  
   always @(posedge system_reset_out)
		begin
    		$display("[%0t] SYSTEM RESET GENERATED", $time);
		end

endmodule
