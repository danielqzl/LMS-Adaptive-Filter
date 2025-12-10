function y = q15_mult(a, b)
% Q15_MULT Simulate Q1.15 fixed-point multiplication (scalar or vector)
%   y = q15_mult(a, b)
%   Performs elementwise multiplication of signed 16-bit integers in Q1.15 format.
%   If inputs are out of range, they are clipped with a warning.
%
%   Inputs:
%       a, b - int16 scalars, vectors
%   Output:
%       y - int16 result (Q1.15 format)
%
%   Example:
%       y = q15_mult([10000, 20000], [20000, -32768]);

    % Define limits for Q1.15
    Q15_MAX = 32767;
    Q15_MIN = -32768;

    % Ensure inputs are int16 (if not, convert)
    if ~isa(a, 'int16')
        a = int16(a);
    end
    if ~isa(b, 'int16')
        b = int16(b);
    end

    % Ensure inputs are same size (or scalar-expand)
    if ~isscalar(a) && ~isscalar(b) && ~isequal(size(a), size(b))
        error('Inputs must be same size or one must be scalar.');
    end

    % Convert to int32 for safe multiplication
    a32 = int32(a);
    b32 = int32(b);

    % Clip inputs to Q1.15 range
    a_clipped = min(max(a32, Q15_MIN), Q15_MAX);
    b_clipped = min(max(b32, Q15_MIN), Q15_MAX);

    % Warn if clipping occurred
    if any(a32(:) ~= a_clipped(:))
        warning('Input "a" clipped to Q1.15 range.');
    end
    if any(b32(:) ~= b_clipped(:))
        warning('Input "b" clipped to Q1.15 range.');
    end

    % Perform elementwise multiplication (32-bit intermediate)
    prod = a_clipped .* b_clipped;

    % Right shift by 15 to return to Q1.15 format
    y32 = bitshift(prod, -15);

    % Saturate result to Q1.15 range
    y32 = min(max(y32, Q15_MIN), Q15_MAX);

    % Convert back to int16
    y = int16(y32);
end