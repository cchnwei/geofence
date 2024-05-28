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
  localparam COMPARE = 1;
  localparam FIND    = 2; // find the vertex closest to the object
  localparam CHECK   = 3;
  localparam OUTPUT  = 4;
  //

  // define reg or wire
  reg [2:0] cs;
  reg [2:0] ns;
  reg [3:0] cnt;
  reg [1:0] cnt2;
  reg [9:0] object_x;
  reg [9:0] object_y;
  reg [9:0] max_x;
  reg [9:0] min_x;
  reg [9:0] max_y;
  reg [9:0] min_y;
  reg [9:0] y_of_max_x;
  reg [9:0] y_of_min_x;
  reg [9:0] x_of_max_y;
  reg [9:0] x_of_min_y;
  reg [9:0] x1;
  reg [9:0] y1;
  reg [9:0] x2;
  reg [9:0] y2;
  // reg [9:0] temp1;
  // reg [9:0] temp2;
  reg is_inside_reg;
  reg valid_reg;
  wire cs_is_READ;
  wire cs_is_COMPARE;
  wire READ_done;
  wire COMPARE_done;
  wire CHECK_done;
  wire is_outside;
  wire area_A;
  wire area_B;
  wire area_C;
  wire area_D;
  wire cnt_is_8;
  wire cnt_is_3;
  wire cnt_is_0;
  wire cnt2_is_2;
  wire [10:0] x1_plus_x2;
  wire [10:0] x1_plus_x2_div2;
  wire [10:0] y1_plus_y2;
  wire [10:0] y1_plus_y2_div2;
  wire object_x_lt_x1;
  // wire [9:0] distance; 
  //

  // logic
  assign cs_is_READ = (cs==READ);
  assign cs_is_COMPARE = (cs==COMPARE);
  assign is_outside = (object_x<min_x||object_y<min_y||object_x>max_x||object_y>max_y); 
  assign READ_done = cnt_is_8;
  assign COMPARE_done = (cnt_is_8||cnt2_is_2);
  assign CHECK_done = (x1_plus_x2_div2-object_x<=63||cnt_is_3);
  // assign CHECK_done = (distance<=52||cnt_is_3);
  // assign distance = temp1-temp2;
  assign valid = valid_reg; 
  assign is_inside = is_inside_reg; 
  assign area_A = (object_x<=x_of_max_y && object_y> y_of_min_x);
  assign area_B = (object_x>=x_of_max_y && object_y> y_of_max_x);
  assign area_C = (object_x<=x_of_min_y && object_y<=y_of_min_x);
  assign area_D = (object_x>=x_of_min_y && object_y<=y_of_max_x && !area_A);
  assign cnt_is_8 = (cnt==8);
  assign cnt_is_3 = (cnt==3);
  assign cnt_is_0 = (cnt==0);
  assign cnt2_is_2 = (cnt2==2);
  assign x1_plus_x2 = x1+x2;
  assign x1_plus_x2_div2 = x1_plus_x2>>1;  
  assign y1_plus_y2 = y1+y2;
  assign y1_plus_y2_div2 = y1_plus_y2>>1;
  assign object_x_lt_x1 = (object_x<x1); 
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
          if (READ_done)          ns=COMPARE;          
          else                    ns=READ;   // loopback
        end          
      COMPARE:         
        begin     
          if (is_outside)         ns=OUTPUT;
          else if (COMPARE_done)  ns=FIND;
          else                    ns=COMPARE;  // loopback
        end        
      FIND:        
        begin    
                                  ns=CHECK;
        end
      CHECK:
        begin
          if (CHECK_done)         ns=OUTPUT;
          else                    ns=CHECK;  // loopback
        end         
      OUTPUT:        
        begin        
                                  ns=READ;
        end
    endcase
  end
  //

  // instantiate RAM
  wire [19:0] data_in={X,Y};
  wire [3:0]  addr=cnt;
  wire        w_en=cs_is_READ;
  wire        r_en=cs_is_COMPARE;
  wire [19:0] data_out;

  RAM mem (
  .clk(clk),
  .data_in(data_in),
  .addr(addr),
  .w_en(w_en),
  .r_en(r_en),
  .data_out(data_out)
  );
  //

  // coordinate of object
  always @(posedge clk) begin
    if (cs_is_READ && cnt_is_0) begin
      object_x <= X;
      object_y <= Y;
    end
  end
  //

  // find (x1,y1):left, (x2,y2):right
  wire vertex_is_in_areaA=(data_out[19:10]<x_of_max_y && data_out[9:0]>y_of_min_x && area_A);
  wire vertex_is_in_areaB=(data_out[19:10]>x_of_max_y && data_out[9:0]>y_of_max_x && area_B);
  wire vertex_is_in_areaC=(data_out[19:10]<x_of_min_y && data_out[9:0]<y_of_min_x && area_C);
  wire vertex_is_in_areaD=(data_out[19:10]>x_of_min_y && data_out[9:0]<y_of_max_x && area_D);

  always @(posedge clk) begin
    case (cs)
      READ: 
        begin
          x1 <= 0;
          y1 <= 0;
          x2 <= 0;
          y2 <= 0;
          cnt2 <= 0;
        end
      COMPARE:
        begin
          case (cnt)
            1:
              begin
                x1 <= 0;
                y1 <= 0;
              end
            8:
              begin
                if (x1>x2 && x2!=0) begin
                  x1 <= x2;
                  y1 <= y2;
                  x2 <= x1;
                  y2 <= y1;
                end
              end
            default: 
              begin
                if (vertex_is_in_areaA||vertex_is_in_areaB||vertex_is_in_areaC||vertex_is_in_areaD) begin
                  x1 <= data_out[19:10];
                  y1 <= data_out[9:0];
                  cnt2 <= cnt2+1;
                end
                  x2 <= (COMPARE_done) ? x2 : x1;
                  y2 <= (COMPARE_done) ? y2 : y1;
              end
          endcase
        end
      FIND:
        begin
          case ({area_A,area_B,area_C,area_D})
            4'b1000, 4'b1001: // A
              begin
                case (cnt2)
                  0:
                    begin
                        x1 <= min_x;
                        y1 <= y_of_min_x;
                        x2 <= x_of_max_y;
                        y2 <= max_y;
                    end
                  1:
                    begin
                      if (object_x_lt_x1) begin
                        x1 <= min_x;
                        y1 <= y_of_min_x;
                        x2 <= x1;
                        y2 <= y1;
                      end
                      else begin  // object_x_gt_x1
                        // x1 <= x1;
                        // y1 <= y1;
                        x2 <= x_of_max_y;
                        y2 <= max_y;
                      end
                    end
                  2:
                    begin
                      if (object_x_lt_x1) begin
                        x1 <= min_x;
                        y1 <= y_of_min_x;
                        x2 <= x1;
                        y2 <= y1;
                      end
                      else begin // object_x_gt_x2
                        x1 <= x2;
                        y1 <= y2;
                        x2 <= x_of_max_y;
                        y2 <= max_y;
                      end
                    end
                endcase
              end
            4'b0100: // B
              begin
                case (cnt2)
                  0:
                    begin
                        x1 <= x_of_max_y;
                        y1 <= max_y;
                        x2 <= max_x;
                        y2 <= y_of_max_x;
                    end
                  1:
                    begin
                      if (object_x_lt_x1) begin
                        x1 <= x_of_max_y;
                        y1 <= max_y;
                        x2 <= x1;
                        y2 <= y1;
                      end
                      else begin  // object_x_gt_x1
                        // x1 <= x1;
                        // y1 <= y1;
                        x2 <= max_x;
                        y2 <= y_of_max_x;
                      end
                    end
                  2:
                    begin
                      if (object_x_lt_x1) begin
                        x1 <= x_of_max_y;
                        y1 <= max_y;
                        x2 <= x1;
                        y2 <= y1;
                      end
                      else begin // object_x_gt_x2
                        x1 <= x2;
                        y1 <= y2;
                        x2 <= max_x;
                        y2 <= y_of_max_x;
                      end
                    end
                endcase
              end
            4'b0010: // C
              begin
                case (cnt2)
                  0:
                    begin
                        x1 <= min_x;
                        y1 <= y_of_min_x;
                        x2 <= x_of_min_y;
                        y2 <= min_y;
                    end
                  1:
                    begin
                      if (object_x_lt_x1) begin
                        x1 <= min_x;
                        y1 <= y_of_min_x;
                        x2 <= x1;
                        y2 <= y1;
                      end
                      else begin  // object_x_gt_x1
                        // x1 <= x1;
                        // y1 <= y1;
                        x2 <= x_of_min_y;
                        y2 <= min_y;
                      end
                    end
                  2:
                    begin
                      if (object_x_lt_x1) begin
                        x1 <= min_x;
                        y1 <= y_of_min_x;
                        x2 <= x1;
                        y2 <= y1;
                      end
                      else begin // object_x_gt_x2
                        x1 <= x2;
                        y1 <= y2;
                        x2 <= x_of_min_y;
                        y2 <= min_y;
                      end
                    end
                endcase
              end
            4'b0001: // D
              begin
                case (cnt2)
                  0:
                    begin
                        x1 <= x_of_min_y;
                        y1 <= min_y;
                        x2 <= max_x;
                        y2 <= y_of_max_x;
                    end
                  1:
                    begin
                      if (object_x_lt_x1) begin
                        x1 <= x_of_min_y;
                        y1 <= min_y;
                        x2 <= x1;
                        y2 <= y1;
                      end
                      else begin  // object_x_gt_x1
                        // x1 <= x1;
                        // y1 <= y1;
                        x2 <= max_x;
                        y2 <= y_of_max_x;
                      end
                    end
                  2:
                    begin
                      if (object_x_lt_x1) begin
                        x1 <= x_of_min_y;
                        y1 <= min_y;
                        x2 <= x1;
                        y2 <= y1;
                      end
                      else begin // object_x_gt_x2
                        x1 <= x2;
                        y1 <= y2;
                        x2 <= max_x;
                        y2 <= y_of_max_x;
                      end
                    end
                endcase
              end
          endcase
        end
      CHECK:
        begin
          if (x1_plus_x2_div2<object_x) begin
            x1 <= x1_plus_x2_div2;
            y1 <= y1_plus_y2_div2;
          end
          else begin
            x2 <= x1_plus_x2_div2;
            y2 <= y1_plus_y2_div2;
          end
        end
    endcase
  end
  //

  // // temp1, temp2
  // always @(*) begin
  //   if (x1_plus_x2_div2>object_x) begin
  //     temp1=x1_plus_x2_div2;
  //     temp2=object_x;
  //   end
  //   else begin
  //     temp1=object_x;
  //     temp2=x1_plus_x2_div2;
  //   end
  // end
  // //

  // counter
  wire [3:0] next_cnt;
  assign next_cnt = cnt+1;

  always @(posedge clk, posedge reset) begin
    if (reset) begin
      cnt <= 0;
    end
    else begin
      case (cs)
        READ:    cnt <= (READ_done)    ? 1 : next_cnt;
        COMPARE: cnt <= (COMPARE_done) ? 0 : next_cnt;
        FIND:    cnt <= 0;
        CHECK:   cnt <= next_cnt;
        OUTPUT:  cnt <= 0; 
      endcase
    end
  end
  //

  // find the coordinate of max_x, max_y, min_x, min_y
  always @(posedge clk) begin
    case (cnt)
      0:
        begin
          if (cs_is_READ) begin
            max_x <= 0;
            min_x <= 1023;
            max_y <= 0;
            min_y <= 1023;
            y_of_max_x <= 0;
            y_of_min_x <= 0;
            x_of_max_y <= 0;
            x_of_min_y <= 0;
          end
        end
      default:
        begin
          if (X>=max_x) begin
            max_x      <= X;
            y_of_max_x <= Y;
          end
          if (X<=min_x) begin
            min_x      <= X;
            y_of_min_x <= Y;
          end
          if (Y>=max_y) begin
            max_y      <= Y;
            x_of_max_y <= X;
          end
          if (Y<=min_y) begin
            min_y      <= Y;
            x_of_min_y <= X;
          end
        end
    endcase
  end 
  //

  // valid
  always @(posedge clk) begin
    case (cs)
      CHECK:   valid_reg <= CHECK_done;
      COMPARE: valid_reg <= is_outside;
      default: valid_reg <= 0;
    endcase
  end 
  //

  // is_inside
  always @(posedge clk) begin
    case (cs)
      CHECK:   
        begin
          if (area_A||area_B) is_inside_reg <= (object_y<y1_plus_y2_div2);
          else                is_inside_reg <= (object_y>y1_plus_y2_div2); // area_C,area_D
        end
      default:                is_inside_reg <= 0;
    endcase
  end 
  //

endmodule

module RAM (
  // input port
  input        clk,
  input [19:0] data_in,
  input [3:0]  addr,
  input        w_en,
  input        r_en,
  // output port
  output reg [19:0] data_out
);

  // define reg, wire
  reg [19:0] mem [0:8];
  //

  // write
  always @(posedge clk) begin
    if (w_en) mem[addr] <= data_in;
  end
  //

  // read
  always @(posedge clk) begin
    if (r_en) data_out <= mem[addr];
  end
  //
  
endmodule