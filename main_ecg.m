%% ========================================================================
%  PROJEK AKHIR: SINYAL DAN SISTEM KONTROL ELEKTRONIK (SEMESTER 3)
%  Topik : Ekstraksi Denyut Jantung (BPM) dari Sinyal ECG (Electrocardiogram)
%  File  : main_ecg.m (Skrip Utama Interaktif - Klik "Run" untuk menjalankan)
%  ========================================================================
clc; close all;

fprintf('====================================================================\n');
fprintf('   SISTEM EKSTRAKSI DENYUT JANTUNG (BPM) DARI SINYAL ECG\n');
fprintf('====================================================================\n');

%% 1. INPUT INTERAKTIF DARI PENGGUNA (NAMA & DETAK JANTUNG)
% Pengguna dapat mengetikkan Nama, BPM, dan Durasi di Command Window.
% Jika langsung menekan Enter, nilai default akan digunakan.
if ~batchStartupOptionUsed
    clear;
    nama_input = strtrim(input('Masukkan Nama Pasien / Penguji [Default: Pasien_Umum]: ', 's'));
    if isempty(nama_input)
        nama_pasien = 'Pasien_Umum';
    else
        nama_pasien = nama_input;
    end

    bpm_str = strtrim(input('Masukkan Detak Jantung / BPM (30 - 200) [Default: 75]: ', 's'));
    if isempty(bpm_str) || isnan(str2double(bpm_str))
        target_bpm = 75;
    else
        target_bpm = max(30, min(200, str2double(bpm_str)));
    end

    dur_str = strtrim(input('Masukkan Durasi Rekaman (detik) [Default: 10]: ', 's'));
    if isempty(dur_str) || isnan(str2double(dur_str))
        duration = 10;
    else
        duration = max(5, min(60, str2double(dur_str)));
    end
else
    % Fallback jika dijalankan melalui mode non-interaktif (-batch)
    if ~exist('nama_pasien', 'var') || isempty(nama_pasien), nama_pasien = 'Pasien_Umum'; end
    if ~exist('target_bpm', 'var')  || isempty(target_bpm),  target_bpm  = 75; end
    if ~exist('duration', 'var')    || isempty(duration),    duration    = 10; end
end

% Parameter teknis sinyal
fs        = 500;   % Frekuensi sampling (Hz) - memenuhi kriteria Nyquist
snr_input = 10;    % Tingkat derau AWGN (dB)

% Buat folder khusus di dalam results/ sesuai nama yang diinputkan
% (Spasi atau karakter khusus diubah menjadi underscore agar nama folder aman)
folder_user = regexprep(nama_pasien, '[^a-zA-Z0-9_-]', '_');
output_dir  = fullfile('results', folder_user);
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

fprintf('\n--------------------------------------------------------------------\n');
fprintf('Nama Pasien / Penguji   : %s\n', nama_pasien);
fprintf('Folder Penyimpanan      : %s\n', output_dir);
fprintf('Frekuensi Sampling (fs) : %d Hz\n', fs);
fprintf('Durasi Simulasi         : %g detik\n', duration);
fprintf('Input BPM (Referensi)   : %g BPM\n', target_bpm);
fprintf('--------------------------------------------------------------------\n\n');

%% 2. PEMBANGKITAN SINYAL ECG & NOISE
[t, ecg_clean, ecg_noisy, noise_info] = generate_ecg(fs, duration, target_bpm, snr_input);

%% 3. FILTERING DIGITAL (BPF 0.5-40 Hz + NOTCH 50 Hz) & ANALISIS FFT
[ecg_filtered, spec, snr_metrics] = filter_ecg(ecg_clean, ecg_noisy, fs);

%% 4. DETEKSI R-PEAK & PERHITUNGAN DENYUT JANTUNG (BPM)
res = detect_bpm(t, ecg_filtered, fs, target_bpm);

% Tampilkan ringkasan hasil utama di Command Window
fprintf('--- HASIL EVALUASI FILTERING (%s) ---\n', nama_pasien);
fprintf('SNR Sebelum Filtering   : %6.2f dB\n', snr_metrics.snr_before);
fprintf('SNR Setelah Filtering   : %6.2f dB\n', snr_metrics.snr_after);
fprintf('Peningkatan SNR         : +%5.2f dB\n\n', snr_metrics.snr_improvement);

