
function [63:0] reverse_64b;
  input [63:0]   data;
  integer        i;
    begin
        for (i = 0; i < 64; i = i + 1) begin
            reverse_64b[i] = data[63 - i];
        end
    end
endfunction


function [31:0] reverse_32b;
  input [31:0]   data;
  integer        i;
    begin
        for (i = 0; i < 32; i = i + 1) begin
            reverse_32b[i] = data[31 - i];
        end
    end
endfunction


function [7:0] reverse_8b;
  input [7:0]   data;
  integer        i;
    begin
        for (i = 0; i < 8; i = i + 1) begin
            reverse_8b[i] = data[7 - i];
        end
    end
endfunction


