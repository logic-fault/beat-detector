% assume input data is 'song' combined L+R channel

SAMPLE_RATE = 44100;
SAMPLES_PER_UNIT = 0.01 * SAMPLE_RATE; % 10 ms
BPS_CUTOFF = 3;
BEAT_WINDOW_SECONDS = 12.0;
RESOLUTION  = 4;  % in seconds

song_beats_delta = zeros ( [ 1 length(song) ] );

seconds_in_song = floor(length(song) / SAMPLE_RATE);
BPM_ARRAY_LENGTH = floor(seconds_in_song / RESOLUTION);

bpm_array    = zeros( [ 1 BPM_ARRAY_LENGTH ] );
offset_array = zeros( [ 1 BPM_ARRAY_LENGTH ] );

for s=0:RESOLUTION:(BPM_ARRAY_LENGTH * RESOLUTION - ceil(BEAT_WINDOW_SECONDS))
 [bpm_array(s / RESOLUTION + 1) offset_array(s / RESOLUTION + 1)   ] = compute_beats(song, SAMPLE_RATE, SAMPLES_PER_UNIT, BPS_CUTOFF, s, BEAT_WINDOW_SECONDS);
end

subplot(4,1,1)
plot(0:RESOLUTION:(BPM_ARRAY_LENGTH * RESOLUTION - RESOLUTION), bpm_array, 0:RESOLUTION:(BPM_ARRAY_LENGTH * RESOLUTION - RESOLUTION), bpm_array ./ bpm_array .* mode(bpm_array), '-.', 0:RESOLUTION:(BPM_ARRAY_LENGTH * RESOLUTION - RESOLUTION), bpm_array ./ bpm_array .* median(bpm_array), '--');
legend(' Beat Period', 'Beat Period Median', 'Beat Period Mode')
xlabel('Position in seconds within music')
ylabel('Period')
grid off

subplot(4,1,2)
plot(0:RESOLUTION:(BPM_ARRAY_LENGTH * RESOLUTION - RESOLUTION), bpm_array ./ mode(bpm_array));
legend(' Beat Period', 'Beat Period Median', 'Beat Period Mode')
xlabel('Position in seconds within music')
ylabel('Period in multiples of period mode')
grid on

subplot(4,1,4)
hist(bpm_array, 100)
grid off

% next thing is to plot beats on song

for i=1:length(bpm_array)
    offset = offset_array(i);
    period    = bpm_array(i);    
    samples_concerned = floor(RESOLUTION  * SAMPLE_RATE);
    start_sample = (i - 1) * samples_concerned + 1;
    
    window_data = zeros ([ 1 samples_concerned ]);
    offset_frames = offset * SAMPLE_RATE;
    for j = offset_frames:(period * SAMPLE_RATE):samples_concerned
        song_beats_delta(start_sample + j) = 1;
    end
end

% change deltas to rectangles
song_beats_delta_conv = conv(song_beats_delta, ones(1, floor(SAMPLE_RATE * 0.1) ));

song_beats_sine = zeros ( [length(song) 1 ] );

% make SAMPLE_RATE sine wave with 12khz component at beat marks
for i=1:length(song_beats_delta)
   song_beats_sine(i) = song_beats_delta_conv(i) * sin(2 * 3.14159 * i / 441000 * 12000) ;
end

% new song with superimposed sine

new_song = song .* 0.25 + song_beats_sine;

subplot(4,1,3)
sample_marker = 1:length(song);
sample_marker = sample_marker ./ SAMPLE_RATE;
plot( sample_marker , song, sample_marker, song_beats_delta);
