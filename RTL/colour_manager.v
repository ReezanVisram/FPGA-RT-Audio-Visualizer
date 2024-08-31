// This module will take in the input from UART and use it to determine the colour of the waveform and background
// curr_colour: 00 = red, 01 = green, 10 = blue, 11 = not editing colour. These will be used to set the colour of the Test LED
module colour_manager(
  input clk,
  input resetn,
  input [7:0] uart_data,
  input uart_data_valid,
  output reg [1:0] curr_channel,
  output reg [11:0] waveform_colour,  // [11:8] blue, [7:4] green, [3:0] red
  output reg [11:0] background_colour // [11:8] blue, [7:4] green, [3:0] red
);

  parameter [1:0] WaitForChannel = 2'b00, 
                  WaitForIntensity = 2'b01, 
                  WaitForComponent = 2'b11,
                  Done = 2'b10;

  reg [3:0] intensity_q;

  reg [5:0] state = WaitForChannel;

  reg valid_channel = 1'b0;
  reg valid_intensity = 1'b0;
  reg valid_component = 1'b0;

  always @(posedge clk)
  begin
    if (!resetn)
      state <= WaitForChannel;
    else
    begin
      case (state)
        WaitForChannel:
        begin
          if (valid_channel)
            state <= WaitForIntensity;
          else
            state <= WaitForChannel;
        end
        WaitForIntensity:
        begin
          if (valid_intensity)
            state <= WaitForComponent;
          else
            state <= WaitForIntensity;
        end
        WaitForComponent:
        begin
          if (valid_component)
            state <= Done;
          else
            state <= WaitForComponent;
        end
        default: // Done
        begin
          state <= WaitForChannel;
        end
      endcase
    end
  end

  always @(posedge clk)
  begin
    if (!resetn)
    begin
      curr_channel <= 2'b11;
      // Defaults are yellow waveform on black background
      waveform_colour <= 12'b000011111111;
      background_colour <= 12'b000000000000;
      valid_channel <= 1'b0;
      valid_intensity <= 1'b0;
    end
    else
    begin
      case (state)
        WaitForChannel:
        begin
          if (!valid_channel && uart_data_valid)
          begin
            if (uart_data == 8'h72 || uart_data == 8'h52) // r or R
            begin
              curr_channel <= 2'b00;
              valid_channel <= 1'b1;
            end 
            else if (uart_data == 8'h67 || uart_data == 8'h47) // g or G
            begin
              curr_channel <= 2'b01;
              valid_channel <= 1'b1;
            end
            else if (uart_data == 8'h62 || uart_data == 8'h42) // b or B
            begin
              curr_channel <= 2'b10;
              valid_channel <= 1'b1;
            end
            else
            begin
              curr_channel <= 2'b11;
              valid_channel <= 1'b0;
            end
          end
        end
        WaitForIntensity:
        begin
          if (!valid_intensity && uart_data_valid)
          begin
            if (uart_data >= 8'h30 && uart_data <= 8'h39) // Number between 0 and 9
            begin
              intensity_q <= uart_data - 8'h30;
              valid_intensity <= 1'b1;
            end
            else if (uart_data >= 8'h41 && uart_data <= 8'h46) // Hex digit between A and F
            begin
              intensity_q <= uart_data - 8'h37;
              valid_intensity <= 1'b1;
            end
            else if (uart_data >= 8'h61 && uart_data <= 8'h66) // Hex digit between a and f
            begin
              intensity_q <= uart_data - 8'h57;
              valid_intensity <= 1'b1;
            end
            else
            begin
              valid_intensity <= 1'b0;
            end
          end
        end
        WaitForComponent:
        begin
          if (!valid_component && uart_data_valid)
          begin
            if (uart_data == 8'h42 || uart_data == 8'h62) // B or b
            begin
              valid_component <= 1'b1;
              case (curr_channel)
              2'b00:
              begin
                background_colour[3:0] <= intensity_q;
              end
              2'b01:
              begin
                background_colour[7:4] <= intensity_q;
              end
              2'b10:
              begin
                background_colour[11:8] <= intensity_q;
              end
              default:
              begin
                background_colour <= background_colour;
              end
              endcase
            end
            else if (uart_data == 8'h57 || uart_data == 8'h77) // W or w
            begin
              valid_component <= 1'b1;
              case (curr_channel)
                2'b00:
                begin
                  waveform_colour[3:0] <= intensity_q;
                end
                2'b01:
                begin
                  waveform_colour[7:4] <= intensity_q;
                end
                2'b10:
                begin
                  waveform_colour[11:8] <= intensity_q;
                end
                default:
                  waveform_colour <= waveform_colour;
              endcase
            end
            else
              valid_component <= 1'b0;
          end
        end
        default: // Done
        begin
          valid_channel <= 1'b0;
          valid_intensity <= 1'b0;
          valid_component <= 1'b0;
          curr_channel <= 3'b11;
        end
      endcase
    end
  end

endmodule