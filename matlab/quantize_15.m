function x_q15 = quantize_15(x)

    x = max(min(x, 1 - 2^-15), -1);
    % Convert to integer representation
    x_q15 = int16(x * 2^15);
end
