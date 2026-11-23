function [ecg_filtered, spec, snr_metrics] = filter_ecg(ecg_clean, ecg_noisy, fs)
% FILTER_ECG Merancang filter digital (BPF + Notch 50 Hz) dan analisis FFT.
%
% Input:
%   ecg_clean    - Sinyal ECG bersih referensi (mV)
%   ecg_noisy    - Sinyal ECG ber-noise (mV)
%   fs           - Frekuensi sampling (Hz)
%
% Output:
%   ecg_filtered - Sinyal ECG setelah proses filtering (mV)
%   spec         - Struct berisi vektor frekuensi & spektrum FFT
%   snr_metrics  - Struct berisi nilai SNR sebelum & sesudah filter (dB)

    fn = fs / 2; % Frekuensi Nyquist

    % 1. Tahap 1: Band-Pass Filter Butterworth (0.5 Hz - 40 Hz)
    %    - Cutoff bawah 0.5 Hz: Meredam baseline wander (0.3 Hz)
    %    - Cutoff atas  40 Hz : Meredam high-frequency noise & sebagian 50 Hz
    fc_low  = 0.5;
    fc_high = 40.0;
    order_bpf = 2; % Orde 2 (menjadi efektif orde 4 setelah filtfilt bolak-balik)
    [b_bpf, a_bpf] = butter(order_bpf, [fc_low, fc_high] / fn, 'bandpass');
    ecg_bpf = filtfilt(b_bpf, a_bpf, ecg_noisy);

    % 2. Tahap 2: Notch Filter / Band-Stop Butterworth (48.5 Hz - 51.5 Hz)
    %    - Memastikan interferensi listrik PLN 50 Hz teredam sempurna
    fc_notch = [48.5, 51.5];
    order_notch = 2;
    [b_notch, a_notch] = butter(order_notch, fc_notch / fn, 'stop');
    ecg_filtered = filtfilt(b_notch, a_notch, ecg_bpf);

    % 3. Analisis Spektrum Frekuensi (Single-Sided Amplitude Spectrum via FFT)
    N = length(ecg_noisy);
    f_axis = (0 : floor(N/2))' * (fs / N);

    fft_clean = abs(fft(ecg_clean) / N);
    fft_noisy = abs(fft(ecg_noisy) / N);
    fft_filt  = abs(fft(ecg_filtered) / N);

    % Ambil spektrum satu sisi (0 s/d fs/2)
    P_clean = fft_clean(1 : floor(N/2)+1);
    P_noisy = fft_noisy(1 : floor(N/2)+1);
    P_filt  = fft_filt(1 : floor(N/2)+1);

    P_clean(2:end-1) = 2 * P_clean(2:end-1);
    P_noisy(2:end-1) = 2 * P_noisy(2:end-1);
    P_filt(2:end-1)  = 2 * P_filt(2:end-1);

    spec.f       = f_axis;
    spec.P_clean = P_clean;
    spec.P_noisy = P_noisy;
    spec.P_filt  = P_filt;
    spec.b_bpf   = b_bpf;
    spec.a_bpf   = a_bpf;
    spec.b_notch = b_notch;
    spec.a_notch = a_notch;

    % 4. Perhitungan Signal-to-Noise Ratio (SNR) dalam dB
    power_signal     = sum(ecg_clean.^2);
    power_err_before = sum((ecg_noisy - ecg_clean).^2);
    power_err_after  = sum((ecg_filtered - ecg_clean).^2);

    snr_before = 10 * log10(power_signal / power_err_before);
    snr_after  = 10 * log10(power_signal / power_err_after);

    snr_metrics.snr_before      = snr_before;
    snr_metrics.snr_after       = snr_after;
    snr_metrics.snr_improvement = snr_after - snr_before;
end
