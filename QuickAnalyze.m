function QuickAnalyze(stimKey, filename_plx)
%% Quick display of VEP data, from AnalyzeVEP_Laura04

% Flags for what analyses and plots to do
showRawDataFlag = true;      % Plot the raw VEP data series and its FFT in separate figure window
plotTimeStampsFlag = false;    % Plot the events and time stamps in a separate figure window

nCheckBdPerTrial = 10;    % Number of checkerboard reversals (including initial onset) per trial
dispTimeSec = 0.5;        % Display time of each checkerboard in sec

filterDataFlag = false;        % Remove 60Hz and 180Hz by calling Remove60Hz(). It turns out not to do that much.
Fs = 1000;                    % Sampling frequency (is this in the Plexon file?)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load the data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% stimKey = Stimulus key file. Assumes format of Alex Yuan's csv data file from June 2014.
% In that format, columns are:
%    iTrial	          Trial number, starting with 1, and repeated if trial was repeated
%    plexonGoTime     Time stamp for start of first presentation within the trial. But what this actually
%                        seems to be is the end of the trial, when a Stimulus END event was sent to the
%                        plexon data file, so it seems we want the 5 sec before this signal, not after.
%                        To make this value equal to END, do this:
%                             stimKeyTS = stimKey(:,2) - stimKey(1,2) + tsevs{1}(2);
%                        The result is synchronized with tsevs{1} to within 0.1 sec (the difference is
%                        sometimes positive and sometimes negative).
%    Success          Binary, 0=failure and trial needs to be repeated
%    eyeCond          1=L, 2=R, 3=both eyes stimulated
%    Presentation 1, Presentation 2,..., Presentation N    Returned durations of stimuli (or 0 if failed trial)

% Read the plx data.
% Questions:
%    The vep time series looks to be sampled at 1000 Hz. Where is this within the plexon data?
%        The text printed to stdout says "Frequency : 40000" but nothing about 1000.
% In the output for readall_plexon:
%    allad=all analog data. For vep this is a 7xN cell array with vectors for:
%       1 xLE, 2 yLE, 3 pupilDiamLE, 4 xRE, 5 yRE, 6 pupilDiamRE, 7 VEP electrode
%    tsevs = timestamps of events. Cell array with 19 vectors:
%       1 stimulus END
%       2 stimulus TRIGGER
%       3 GO (i.e. OK to start stimulus - eyes are open)
%       4 STOP (blink or eye deviation detected?)
%       To see these series plotted on the same axes, run Show_tsevs.m
%       How it worked in the experiment: The rest period was 5 sec, first a 4 sec enforced rest then a 1 sec
%          period with green fixation mark to indicate to S they should blink one last time before stimulus
%          resumes. They had to blink during this time. Then the stimulus was displayed for 5 sec. This cycle
%          was repeated 18 times, plus as many additional times as needed to replace trials with eye blinks.
%          Thus: TRIGGER is issued when the fixation turns green at the end of the 4 sec. Then the stimulus
%          machine waits for a STOP signal, then it waits for a GO signal, then it starts the stimulus which
%          runs for the next 5 sec. At that point END is issued and nothing happens for the next 4 sec, until
%          the next TRIGGER. For reasons I don't quite understand, there are 5.6 or 5.9 or so sec between the
%          final GO and the STOP (probably because the green mark has to be on for at least a second), and
%          the time between trials is quite a bit larger than the 10 sec intended. Not sure what's causing
%          the extra waiting.
%             However, for reasons I don't understand, there were sometimes two blinks required before the start
%          of the next trial. Often there is a GO STOP GO, but sometimes also there's a STOP GO STOP GO after
%          the TRIGGER (i.e. after the green fixation mark comes on) before the stimulus starts.
%    allts=? (unused)
%    tsad=?
[allad,tsevs,allts,tsad]=readall_plexon(filename_plx);
vepData = allad{7};              % 7 is the channel for the VEP data
if filterDataFlag
    vepData = Remove60Hz(vepData, Fs);  % Remove 59-61 Hz signal
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Look at raw vep data, do fft to see e.g. power of 60 Hz signal.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if showRawDataFlag
    %         vepData = allad{7}(round(length(allad{7}))/2:end);          % Look at only half the data
    T = 1/Fs;                     % Sample time
    L = length(vepData);             % Length of signal
    t = (0:L-1)*T;                % Time vector (in seconds)
    figure
    subplot(2,1,1)   % VEP data series first
    plot(t, vepData)
    title('VEP Signal')
    xlabel('Time (sec)')

    subplot(2,1,2)   % FFT
    NFFT = 2^nextpow2(L); % Next power of 2 from length of y
    Y = fft(vepData,NFFT)/L;
    f = Fs/2*linspace(0,1,NFFT/2+1);
    % Plot single-sided amplitude spectrum.
    amplitudes = 2*abs(Y(1:NFFT/2+1));
    plot(f,amplitudes)
    title('Single-Sided Amplitude Spectrum of VEP signal')
    xlabel('Frequency (Hz)')
    ylabel('|Y(f)|')
    set(gca, 'XLim', [0 500])
    set(gca, 'YLim', [0 0.001])   % Kludge. At 2000th freq the amplitude is low enough for scaling
    %         set(gca, 'YLim', [0 max(amplitudes(2000:end))])   % Kludge. At 2000th freq the amplitude is low enough for scaling