fprintf('--- HASIL EKSTRAKSI DENYUT JANTUNG (%s) ---\n', nama_pasien);
fprintf('Jumlah R-Peak Terdeteksi: %d detak (dalam %g detik)\n', res.num_beats, duration);
fprintf('Rata-rata RR-Interval   : %.4f detik\n', res.mean_rr);
fprintf('BPM Input (Asli)        : %.2f BPM\n', res.target_bpm);
fprintf('BPM Terdeteksi          : %.2f BPM\n', res.mean_bpm);
fprintf('Persentase Error BPM    : %.4f %%\n', res.bpm_error_pct);
fprintf('Klasifikasi Klinis      : %s\n\n', res.status_klinis);

%% 5. VISUALISASI GRAFIK (TERSIMPAN KE results/<Nama_Input>/)
t_zoom = min(5, duration); % Tampilkan 5 detik pertama agar bentuk P-Q-R-S-T jelas

% -------------------------------------------------------------------------
% FIGURE 1: Perbandingan Sinyal Domain Waktu (Bersih vs Noisy vs Filtered)
% -------------------------------------------------------------------------
fig1 = figure('Name', sprintf('Domain Waktu - %s', nama_pasien), ...
              'Color', 'w', 'Position', [100, 80, 950, 650]);
try theme(fig1, 'light'); catch, end

subplot(3,1,1);
plot(t, ecg_clean, 'Color', [0.00 0.45 0.74], 'LineWidth', 1.3);
grid on; xlim([0 t_zoom]); ylim([-0.6 1.5]);
title(sprintf('1. Sinyal ECG Bersih | Pasien: %s (%g BPM)', nama_pasien, target_bpm), 'FontWeight', 'bold');
ylabel('Amplitudo (mV)');

subplot(3,1,2);
plot(t, ecg_noisy, 'Color', [0.85 0.33 0.10], 'LineWidth', 1.0);
grid on; xlim([0 t_zoom]); ylim([-1.0 1.8]);
title(sprintf('2. Sinyal ECG + Noise (Baseline 0.3 Hz + PLN 50 Hz + AWGN | SNR = %.2f dB)', ...
      snr_metrics.snr_before), 'FontWeight', 'bold');
ylabel('Amplitudo (mV)');

subplot(3,1,3);
plot(t, ecg_filtered, 'Color', [0.13 0.55 0.13], 'LineWidth', 1.3);
grid on; xlim([0 t_zoom]); ylim([-0.6 1.5]);
title(sprintf('3. Sinyal ECG Hasil Filtering (BPF 0.5-40 Hz + Notch 50 Hz | SNR = %.2f dB)', ...
      snr_metrics.snr_after), 'FontWeight', 'bold');
xlabel('Waktu (detik)');
ylabel('Amplitudo (mV)');

exportgraphics(fig1, fullfile(output_dir, 'fig1_domain_waktu.png'), 'Resolution', 200);

% -------------------------------------------------------------------------
% FIGURE 2: Analisis Spektrum Frekuensi (FFT Sebelum vs Sesudah Filter)
% -------------------------------------------------------------------------
fig2 = figure('Name', sprintf('Spektrum FFT - %s', nama_pasien), ...
              'Color', 'w', 'Position', [150, 100, 950, 550]);
try theme(fig2, 'light'); catch, end

subplot(2,1,1);
plot(spec.f, spec.P_noisy, 'Color', [0.85 0.33 0.10], 'LineWidth', 1.2);
hold on;
xline(0.3, '--k', 'Baseline (0.3 Hz)', 'LabelVerticalAlignment', 'top', 'LineWidth', 1.1);
xline(50,  '--r', 'Listrik PLN (50 Hz)', 'LabelVerticalAlignment', 'top', 'LineWidth', 1.1);
hold off;
grid on; xlim([0 80]);
title(sprintf('Spektrum Frekuensi (FFT) Sebelum Filtering | Pasien: %s', nama_pasien), 'FontWeight', 'bold');
ylabel('Magnitudo |P(f)|');

subplot(2,1,2);
plot(spec.f, spec.P_filt, 'Color', [0.13 0.55 0.13], 'LineWidth', 1.2);
hold on;
xline(0.5, ':b', 'Cutoff Bawah (0.5 Hz)', 'LineWidth', 1.1);
xline(40,  ':b', 'Cutoff Atas (40 Hz)', 'LineWidth', 1.1);
xline(50,  '--k', '50 Hz Teredam', 'LineWidth', 1.1);
hold off;
grid on; xlim([0 80]);
title('Spektrum Frekuensi (FFT) Setelah Filtering (BPF + Notch)', 'FontWeight', 'bold');
xlabel('Frekuensi (Hz)');
ylabel('Magnitudo |P(f)|');

