module axi_lite_watchdog(

    input ACLK,
    input ARESETN,

    // AXI-Lite Write Address
    input[31:0] AWADDR,
    input AWVALID,
    output reg AWREADY,

    // AXI-Lite Write Data
    input [31:0] WDATA,
    input  WVALID,
    output reg WREADY,

    // AXI-Lite Write Response
    output reg BVALID,
    input  BREADY,

    // AXI-Lite Read Address
    input [31:0] ARADDR,
    input ARVALID,
    output reg ARREADY,

    // AXI-Lite Read Data
    output reg [31:0] RDATA,
    output reg RVALID,
    input RREADY,

    // Outputs
    output reg timeout,
    output reg reset_out,
    output reg system_reset_out
);

// Registers

reg [31:0] control_reg;
reg [31:0] load_reg;
reg [31:0] counter_reg;
reg kick_req;

wire enable;

assign enable = control_reg[0];

// AXI WRITE


always @(posedge ACLK)
begin
  if(!ARESETN || system_reset_out)
    begin
        AWREADY <= 0;	//slave is not ready
        WREADY  <= 0;
        BVALID  <= 0;

        control_reg <= 0;	//disabled watchdog
        load_reg  <= 20;	//default
    end
    else
    begin
        AWREADY <= 1;
        WREADY <= 1;

        if(AWVALID && WVALID)
        begin

            case(AWADDR)

                32'h00:
                begin
                    control_reg <= WDATA;

                    // Enable edge
                  if(!control_reg[0] && WDATA[0]) 	//It prevents watchdog to load again and again in between
				begin
    				counter_reg <= load_reg;
    				timeout <= 0;
				end
                end

                32'h04:
                begin
                    load_reg <= WDATA;
                end

              32'h08:
				
				begin
  				  kick_req <= 1;
   				 timeout <= 0;
				end
              
            endcase

            BVALID <= 1;
        end

        if(BVALID && BREADY)
            BVALID <= 0;
    end
end

// AXI READ


always @(posedge ACLK)
begin
  if(!ARESETN || system_reset_out)
    begin
        ARREADY <= 0;
        RVALID <= 0;
        RDATA <= 0;
    end
    else
    begin
        ARREADY <= 1;

        if(ARVALID)
        begin

            case(ARADDR)

                32'h00: RDATA <= control_reg;
                32'h04: RDATA <= load_reg;
                32'h0C: RDATA <= {31'd0, timeout};

                default:
                    RDATA <= 32'hABCD;

            endcase

            RVALID <= 1;
        end

        if(RVALID && RREADY)
            RVALID <= 0;
    end
end

// WATCHDOG COUNTER


always @(posedge ACLK)
begin

    if(!ARESETN || system_reset_out)
    begin

        counter_reg <= 0;
        timeout <= 0;
        reset_out <= 0;
        system_reset_out <= 0;
        kick_req <= 0;

    end
    else
    begin

        // default pulse values
   

        reset_out <= 0;
        system_reset_out <= 0;

        // watchdog active


     if(kick_req)
  			begin

    		counter_reg <= load_reg;
    		kick_req <= 0;

			end
			else if(enable)
				begin

            if(counter_reg > 1)
            begin

                counter_reg <= counter_reg - 1;

            end
            else if(counter_reg == 1)
            begin

                counter_reg <= 0;

                timeout <= 1;
                reset_out <= 1;
                system_reset_out <= 1;

            end
                

        end

    end

end
  
endmodule
