function E = SetParams_Expt_BinoChecks1(E)
%
%   Set the hardware, viewing distance, and other parameters
%
% BB 2014-05-16

if ~exist('E', 'var')
    E = [];
end
 
E.screenResXY          = [800 600];     % [x y] Screen resolution to use

% Stimulus descriptors
E.stim.checkSizeDeg    = 2;             % Size of edge of checks in deg visual angle
E.stim.checkHz         = 10;            % Rate of flicker at onset
E.stim.flickerDurSec   = 0.2;           % Duration of flickering portion of stimulus in sec
E.stim.stimDurSec      = 0.5;           % Duration of single stimulus in sec
E.stim.checkContrast   = 0.85;           % Constrast of checkerboards
E.stim.deadZoneDeg     = 2;             % Size of dead zone between the left and right images

% Fixation mark descriptors
E.fixationBoxWidthDeg  = 0.5;           % Width of the fixation box in degrees
E.fixationLineWidthPx  = 2;             % Width of the lines of the fixation box

% Trial descriptors
E.trial.nStimPerTrial  = 10;            % Stimulus repeats per trial (between blinking rests)
E.trial.ITIsec         = 2;             % Intertrial interval for blinking

% Experiment descriptors
% Example settings: Stimuli are 0.5 sec x 10 stimuli/trial = 5 sec for the stimulation portion of each trial. 
%   5 second to respond and blink = 10 sec and 10 stimuli per trial. x 18 trials makes 180 stimuli in 180 sec. 
E.expt.nTrialOS        = 6;             % Number of left-eye only trials in the experiment. 
E.expt.nTrialOD        = 6;             % Number of right-eye only trials in the experiment
E.expt.nTrialOU        = 6;             % Number of both-eye trials in the experiment
if    E.expt.nTrialOS ~= E.expt.nTrialOD | E.expt.nTrialOS ~= E.expt.nTrialOU
    error('In this experiment the number of trials in OD, OS, and OU currently must be the same.');
end
E.expt.trialOrder      = [];            % This will be determined when the experiment is run

end
