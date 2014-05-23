% Script RunExpt_BinoCheckerVEP
%
% Run the Binocular Checker VEP experiment.
%
% This experiment follows the example of Jens Kremkow. This code gets ready
% to show the stimulus. It checks for a GO signal in the event cue indicating that the eyes
% are open (and properly fixated, although that doesn't matter as much for this
% experiment). The stimulus runs, reporting when it has started and stopped
% so that the VEP system can time-stamp these events for correlation with
% the VEP signal(s). If a blink occurs during presentation of a stimulus,
% that stimulus is shown again.
%
% Internal structure of the code for this experiment:
%    A = SetParams_Apparatus;           % Parameters describing the apparatus
%    E = SetParams_Expt_BinoChecks1;    % Parameters controlling the experiment
%    This code calls DoTrial as many times as there are trials.
%      DoTrial calls ShowStimulus and GetResponse
%        ShowStimulus calls BuildBinoCheckStim
%          BuildBinoCheckStim calls MakeBinoCheckImage
%
%    Note that only a few images are used in this experiment. They could be created and loaded early on.   
%
%
% BB 5/14/2014

%% Get experimental variables, set up necessary parameters, open data files for the experiment

% Seed the random number generator based on current time
rng('shuffle');

A = SetParams_Apparatus;           % Parameters controlling the stimuli in the experiment
E = SetParams_Expt_BinoChecks1;    % Parameters controlling the experiment
% L = LowLevelParams;              % Parameters and constants for low-level communcation between parts

% Set the trial order (1=OS, 2=OD, 3=OU) using random permutations of 1, 2, and 3 (L, R, both)
trialOrder = [];
for iRep = 1:E.expt.nTrialOS       % Same as number of trials for R, both
    trialOrder = [trialOrder randperm(3)];
end
E.expt.trialOrder = trialOrder;    % Set this parameter here

% Open data file for responses to task  ###

%% Prepare the display
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'FinalFormatting', 'DisplayColorCorrection',...
    'LookupTable');
PsychImaging('AddTask', 'General', 'UseFastOffscreenWindows');
PsychImaging('AddTask', 'General', 'FloatingPoint32Bit');

Screen('Preference', 'SkipSyncTests', 1); % FIXME debug only
H = struct();
H.screenWindow = PsychImaging('OpenWindow', A.screenNumber, [], [], [], [], [], [], [], [], [0 0 E.screenResXY]);
%H.screenWindow = -1;

% FIXME need real calibration data here
H.lumChannelContrib = [.2 .7 .1]; % [R, G, B] contribution to total
H.lumCalib = [0:10:250, 255]';
H.lumCalib = [H.lumCalib (H.lumCalib ./ 255).^2 ];
H.white = 255;

table = LumToColor(H, ((0:1023)./1023.0)');
table = table * 1/255; % HACK
PsychColorCorrection('SetLookupTable', H.screenWindow, table);

Screen('BlendFunction', H.screenWindow, ...
    GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

KbName('UnifyKeyNames');
H.escapeKey = KbName('ESCAPE');

% Initialize Plexon & parallel port data connection
H.usePlexonFlag = false;
if H.usePlexonFlag
    H.PLserver = PL_InitClient(0);

    LPTSetup();
    LPT_Stimulus_Trigger = 4;
    LPT_Stimulus_End= 1;
end

%% Run the trials
nTrial = length(trialOrder);
result = cell(1, nTrial);
for iTrial = 1:nTrial
    needToPresent = true; % whether to present (again)
    result{iTrial} = {};
    while needToPresent
        
        if H.usePlexonFlag
            LPTTrigger(LPT_Stimulus_Trigger);
            go_ts = []; GetEventsPlexon(H.PLserver);
            fprintf('%s', 'Waiting for go...');
            while isempty(go_ts)
                [~,~,go_ts,~]=GetEventsPlexon(H.PLserver);   % ### Save this timestamp to output file for later correlation with VEP data
                pause(1e-2); % prevent 100% CPU usage
            end
            fprintf('%s\n', 'Going now!');
        end
        
        latestResult = DoBinoCheckerTrial(A, E, H, trialOrder(iTrial));  % Do a trial of type 1, 2, or 3 (LE, RE, both) depending on trial type
        result{iTrial} = { result{iTrial}{:} latestResult };  % List of any blink trials (-1 values) followed by vector of stimulus times upon success 
        
        if H.usePlexonFlag
            LPTTrigger(LPT_Stimulus_End);

            % Check for blinks
            [~,~,~,stop_ts]=GetEventsPlexon(H.PLserver);
            needToPresent = ~isempty(stop_ts);
            if needToPresent
                fprintf('%s\n', 'Blink detected!');
            end
        else
            needToPresent = false;
        end
        
        [~, ~, keyCode] = KbCheck;
        if keyCode(H.escapeKey) || ~isscalar(latestResult)  % latestResult is -1 upon failure, or a vector upon success
            needToPresent = false;
        end
    end
    [~, ~, keyCode] = KbCheck;
    if keyCode(H.escapeKey) || (exist('latestResult', 'var') && isscalar(latestResult))
        break;
    end
    WaitSecs(E.trial.ITIsec);                      % Intertrial interval for blinking
end

%% Close display and exit gracefully
Screen('CloseAll');

% Save the data file ###

