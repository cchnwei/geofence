`timescale 1ns/10ps
module geofence (clk,reset,X,Y,valid,is_inside);
input			clk;
input			reset;
input	[9:0]	X;
input	[9:0]	Y;
output			valid;
output			is_inside;

  // state
  localparam READ    = 0;
  localparam SORT    = 1;
  localparam DIVIDE  = 2;
  localparam CHECK   = 3;
  localparam INSIDE  = 4;
  localparam OUTSIDE = 5;
  //

  // define reg or wire
  reg  [9:0] coord_x [0:7];
  reg  [9:0] coord_y [0:7];
  reg  [2:0] cs;
  reg  [2:0] ns;
  reg  [3:0] cnt;
  wire [9:0] object_x;
  wire [9:0] object_y;
  reg  [9:0] max_x;
  reg  [9:0] max_y;
  reg  [9:0] min_x;
  reg  [9:0] min_y;
  reg  outside;
  reg  is_inside_reg;
  reg  valid_reg;
  reg  check;
  wire cs_is_READ;
  wire READ_done;
  wire SORT_done;
  wire ns_is_OUTSIDE;
  wire jump_to_OUTSIDE;
  wire x1_gt_or_et_x2;
  wire x3_gt_or_et_x4;
  wire x5_gt_or_et_x6;
  wire x1_gt_or_et_x4;
  wire x2_gt_or_et_x3;
  wire x6_gt_or_et_x7;
  wire x2_gt_or_et_x7;
  wire x3_gt_or_et_x6;
  wire x4_gt_or_et_x5;
  wire cnt_is_7;
  wire cnt_is_6;
  wire cnt_is_4;
  wire cnt_is_15;
  integer i;
  //

  // logic
  assign cs_is_READ = (cs==READ);
  assign ns_is_OUTSIDE = (ns==OUTSIDE);
  assign ns_is_INSIDE = (ns==INSIDE);
  assign jump_to_OUTSIDE = (object_x<min_x||object_y<min_y||object_x>max_x||object_y>max_y); 
  assign READ_done = cnt_is_7;
  assign SORT_done = cnt_is_6;
  assign DIVIDE_done = cnt_is_4;
  assign CHECK_done = (cnt_is_15 && !check);
  assign valid = valid_reg; 
  assign is_inside = is_inside_reg; 
  assign object_x = coord_x[0];
  assign object_y = coord_y[0];
  assign x1_gt_or_et_x2 = (coord_x[1]>=coord_x[2]);
  assign x3_gt_or_et_x4 = (coord_x[3]>=coord_x[4]);
  assign x5_gt_or_et_x6 = (coord_x[5]>=coord_x[6]);
  assign x1_gt_or_et_x4 = (coord_x[1]>=coord_x[4]);
  assign x2_gt_or_et_x3 = (coord_x[2]>=coord_x[3]);
  assign x6_gt_or_et_x7 = (coord_x[6]>=coord_x[7]);
  assign x2_gt_or_et_x7 = (coord_x[2]>=coord_x[7]);
  assign x3_gt_or_et_x6 = (coord_x[3]>=coord_x[6]);
  assign x4_gt_or_et_x5 = (coord_x[4]>=coord_x[5]);
  assign cnt_is_7 = (cnt==7);
  assign cnt_is_6 = (cnt==6);
  assign cnt_is_4 = (cnt==4);
  assign cnt_is_15 = (cnt==15);
  //

  // state transition
  always @(posedge clk, posedge reset) begin
    if (reset) cs <= READ;
    else       cs <= ns;
  end

  always @(*) begin
    ns=3'bx;
    case (cs)
      READ:
        begin
          if (READ_done)        ns=SORT;
          else                  ns=READ;   // loopback
        end          
      SORT:          
        begin     
          if (jump_to_OUTSIDE)  ns=OUTSIDE;
          else if (SORT_done)   ns=DIVIDE;
          else                  ns=SORT;   // loopback
        end        
      DIVIDE:        
        begin    
          if (DIVIDE_done)      ns=CHECK;
          else                  ns=DIVIDE; // loopback
        end
      CHECK:
        begin
          if (outside)          ns=OUTSIDE;
          else if (CHECK_done)  ns=INSIDE;
          else                  ns=CHECK;  // loopback
        end         
      INSIDE:        
        begin        
                                ns=READ;
        end
      OUTSIDE:        
        begin        
                                ns=READ;
        end
    endcase
  end
  //

  // read and sort coord_x, coord_y
  always @(posedge clk) begin
    case (cs)
      READ:
        begin
          coord_x[7] <= X;
          coord_y[7] <= Y;
          for (i=0;i<7;i=i+1) begin
            coord_x[i] <= coord_x[i+1];
            coord_y[i] <= coord_y[i+1];
          end
        end
      SORT:
        begin
          case (cnt)
            0:
              begin
                if (x1_gt_or_et_x2) begin
                  coord_x[1] <= coord_x[2];
                  coord_y[1] <= coord_y[2];
                  coord_x[2] <= coord_x[1];
                  coord_y[2] <= coord_y[1];
                end
                if (x3_gt_or_et_x4) begin
                  coord_x[3] <= coord_x[4];
                  coord_y[3] <= coord_y[4];
                  coord_x[4] <= coord_x[3];
                  coord_y[4] <= coord_y[3];
                end 
                if (x5_gt_or_et_x6) begin
                  coord_x[5] <= coord_x[6];
                  coord_y[5] <= coord_y[6];
                  coord_x[6] <= coord_x[5];
                  coord_y[6] <= coord_y[5];
                end
                // if (coord_x[7]>=max_x) begin
                //   coord_x[7] <= max_x;
                //   max_x <= coord_x[7];
                // end
              end
            1:
              begin
                if (x1_gt_or_et_x4) begin
                  coord_x[1] <= coord_x[4];
                  coord_y[1] <= coord_y[4];
                  coord_x[4] <= coord_x[1];
                  coord_y[4] <= coord_y[1];
                end
                if (x2_gt_or_et_x3) begin
                  coord_x[2] <= coord_x[3];
                  coord_y[2] <= coord_y[3];
                  coord_x[3] <= coord_x[2];
                  coord_y[3] <= coord_y[2];
                end
                // if (coord_x[5]>=max_x) begin
                //   coord_x[5] <= max_x;
                //   max_x <= coord_x[5];
                // end
                if (x6_gt_or_et_x7) begin
                  coord_x[6] <= coord_x[7];
                  coord_y[6] <= coord_y[7];
                  coord_x[7] <= coord_x[6];
                  coord_y[7] <= coord_y[6];
                end
              end
            2: 
              begin
                if (x1_gt_or_et_x2) begin
                  coord_x[1] <= coord_x[2];
                  coord_y[1] <= coord_y[2];
                  coord_x[2] <= coord_x[1];
                  coord_y[2] <= coord_y[1];
                end
                if (x3_gt_or_et_x4) begin
                  coord_x[3] <= coord_x[4];
                  coord_y[3] <= coord_y[4];
                  coord_x[4] <= coord_x[3];
                  coord_y[4] <= coord_y[3];
                end 
                if (x5_gt_or_et_x6) begin
                  coord_x[5] <= coord_x[6];
                  coord_y[5] <= coord_y[6];
                  coord_x[6] <= coord_x[5];
                  coord_y[6] <= coord_y[5];
                end
                // if (coord_x[7]>=max_x) begin
                //   coord_x[7] <= max_x;
                //   max_x <= coord_x[7];
                // end
              end
            3:
              begin
                // if (coord_x[1]>=max_x) begin
                //   coord_x[1] <= max_x;
                //   max_x <= coord_x[1];
                // end
                if (x2_gt_or_et_x7) begin
                  coord_x[2] <= coord_x[7];
                  coord_y[2] <= coord_y[7];
                  coord_x[7] <= coord_x[2];
                  coord_y[7] <= coord_y[2];
                end 
                if (x3_gt_or_et_x6) begin
                  coord_x[3] <= coord_x[6];
                  coord_y[3] <= coord_y[6];
                  coord_x[6] <= coord_x[3];
                  coord_y[6] <= coord_y[3];
                end
                if (x4_gt_or_et_x5) begin
                  coord_x[4] <= coord_x[5];
                  coord_y[4] <= coord_y[5];
                  coord_x[5] <= coord_x[4];
                  coord_y[5] <= coord_y[4];
                end
              end
            4:
              begin
                if (x1_gt_or_et_x2) begin
                  coord_x[1] <= coord_x[2];
                  coord_y[1] <= coord_y[2];
                  coord_x[2] <= coord_x[1];
                  coord_y[2] <= coord_y[1];
                end
                if (x3_gt_or_et_x4) begin
                  coord_x[3] <= coord_x[4];
                  coord_y[3] <= coord_y[4];
                  coord_x[4] <= coord_x[3];
                  coord_y[4] <= coord_y[3];
                end 
                if (x5_gt_or_et_x6) begin
                  coord_x[5] <= coord_x[6];
                  coord_y[5] <= coord_y[6];
                  coord_x[6] <= coord_x[5];
                  coord_y[6] <= coord_y[5];
                end
                // if (coord_x[7]>=max_x) begin
                //   coord_x[7] <= max_x;
                //   max_x <= coord_x[7];
                // end
              end
            5:
              begin
                if (x1_gt_or_et_x4) begin
                  coord_x[1] <= coord_x[4];
                  coord_y[1] <= coord_y[4];
                  coord_x[4] <= coord_x[1];
                  coord_y[4] <= coord_y[1];
                end
                if (x2_gt_or_et_x3) begin
                  coord_x[2] <= coord_x[3];
                  coord_y[2] <= coord_y[3];
                  coord_x[3] <= coord_x[2];
                  coord_y[3] <= coord_y[2];
                end
                // if (coord_x[5]>=max_x) begin
                //   coord_x[5] <= max_x;
                //   max_x <= coord_x[5];
                // end
                if (x6_gt_or_et_x7) begin
                  coord_x[6] <= coord_x[7];
                  coord_y[6] <= coord_y[7];
                  coord_x[7] <= coord_x[6];
                  coord_y[7] <= coord_y[6];
                end
              end
            6:
              begin
                if (x1_gt_or_et_x2) begin
                  coord_x[1] <= coord_x[2];
                  coord_y[1] <= coord_y[2];
                  coord_x[2] <= coord_x[1];
                  coord_y[2] <= coord_y[1];
                end
                if (x3_gt_or_et_x4) begin
                  coord_x[3] <= coord_x[4];
                  coord_y[3] <= coord_y[4];
                  coord_x[4] <= coord_x[3];
                  coord_y[4] <= coord_y[3];
                end 
                if (x5_gt_or_et_x6) begin
                  coord_x[5] <= coord_x[6];
                  coord_y[5] <= coord_y[6];
                  coord_x[6] <= coord_x[5];
                  coord_y[6] <= coord_y[5];
                end
                // if (coord_x[7]>=max_x) begin
                //   coord_x[7] <= max_x;
                //   max_x <= coord_x[7];
                // end
              end          
          endcase
        end
      DIVIDE:
        begin
          case (cnt)
            0:
              begin
                if (coord_y[6]>=coord_y[1]) begin
                  coord_x[7] <= coord_x[6];
                  coord_y[7] <= coord_y[6];
                  coord_x[6] <= coord_x[7];
                  coord_y[6] <= coord_y[7];
                end
              end
            1:
              begin
                if (coord_y[5]>=coord_y[1]) begin
                  coord_x[7] <= coord_x[5];
                  coord_y[7] <= coord_y[5];
                  for (i=5;i<7;i=i+1) begin
                    coord_x[i] <= coord_x[i+1];
                    coord_y[i] <= coord_y[i+1];
                  end
                end
              end
            2:
              begin
                if (coord_y[4]>=coord_y[1]) begin
                  coord_x[7] <= coord_x[4];
                  coord_y[7] <= coord_y[4];
                  for (i=4;i<7;i=i+1) begin
                    coord_x[i] <= coord_x[i+1];
                    coord_y[i] <= coord_y[i+1];
                  end
                end
              end
            3:
              begin
                if (coord_y[3]>=coord_y[1]) begin
                  coord_x[7] <= coord_x[3];
                  coord_y[7] <= coord_y[3];
                  for (i=3;i<7;i=i+1) begin
                    coord_x[i] <= coord_x[i+1];
                    coord_y[i] <= coord_y[i+1];
                  end
                end
              end  
            4:
              begin
                if (coord_y[2]>=coord_y[1]) begin
                  coord_x[7] <= coord_x[2];
                  coord_y[7] <= coord_y[2];
                  for (i=2;i<7;i=i+1) begin
                    coord_x[i] <= coord_x[i+1];
                    coord_y[i] <= coord_y[i+1];
                  end
                end
              end  
          endcase
        end
    endcase
  end
  //

  // counter
  wire [3:0] next_cnt;
  assign next_cnt = cnt+1;

  always @(posedge clk, posedge reset) begin
    if (reset) begin
      cnt <= 0;
    end
    else begin
      case (cs)
        READ:    cnt <= (cnt_is_7) ? 0 : next_cnt;
        SORT:    cnt <= (cnt_is_6) ? 0 : next_cnt;
        DIVIDE:  cnt <= (cnt_is_4) ? 0 : next_cnt;
        CHECK:   cnt <= next_cnt;
        INSIDE:  cnt <= 0; 
        OUTSIDE: cnt <= 0; 
      endcase
    end
  end
  //

  //
  reg  [10:0] var1; 
  reg  [10:0] var2; 
  reg  [10:0] var3; 
  reg  [10:0] var4; 
  reg  [10:0] var5; 
  reg  [10:0] var6; 
  reg  [10:0] var7; 
  reg  [10:0] var8; 
  wire [10:0] var1_minus_var2 = $signed(var1)-$signed(var2);
  wire [10:0] var3_minus_var4 = $signed(var3)-$signed(var4);
  wire [10:0] var5_minus_var6 = $signed(var5)-$signed(var6);
  wire [10:0] var7_minus_var8 = $signed(var7)-$signed(var8);

  always @(*) begin
    var1=0;
    var2=0;
    var3=0;
    var4=0;
    var5=0;
    var6=0;
    var7=0;
    var8=0;
    case (cnt)
      0,1:
        begin
          var1={1'b0,coord_x[1]};
          var2={1'b0,object_x};
          var3={1'b0,coord_y[2]};
          var4={1'b0,coord_y[1]};
          var5={1'b0,coord_y[1]};
          var6={1'b0,object_y};
          var7={1'b0,coord_x[2]};
          var8={1'b0,coord_x[1]};
        end
      2,3:
        begin
          var1={1'b0,coord_x[2]};
          var2={1'b0,object_x};
          var3={1'b0,coord_y[3]};
          var4={1'b0,coord_y[2]};
          var5={1'b0,coord_y[2]};
          var6={1'b0,object_y};
          var7={1'b0,coord_x[3]};
          var8={1'b0,coord_x[2]};
        end
      4,5:
        begin
          var1={1'b0,coord_x[3]};
          var2={1'b0,object_x};
          var3={1'b0,coord_y[4]};
          var4={1'b0,coord_y[3]};
          var5={1'b0,coord_y[3]};
          var6={1'b0,object_y};
          var7={1'b0,coord_x[4]};
          var8={1'b0,coord_x[3]};
        end
      6,7:
        begin
          var1={1'b0,coord_x[4]};
          var2={1'b0,object_x};
          var3={1'b0,coord_y[5]};
          var4={1'b0,coord_y[4]};
          var5={1'b0,coord_y[4]};
          var6={1'b0,object_y};
          var7={1'b0,coord_x[5]};
          var8={1'b0,coord_x[4]};
        end
      8,9:
        begin
          var1={1'b0,coord_x[5]};
          var2={1'b0,object_x};
          var3={1'b0,coord_y[6]};
          var4={1'b0,coord_y[5]};
          var5={1'b0,coord_y[5]};
          var6={1'b0,object_y};
          var7={1'b0,coord_x[6]};
          var8={1'b0,coord_x[5]};
        end
      10,11:
        begin
          var1={1'b0,coord_x[6]};
          var2={1'b0,object_x};
          var3={1'b0,coord_y[7]};
          var4={1'b0,coord_y[6]};
          var5={1'b0,coord_y[6]};
          var6={1'b0,object_y};
          var7={1'b0,coord_x[7]};
          var8={1'b0,coord_x[6]};
        end
      12,13:
        begin
          var1={1'b0,coord_x[7]};
          var2={1'b0,object_x};
          var3={1'b0,coord_y[1]};
          var4={1'b0,coord_y[7]};
          var5={1'b0,coord_y[7]};
          var6={1'b0,object_y};
          var7={1'b0,coord_x[1]};
          var8={1'b0,coord_x[7]};
        end
    endcase
  end
  //

  //
  reg  [10:0] c0;
  reg  [10:0] c1;
  reg  [10:0] c2;
  reg  [10:0] c3;

  always @(posedge clk) begin
    c0 <= var1_minus_var2;
    c1 <= var3_minus_var4;
    c2 <= var5_minus_var6;
    c3 <= var7_minus_var8;
  end
  //

  // instantiate mul
  reg  [10:0] mul_in1;
  reg  [10:0] mul_in2;
  wire [21:0] mul_o;

  mul mul0 (
    .in1(mul_in1),
    .in2(mul_in2),
    .out(mul_o)
  );

  always @(*) begin
    mul_in1=0;
    mul_in2=0;
    case (cnt)
      1,3,5,7,9,11,13:  
        begin
          mul_in1=c0; mul_in2=c1;
        end
      2,4,6,8,10,12,14: 
        begin
          mul_in1=c2; mul_in2=c3;
        end
    endcase
  end
  //

  // mul_reg
  reg [21:0] mul_reg;

  always @(posedge clk, posedge reset) begin
    if (reset) begin
      mul_reg <= 0;
    end
    else begin
      mul_reg <= mul_o;
    end
  end
  //

  // check
  always @(posedge clk, posedge reset) begin
    if (reset) begin
      check <= 0;
    end
    else begin
      case (cnt)
        2,4,6,8,10,12,14:
          begin
            check <= ($signed(mul_reg)<$signed(mul_o)) ? 1 : 0;
          end
      endcase
    end
  end
  //

  // find the max_x, max_y, min_x, min_y
  always @(posedge clk) begin
    case (cnt)
      0:
        begin
          if (cs_is_READ) begin
            max_x <= 0;
            min_x <= 1023;
            max_y <= 0;
            min_y <= 1023;
          end
        end
      default:
        begin
            max_x <= (X>=max_x) ? X : max_x;
            min_x <= (X<=min_x) ? X : min_x;
            max_y <= (Y>=max_y) ? Y : max_y;
            min_y <= (Y<=min_y) ? Y : min_y;
        end
    endcase
  end 
  //

  // valid
  always @(posedge clk) begin
    valid_reg <= (ns_is_OUTSIDE||ns_is_INSIDE);
  end 
  //

  // is_inside
  always @(posedge clk) begin
    is_inside_reg <= (ns_is_INSIDE);
  end 
  //


  // outside
  always @(posedge clk) begin
    case (cs)
      READ:
        begin
          outside <= 0;
        end
      CHECK:
        begin
          case (cnt)
            3,5,7,9,11,13,15: outside <= check;
            default:          outside <= 0;
          endcase
        end
    endcase
  end
  //

endmodule

module mul (
  // input port
  input  [10:0] in1, // 11-bit, signed integer
  input  [10:0] in2, // 11-bit, signed integer
  // output port
  output reg [21:0] out // 22-bit
);

  // define reg or wire
  reg  [21:0] add0;
  reg  [19:0] add1;
  reg  [17:0] add2;
  reg  [15:0] add3;
  reg  [13:0] add4;
  reg  [11:0] add5;
  // reg  [9:0]  add6;
  wire [11:0]  in1_shf;
  //

  // logic
  assign in1_shf = in1<<1;
  //

  // booth encoding
  always @(*) begin
    add0=0;
    case ({in2[1:0],1'b0})
      3'b000, 3'b111 : add0 =  0; 
      3'b001, 3'b010 : add0 = $signed( in1     ); 
      3'b101, 3'b110 : add0 = $signed(-in1     ); 
      3'b011         : add0 = $signed( in1_shf ); 
      3'b100         : add0 = $signed(-in1_shf ); 
    endcase
  end

  always @(*) begin
    add1=0;
    case (in2[3:1])
      3'b000, 3'b111 : add1 =  0; 
      3'b001, 3'b010 : add1 = $signed( in1     ); 
      3'b101, 3'b110 : add1 = $signed(-in1     ); 
      3'b011         : add1 = $signed( in1_shf ); 
      3'b100         : add1 = $signed(-in1_shf ); 
    endcase
  end

  always @(*) begin
    add2=0;
    case (in2[5:3])
      3'b000, 3'b111 : add2 =  0; 
      3'b001, 3'b010 : add2 = $signed( in1     ); 
      3'b101, 3'b110 : add2 = $signed(-in1     ); 
      3'b011         : add2 = $signed( in1_shf ); 
      3'b100         : add2 = $signed(-in1_shf ); 
    endcase
  end

  always @(*) begin
    add3=0;
    case (in2[7:5])
      3'b000, 3'b111 : add3 =  0; 
      3'b001, 3'b010 : add3 = $signed( in1     ); 
      3'b101, 3'b110 : add3 = $signed(-in1     ); 
      3'b011         : add3 = $signed( in1_shf ); 
      3'b100         : add3 = $signed(-in1_shf ); 
    endcase
  end

  always @(*) begin
    add4=0;
    case (in2[9:7])
      3'b000, 3'b111 : add4 =  0; 
      3'b001, 3'b010 : add4 = $signed( in1     ); 
      3'b101, 3'b110 : add4 = $signed(-in1     ); 
      3'b011         : add4 = $signed( in1_shf ); 
      3'b100         : add4 = $signed(-in1_shf ); 
    endcase
  end

  always @(*) begin
    add5=0;
    case ({in2[10],in2[10:9]})
      3'b000, 3'b111 : add5 =  0; 
      3'b001, 3'b010 : add5 = $signed( in1     ); 
      3'b101, 3'b110 : add5 = $signed(-in1     ); 
      3'b011         : add5 = $signed( in1_shf ); 
      3'b100         : add5 = $signed(-in1_shf ); 
    endcase
  end

  // wallace tree
  wire [21:0] sum0;
  wire [21:0] carry0;
  wire [21:0] carry0_shf;
  assign carry0_shf = carry0<<1;

  adder22 adder22_0 (
    .a(add0),
    .b({add1,2'b0}),
    .cin({add2,4'b0}),
    .sum(sum0),
    .cout(carry0)
  );
  //

  //
  wire [21:0] sum1;
  wire [21:0] carry1;
  wire [21:0] carry1_shf;
  assign carry1_shf = carry1<<1;

  adder22 adder22_1 (
    .a({add3,6'b0}),
    .b({add4,8'b0}),
    .cin({add5,10'b0}),
    .sum(sum1),
    .cout(carry1)
  );
  //

  //
  wire [21:0] sum2;
  wire [21:0] carry2;
  wire [21:0] carry2_shf;
  assign carry2_shf = carry2<<1;

  adder22 adder22_2 (
    .a(sum0),
    .b(carry0_shf),
    .cin(sum1),
    .sum(sum2),
    .cout(carry2)
  );
  //

  //
  wire [21:0] sum3;
  wire [21:0] carry3;
  wire [21:0] carry3_shf;
  assign carry3_shf = carry3<<1;

  adder22 adder22_3 (
    .a(carry1_shf),
    .b(carry2_shf),
    .cin(sum2),
    .sum(sum3),
    .cout(carry3)
  );
  //

  // out = sum3 + carry3_shf
  reg [11:0] out_temp0; // msb is carry-bit
  reg [10:0] out_temp1;
  reg [10:0] out_temp2;

  always @(*) begin
    out = sum3 + carry3_shf;
  end
  // always @(*) begin
  //   out_temp0 = sum3[10:0]+carry3_shf[10:0]; 
  // end

  // always @(*) begin
  //   out_temp1 = sum3[21:11]+carry3_shf[21:11]+1; // carry is 1
  //   out_temp2 = sum3[21:11]+carry3_shf[21:11];   // carry is 0
  // end

  // always @(*) begin
  //   if (out_temp0[11]) begin // carry is 1
  //     out = {out_temp1, out_temp0[10:0]};
  //   end else begin           // carry is 0
  //     out = {out_temp2, out_temp0[10:0]};
  //   end
  // end
  //
  
endmodule

module adder22 (
  input [21:0] a,
  input [21:0] b,
  input [21:0] cin,
  output [21:0] sum,
  output [21:0] cout
);

  genvar i;

  generate
    for (i=0;i<22;i=i+1) begin:FA
      FA fa (.a(a[i]), .b(b[i]), .cin(cin[i]), .sum(sum[i]), .cout(cout[i]));
    end
  endgenerate
  
endmodule

module FA (
  input a, 
  input b,
  input cin,
  output sum, 
  output cout 
);

  wire c1, c2, s1;

  HA ha1(.a(a), .b(b), .cout(c1), .sum(s1));
  HA ha2(.a(s1), .b(cin), .cout(c2), .sum(sum));
  or (cout, c1, c2);
endmodule

module HA (
  input a, 
  input b,
  output sum, 
  output cout 
);

  xor (sum, a, b);
  and (cout, a, b);
endmodule