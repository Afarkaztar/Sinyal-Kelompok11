function result = detect_bpm(t, ecg_filtered, fs, target_bpm)
% DETECT_BPM Mendeteksi puncak R (R-Peak), menghitung RR-interval, BPM, dan klasifikasi.
%
% Input:
%   t            - Vektor waktu (detik)
%   ecg_filtered - Sinyal ECG hasil filtering (mV)
%   fs           - Frekuensi sampling (Hz)
%   target_bpm   - BPM referensi/asli untuk perhitungan error (%)
%
% Output:
%   result       - Struct berisi lokasi R-Peak, RR-Interval, BPM, Error, & Status

    % 1. Penonjolan gelombang R (Positif Squaring) untuk menekan gelombang P & T
    ecg_pos = max(ecg_filtered, 0);
    ecg_sq  = ecg_pos .^ 2;

    % 2. Parameter Threshold Adaptif & Periode Refraktori Jantung
    %    - Threshold = 45% dari amplitudo maksimum sinyal terfilter
    %    - Jarak minimum antar puncak = 0.25 detik (250 ms periode refraktori)
    threshold_amp  = 0.45 * max(ecg_filtered);
    min_peak_dist  = round(0.25 * fs);

    % 3. Deteksi Puncak R menggunakan findpeaks
    [r_amps, r_indices] = findpeaks(ecg_filtered, ...
        'MinPeakHeight', threshold_amp, ...
        'MinPeakDistance', min_peak_dist);

    r_times = t(r_indices);

    % 4. Perhitungan RR-Interval & Denyut Jantung (BPM)
    if length(r_times) >= 2
        rr_intervals = diff(r_times);              % Selisih waktu antar puncak R (detik)
        inst_bpm     = 60 ./ rr_intervals;         % BPM sesaat pada tiap detak
        mean_rr      = mean(rr_intervals);         % Rata-rata RR-interval (detik)
        mean_bpm     = 60 / mean_rr;               % BPM rata-rata
    else
        rr_intervals = NaN;
        inst_bpm     = NaN;
        mean_rr      = NaN;
        mean_bpm     = 0;
    end

    % 5. Evaluasi Akurasi terhadap Ground Truth BPM
    bpm_error_pct = abs(mean_bpm - target_bpm) / target_bpm * 100;

    % 6. Klasifikasi Kondisi Klinis Denyut Jantung
    if mean_bpm < 60
        status_klinis = 'Bradikardia (< 60 BPM)';
    elseif mean_bpm <= 100
        status_klinis = 'Normal (60 - 100 BPM)';
    else
        status_klinis = 'Takikardia (> 100 BPM)';
    end

    % Kemas seluruh hasil ke dalam struct output
    result.ecg_sq        = ecg_sq;
    result.threshold_amp = threshold_amp;
    result.r_indices     = r_indices;
    result.r_times       = r_times;
    result.r_amps        = r_amps;
    result.num_beats     = length(r_indices);
    result.rr_intervals  = rr_intervals;
    result.inst_bpm      = inst_bpm;
    result.mean_rr       = mean_rr;
    result.mean_bpm      = mean_bpm;
    result.target_bpm    = target_bpm;
    result.bpm_error_pct = bpm_error_pct;
    result.status_klinis = status_klinis;
end