exportgraphics(fig2, fullfile(output_dir, 'fig2_spektrum_fft.png'), 'Resolution', 200);

% -------------------------------------------------------------------------
% FIGURE 3: Deteksi Puncak R (R-Peak) & Ekstraksi BPM
% -------------------------------------------------------------------------
fig3 = figure('Name', sprintf('Deteksi R-Peak & BPM - %s', nama_pasien), ...
              'Color', 'w', 'Position', [200, 120, 950, 580]);
try theme(fig3, 'light'); catch, end

subplot(2,1,1);
plot(t, ecg_filtered, 'Color', [0.00 0.45 0.74], 'LineWidth', 1.2); hold on;
plot(res.r_times, res.r_amps, 'rv', 'MarkerFaceColor', 'r', 'MarkerSize', 8);
yline(res.threshold_amp, '--k', sprintf('Threshold Adaptif (%.2f mV)', res.threshold_amp), ...
      'LabelHorizontalAlignment', 'left', 'LineWidth', 1.1);

% Anotasi visual RR-Interval pada pasangan detak ke-2 dan ke-3
if length(res.r_times) >= 3
    t1 = res.r_times(2); t2 = res.r_times(3);
    y_arrow = max(res.r_amps) * 0.82;
    plot([t1 t2], [y_arrow y_arrow], 'k-', 'LineWidth', 1.5);
    text((t1+t2)/2, y_arrow + 0.12, sprintf('RR = %.2f s', t2-t1), ...
         'HorizontalAlignment', 'center', 'FontWeight', 'bold', ...
         'Color', 'k', 'BackgroundColor', [1 1 0.85], 'EdgeColor', 'k');
end
hold off;
grid on; xlim([0 duration]); ylim([-0.6 1.5]);
title(sprintf('Deteksi R-Peak [%s] | Terdeteksi: %.2f BPM (%s)', ...
      nama_pasien, res.mean_bpm, res.status_klinis), 'FontWeight', 'bold');
xlabel('Waktu (detik)');
ylabel('Amplitudo (mV)');
legend('ECG Terfilter', 'Puncak R (R-Peak)', 'Threshold', 'Location', 'northeast');

subplot(2,1,2);
beat_numbers = 1:length(res.inst_bpm);
plot(beat_numbers, res.inst_bpm, '-o', 'Color', [0.13 0.55 0.13], ...
     'MarkerFaceColor', [0.13 0.55 0.13], 'LineWidth', 1.5); hold on;
yline(res.mean_bpm, '--b', sprintf('Rata-rata Terdeteksi: %.2f BPM', res.mean_bpm), ...
      'LabelHorizontalAlignment', 'left', 'LabelVerticalAlignment', 'top', 'LineWidth', 1.2);
yline(target_bpm, ':r', sprintf('Input Referensi: %.2f BPM', target_bpm), ...
      'LabelHorizontalAlignment', 'right', 'LabelVerticalAlignment', 'bottom', 'LineWidth', 1.2);
hold off;
grid on;
xlim([0.5, max(2, length(res.inst_bpm) + 0.5)]);
ylim([target_bpm - 10, target_bpm + 10]);
title(sprintf('Denyut Jantung Sesaat (Instantaneous BPM) - %s', nama_pasien), 'FontWeight', 'bold');
xlabel('Indeks Interval RR ke-n');
ylabel('Denyut Jantung (BPM)');
legend('BPM Sesaat', 'Rata-rata BPM', 'Input BPM', 'Location', 'northeast');

exportgraphics(fig3, fullfile(output_dir, 'fig3_deteksi_rpeak_bpm.png'), 'Resolution', 200);

%% 6. PERBANDINGAN INPUT PENGGUNA VS SKENARIO KLINIS (BRADIKARDIA, NORMAL, TAKIKARDIA)
scenarios_name = {sprintf('Input (%s)', nama_pasien), 'Bradikardia', 'Normal', 'Takikardia'};
scenarios_bpm  = [target_bpm, 50, 75, 120];
colors_scen    = {[0.49 0.18 0.56], [0.00 0.45 0.74], [0.13 0.55 0.13], [0.85 0.33 0.10]};

fig4 = figure('Name', sprintf('Perbandingan Skenario Klinis - %s', nama_pasien), ...
              'Color', 'w', 'Position', [250, 50, 950, 780]);
try theme(fig4, 'light'); catch, end

