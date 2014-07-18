function E = SetParams_Expt_BinoChecks3(E)
%
% Set the hardware, viewing distance, and other parameters
% Version 3 allows more than one spatial frequency of the checkerboards 
%
% BB 2014-05-16

if ~exist('E', 'var')
    E = [];
end
 
E.screenResXY          = [1920 1080];     % [x y] Screen resolution to use

% Stimulus descriptors
E.stim.checkSizeDeg    = [1,1/4];      % 1 or 2 for big, 0.25 for small. Size of edge of checks in deg visual angle
E.stim.checkHz         = 1.0;           % Rate of flicker at onset. 1.0 Hz = 2 images/sec
E.stim.flickerDurSec   = 5.0;           % Duration of flickering portion of stimulus in sec 
E.stim.stimDurSec      = 5.0;           % Duration of single stimulus in sec (greater than or equal to flickerDurSec, with gray screen shown after flicker)
E.stim.checkContrast   = 0.80;          % Constrast of checkerboards
E.stim.deadZoneDeg     = 2;             % Size of dead zone between the left and right images

% Fixation mark descriptors
E.fixationBoxWidthDeg  = 0.5;           % Width of the fixation box in degrees
E.fixationLineWidthPx  = 2;             % Width of the lines of the fixation box

% Trial descriptors
E.trial.nStimPerTrial  = 1;             % Stimulus repeats per trial (between blinking rests)
E.trial.ITIsec         = 4.0;           % Intertrial interval for blinking
E.trial.warnNoBlinkSec = 1.0;           % Duration of end-of-rest signal prior to end of rest.
E.trial.blankStartSec  = 0.3;           % Duration of blank time at beginning of a trial before stimuli
E.warnSignalColor      = [0 255 0];     % 0-255 or [r g b]

% Experiment descriptors
% Example settings: Stimuli are 0.5 sec x 10 stimuli/trial = 5 sec for the stimulation portion of each trial. 
%   5 second to respond and blink = 10 sec and 10 stimuli per trial. x 18 trials makes 180 stimuli in 180 sec. 
E.expt.nTrialPerCond   = 3;             % Number of trials in the run for each combination of eye and sp freq 
E.expt.trialOrder      = [];            % This will be determined when the experiment is run

end
