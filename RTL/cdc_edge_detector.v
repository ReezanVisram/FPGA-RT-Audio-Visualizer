module cdc_edge_detector(
  input fast_clk,
  input slow_data,
  output reg data_rise,
  output reg data_fall
);

  reg data1;
  reg data1_d;
  reg data1_dd;

  always @(posedge fast_clk)
  begin
    data1 <= slow_data;
    data1_d <= data1;
    data1_dd <= data1_d;

    if (data1_d && !data1_dd)
    begin
      data_rise <= 1'b1;
    end
    else
    begin
      data_rise <= 1'b0;
    end

    if (!data1_d && data1_dd)
    begin
      data_fall <= 1'b1;
    end
    else
    begin
      data_fall <= 1'b0;
    end
  end


endmodule