end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Find the trial start times
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This is a bit tricky since we don't actually have the stimulus start time recorded in the
%   plexon file. I don't think it's in the stimKey file either. But we have the stimulus ending
%   times in the plexon file so these can be synchronized.
% New data (not VEP, just stimKey data) collected on 3 July with better time-stamp information
%   shows that the inter-stimulus interval averages 1039 msec, occasionally being as high as
%   1078 msec. We can no longer recover the exact values from previously collected data files
%   because we time-stamped only the GO signal at the start, and the stim END signal as events.
%   So instead, we'll find the times of the END signals and go backwards from there to get
%   approximate stimulus start times of T - n*1.039 sec, n=1:5. Lame, but at least we'll see something
%   if there's any signal to be had. Alternatively we could go foward from the final GO signal before
%   the trial started. There's no reason to think that would be better however.

% Find the good values among the STIM END time stamps (i.e. for trials we want to analyze)
keeperTrialIndx = stimKey(:,3)==1;
keeperTrials = stimKey(keeperTrialIndx, :);     % Reduced table with only the essential trials
if size(tsevs{1,2},1) > 2*size(tsevs{1,1},1)    % New style (after 2014-08-12) plexon file, with lots of stimulus triggers
    fprintf('Using NEW stim trigger method to align data\n');
    tStimStart = GetStimStartTimesVEP(tsevs, stimKey, plotTimeStampsFlag, nCheckBdPerTrial);
else  % Old style that doesn't use stimulus triggers to align the data
    fprintf('Using OLD stim trigger method to align data\n');
    stimOffsetSec = GetStimKeyOffsetVEP(tsevs, stimKey, plotTimeStampsFlag);    % Get the offset for interpreting stimKey times in seconds from start of Plex recording
    tStimStart = repmat(keeperTrials(:,9), 1, 10) + stimOffsetSec + repmat(dispTimeSec*(0:(nCheckBdPerTrial-1)), length(keeperTrials), 1);       % Stimulus start times in plexon file seconds
end
nTrial = size(tStimStart, 1);                   % Number of trials
nStim = size(tStimStart, 2);                    % Number of stimuli per trial
condKey = keeperTrials(:, 4);                   % 1, 2, or 3 for eye condition (L, R, Both).

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Get the VEP data corresponding to the 500 msec after the start of each trial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nSample = 500; % Number of vep data stream samples within window
tVals = 0:(nSample-1);

% Assume a sampling rate of 1000 Hz, and that data collection started at plexon time = 0
vepTrialData = zeros(nTrial, nStim, nSample);
for iTrial = 1:nTrial
    for iStim = 1:10
        indxData = tVals + round(1000*tStimStart(iTrial, iStim));
        vepTrialData(iTrial, iStim, :) = vepData(indxData);
    end
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Group the data by eye condition, smooth, plot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

smoothSpan = 20;       % window for smoothing
%     smoothSpan = 10;       % window for smoothing
meanData   = zeros(6,nSample);
smoothData = zeros(6,nSample);
normData   = zeros(6,nSample);
for iCond = 1:6
    keeperData = vepTrialData(condKey==iCond, :, :);
    meanData(iCond,:) = squeeze(mean(mean(keeperData, 1),2));     % Average across all trials for that eye cond
    smoothData(iCond,:) = smooth(meanData(iCond,:), smoothSpan);   % Smooth the data
    normData(iCond,:) = smoothData(iCond,:) - mean(smoothData(iCond,:));
end

% Plot the data
figure

subplot(2,1,1);  % Large checks
h1=plot(tVals, normData(1:3,:));
legend('LE-60', 'RE-60', 'B-60', 'Location', 'NorthEastOutside');
if filterDataFlag
    filterText = ' (60Hz, 180Hz removed)';
else
    filterText = [];
end
% subSesScanStr = ['Sub ' num2str(iSub) ', Ses ' num2str(iSes) ', Scan ' 'a'+iScan-1];
% title([filename_plx(1:8) ' = ' subSesScanStr filterText])
title(['For plx file ''...' filename_plx(end-30:end) '''']);
set(gca, 'YLim', [-0.015 0.020]);

subplot(2,1,2);  % Small checks
h2=plot(tVals, normData(4:6,:));

legend('LE-15', 'RE-15', 'B-15', 'Location', 'NorthEastOutside');
ylabel('VEP signal');
xlabel('Time (msec)')
set(gca, 'YLim', [-0.015 0.020]);

set(h1,'LineWidth',2);
set(h2,'LineWidth',2);

end
