function [beat_period, beat_pos] = compute_beats(sound, SAMPLE_RATE, SAMPLES_PER_UNIT, BPS_CUTOFF, SECONDS_OFFSET, BEAT_WINDOW_SECONDS)

MAX_PERIOD_CUTOFF = 5.0 % seconds


UM_OFFSET = SECONDS_OFFSET * SAMPLE_RATE / SAMPLES_PER_UNIT;

CORRELATION_SIZE = floor(BEAT_WINDOW_SECONDS * SAMPLE_RATE / SAMPLES_PER_UNIT);


sound_len = length(sound);
sound = sound .* sound;

% assume sound is 44khz sample rate

um = zeros([ 1  sound_len/SAMPLES_PER_UNIT]);
c = 0;

for mag_win=1:((sound_len/SAMPLES_PER_UNIT) - 1)
    um(mag_win) = sum(sound((mag_win * SAMPLES_PER_UNIT):(mag_win * SAMPLES_PER_UNIT + SAMPLES_PER_UNIT - 1)));
end    

c = xcorr(um((1 + UM_OFFSET):(CORRELATION_SIZE + UM_OFFSET)), um((1 + UM_OFFSET):(CORRELATION_SIZE + UM_OFFSET)));
c(CORRELATION_SIZE) = 0;

times = -(CORRELATION_SIZE - 1):(CORRELATION_SIZE - 1);


% now eliminate negative regions
c_pos = c(CORRELATION_SIZE:CORRELATION_SIZE * 2 - 1);

% now eliminate anything longer than 5 seconds
c_pos = c_pos(1: min(length(c_pos),MAX_PERIOD_CUTOFF * SAMPLE_RATE / SAMPLES_PER_UNIT));

% eliminate any beats greater than 10 bps
c_pos(1:SAMPLE_RATE / SAMPLES_PER_UNIT / BPS_CUTOFF) = zeros([ 1 SAMPLE_RATE / SAMPLES_PER_UNIT / BPS_CUTOFF]);


pos_time_labels = (1:length(c_pos)) .* (SAMPLES_PER_UNIT / SAMPLE_RATE);

%subplot(3,1,2)
%plot(pos_time_labels, c_pos)

c_pos_reverse = zeros( [ 1 length(c_pos) ] );
for i=1:length(c_pos)
    c_pos_reverse(i) = c_pos(length(c_pos) - i + 1);
end

%plot(freq_labels, c_pos_reverse)

[c_pos_max c_pos_max_index] = max(c_pos);
print 'BEAT PERIOD' 
beat_period = pos_time_labels(c_pos_max_index)
beats_per_minute = 1.00 / pos_time_labels(c_pos_max_index) * 60.00

UM_WINDOW_SIZE = floor(beat_period * SAMPLE_RATE / SAMPLES_PER_UNIT)
NUM_WINDOWS    = floor(length(um) / UM_WINDOW_SIZE)
MAX_WINDOWS    = 12
if (NUM_WINDOWS > MAX_WINDOWS)
    NUM_WINDOWS = MAX_WINDOWS
end

um_avg = zeros( [ 1 UM_WINDOW_SIZE ] );

for i=1:UM_WINDOW_SIZE
    for j=1:NUM_WINDOWS
        um_avg(i) = um_avg(i) + um((j - 1) * UM_WINDOW_SIZE + i);
    end
end

[ junk beat_pos] = max(um_avg)
beat_pos = beat_pos * SAMPLES_PER_UNIT / SAMPLE_RATE;

return