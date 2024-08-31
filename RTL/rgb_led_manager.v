module rgb_led_manager(
  input clk,
  input resetn,
  input [1:0] curr_channel,
  output reg led_r,
  output reg led_g,
  output reg led_b
);
  reg [7:0] pwm_counter;

  always @(posedge clk)
  begin
    pwm_counter <= pwm_counter + 1;
    if (!resetn)
    begin
      led_r <= 1'b0;
      led_g <= 1'b0;
      led_b <= 1'b0;
      pwm_counter <= {8{1'b0}};
    end
    else
    begin      
      if (pwm_counter < 8'd128)
      begin
        case (curr_channel)
          2'b00: 
          begin
            led_r <= 1'b1;
            led_g <= 1'b0;
            led_b <= 1'b0;
          end
          2'b01:
          begin
            led_r <= 1'b0;
            led_g <= 1'b1;
            led_b <= 1'b0;
          end
          2'b10:
          begin
            led_r <= 1'b0;
            led_g <= 1'b0;
            led_b <= 1'b1;
          end
          default: 
          begin
            led_r <= 1'b0; 
            led_g <= 1'b0; 
            led_b <= 1'b0;
          end
        endcase
      end
      else
      begin
        led_r <= 1'b0;
        led_g <= 1'b0;
        led_b <= 1'b0;
      end
    end
  end

endmodule