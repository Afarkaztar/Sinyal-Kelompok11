function [t, ecg_clean, ecg_noisy, noise_info] = generate_ecg(fs, duration, target_bpm, snr_db)
% GENERATE_ECG Membangkitkan sinyal ECG sintetis (P-Q-R-S-T) beserta noise.
%
% Input:
%   fs         - Frekuensi sampling (Hz), contoh: 500
%   duration   - Durasi sinyal (detik), contoh: 10
%   target_bpm - Denyut jantung target / ground truth (BPM), contoh: 75
%   snr_db     - Signal-to-Noise Ratio untuk white noise (dB), contoh: 12
%
% Output:
%   t          - Vektor waktu (detik)
%   ecg_clean  - Sinyal ECG bersih (mV)
%   ecg_noisy  - Sinyal ECG yang terkontaminasi 3 jenis noise (mV)
%   noise_info - Struct berisi komponen noise untuk analisis/plot

    % 1. Vektor waktu dan periode detak jantung (RR-interval ideal)
    t = (0 : 1/fs : duration - 1/fs)';
    rr_interval = 60 / target_bpm; % Periode 1 siklus detak (detik)

    % 2. Parameter morfologi gelombang P-Q-R-S-T (Model Superposisi Gaussian)
    % Format: [P, Q, R, S, T]
    % Posisi relatif terhadap puncak R (dalam detik)
    ti = [-0.16, -0.035, 0.00,  0.035, 0.22];
    % Amplitudo masing-masing gelombang (mV)
    ai = [ 0.15, -0.15,  1.20, -0.25,  0.30];
    % Lebar pulsa / standar deviasi Gaussian (detik)
    bi = [ 0.025, 0.010, 0.012, 0.012, 0.040];

    % Penyesuaian lebar jarak gelombang untuk detak cepat (Takikardia)
    scale_factor = min(1.0, rr_interval / 0.8);
    ti = ti * scale_factor;
    bi = bi * scale_factor;

    % 3. Sintesis sinyal ECG bersih untuk seluruh durasi
    ecg_clean = zeros(size(t));
    % Mulai detak pertama pada t = 0.5 detik agar tidak terpotong di awal
    beat_times = 0.5 : rr_interval : (duration - 0.4);

    for k = 1:length(beat_times)
        t_beat = beat_times(k);
        for w = 1:length(ai)
            ecg_clean = ecg_clean + ai(w) * exp(-((t - (t_beat + ti(w))).^2) / (2 * bi(w)^2));
        end
    end

    % 4. Pembangkitan 3 Jenis Noise Biomedis Realistis
    rng(42); % Seed tetap agar hasil simulasi konsisten saat dipresentasikan

    % a) Baseline Wander (0.3 Hz) - akibat gerakan respirasi/pernapasan pasien
    bw_freq = 0.3;
    bw_amp  = 0.25;
    baseline_wander = bw_amp * sin(2 * pi * bw_freq * t);

    % b) Powerline Interference (50 Hz) - akibat induksi jala-jala listrik PLN
    pli_freq = 50.0;
    pli_amp  = 0.15;
    powerline_noise = pli_amp * sin(2 * pi * pli_freq * t);

    % c) White Gaussian Noise (EMG / derau sensor frekuensi tinggi)
    sig_power = mean(ecg_clean.^2);
    noise_power = sig_power / (10^(snr_db / 10));
    white_noise = sqrt(noise_power) * randn(size(t));

    % Gabungkan sinyal bersih dengan seluruh komponen gangguan
    total_noise = baseline_wander + powerline_noise + white_noise;
    ecg_noisy = ecg_clean + total_noise;

    % Simpan informasi komponen noise untuk evaluasi
    noise_info.beat_times      = beat_times;
    noise_info.baseline_wander = baseline_wander;
    noise_info.powerline_noise = powerline_noise;
    noise_info.white_noise     = white_noise;
    noise_info.total_noise     = total_noise;
end