fprintf('========================================================================================\n');
fprintf('            TABEL EVALUASI INPUT (%s) & SKENARIO KLINIS DENYUT JANTUNG\n', upper(nama_pasien));
fprintf('========================================================================================\n');
fprintf('%-18s | %-10s | %-12s | %-9s | %-10s | %-10s\n', ...
        'Skenario', 'BPM Asli', 'BPM Deteksi', 'Error (%)', 'SNR Awal', 'SNR Filter');
fprintf('----------------------------------------------------------------------------------------\n');

for i = 1:length(scenarios_bpm)
    bpm_ref = scenarios_bpm(i);
    [t_s, clean_s, noisy_s, ~] = generate_ecg(fs, duration, bpm_ref, snr_input);
    [filt_s, ~, snr_s]         = filter_ecg(clean_s, noisy_s, fs);
    res_s                      = detect_bpm(t_s, filt_s, fs, bpm_ref);

    fprintf('%-18s | %6.2f BPM | %8.2f BPM | %7.4f %% | %7.2f dB | %7.2f dB\n', ...
            scenarios_name{i}, bpm_ref, res_s.mean_bpm, res_s.bpm_error_pct, ...
            snr_s.snr_before, snr_s.snr_after);

    subplot(4, 1, i);
    plot(t_s, filt_s, 'Color', colors_scen{i}, 'LineWidth', 1.2); hold on;
    plot(res_s.r_times, res_s.r_amps, 'rv', 'MarkerFaceColor', 'r', 'MarkerSize', 6);
    yline(res_s.threshold_amp, '--k');
    hold off;
    grid on; xlim([0 duration]); ylim([-0.6 1.5]);
    title(sprintf('%s | Target: %g BPM -> Terdeteksi: %.2f BPM (Error: %.3f%%, Detak: %d)', ...
          scenarios_name{i}, bpm_ref, res_s.mean_bpm, res_s.bpm_error_pct, res_s.num_beats), ...
          'FontWeight', 'bold');
    ylabel('mV');
    if i == 4
        xlabel('Waktu (detik)');
    end
end
fprintf('========================================================================================\n');

exportgraphics(fig4, fullfile(output_dir, 'fig4_uji_skenario_klinis.png'), 'Resolution', 200);

%% 7. SIMPAN RINGKASAN HASIL KE FILE TEKS DI FOLDER PENGGUNA
laporan_txt = fullfile(output_dir, 'ringkasan_hasil.txt');
fid = fopen(laporan_txt, 'w');
if fid ~= -1
    fprintf(fid, '============================================================\n');
    fprintf(fid, '   LAPORAN HASIL EKSTRAKSI DENYUT JANTUNG (SINYAL ECG)\n');
    fprintf(fid, '============================================================\n');
    fprintf(fid, 'Nama Pasien / Penguji   : %s\n', nama_pasien);
    fprintf(fid, 'Waktu Pengujian         : %s\n', char(datetime('now')));
    fprintf(fid, 'Frekuensi Sampling (fs) : %d Hz\n', fs);
    fprintf(fid, 'Durasi Rekaman          : %g detik\n\n', duration);
    fprintf(fid, '--- HASIL FILTERING ---\n');
    fprintf(fid, 'SNR Sebelum Filtering   : %.2f dB\n', snr_metrics.snr_before);
    fprintf(fid, 'SNR Setelah Filtering   : %.2f dB\n', snr_metrics.snr_after);
    fprintf(fid, 'Peningkatan SNR         : +%.2f dB\n\n', snr_metrics.snr_improvement);
    fprintf(fid, '--- HASIL DETEKSI DENYUT JANTUNG ---\n');
    fprintf(fid, 'BPM Input Referensi     : %.2f BPM\n', res.target_bpm);
    fprintf(fid, 'BPM Terdeteksi          : %.2f BPM\n', res.mean_bpm);
    fprintf(fid, 'Rata-rata RR-Interval   : %.4f detik\n', res.mean_rr);
    fprintf(fid, 'Jumlah R-Peak Terdeteksi: %d detak\n', res.num_beats);
    fprintf(fid, 'Persentase Error BPM    : %.4f %%\n', res.bpm_error_pct);
    fprintf(fid, 'Klasifikasi Klinis      : %s\n', res.status_klinis);
    fprintf(fid, '============================================================\n');
    fclose(fid);
end

fprintf('Seluruh grafik & laporan teks untuk [%s] tersimpan di:\n-> %s\n', ...
        nama_pasien, fullfile(pwd, output_dir));
