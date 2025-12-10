function [e, w_hist, x, y, delta] = lms_filter_hardware_sim( ...
    d_q15, n_q15, N_TAPS, step_size_q15)
      
    N = length(d_q15);
    w = int16(zeros(N_TAPS,1));   % Filter weights initialization
    x = int16(zeros(N_TAPS+1,1));   % Reference signal buffer
    y = int16(zeros(N,1));   % FIR Filter output
    e = int16(zeros(N,1));   % Error signal
    
    acc = zeros(N_TAPS,1);  
    delta = zeros(N,1); 
    w_hist = zeros(N_TAPS,N);
    % x_hist = zeros(N_TAPS,N);
    % acc_hist = zeros(N_TAPS,N);
    
    e_new = 0;
    for k = 1:N
        e(k) = e_new;
        x_in = n_q15(k);
        d_in = d_q15(k);
    
        % Pipelined FIR Filter
        acc(1) = q15_mult(w(1), x_in);
        for i = 2:N_TAPS
            acc(i) = acc(i-1) + q15_mult(w(i), x(i-1));
        end
        y(k) = acc(N_TAPS);
    
        % LMS
        e_new = d_in - y(k);
        x_lms = x(1:end-1);
        delta(k) = q15_mult(step_size_q15, e(k));
        w = w + q15_mult(delta(k), x_lms);  
        x = [x_in; x(1:end-1)]; 

        % x_hist(:, k) = x_lms;
        w_hist(:, k) = w;
        % acc_hist(:, k) = acc;
        
    end
end