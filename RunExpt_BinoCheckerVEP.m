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
    trialOrder = [trialOrder, randperm(3)];
end
E.expt.trialOrder = trialOrder;    % Set this parameter here

% Open data file for record of stimuli presented and responses to task
% Create a cell array (vector) of strings that will be written as the first line of the data file,
%   of the form {'Presentation 1', 'Presentation 2', ...}
presentationStrs = cellfun(...
    @(stimNum){sprintf('Presentation %i',stimNum)}, ...
    num2cell(1:E.trial.nStimPerTrial));
dataColumns = [{'iTrial', 'plexonGoTime', 'Success', 'eyeCond'} presentationStrs];  % Catenate to prepend more items to the list 
sessionName = input('Session name (Subjectcode+experimentInitial): ', 's');
datafile = DataFile(DataFile.defaultPath(sessionName), dataColumns);

%% Prepare the display
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'FinalFormatting', 'DisplayColorCorrection',...
    'LookupTable');
PsychImaging('AddTask', 'General', 'UseFastOffscreenWindows');
PsychImaging('AddTask', 'General', 'FloatingPoint32Bit');

%Screen('Preference', 'SkipSyncTests', 1); % for debug only!
H = struct();
res = Screen('Resolution', A.screenNumber);
if ~all([res.width res.height] == E.screenResXY)
    fprintf(['Current screen resolution is not the expected %ix%i! '...
        'Press Ctrl-C to interrupt, or any key to continue'], ...
        E.screenResXY(1), E.screenResXY(2))
    pause()
end
H.screenWindow = PsychImaging('OpenWindow', A.screenNumber, [], [], [], [], [], [], [], [], [0 0 E.screenResXY]);

% Set up color calibration
H.lumCalib = importdata('lumCalib 1419 2014-05-27.mat');
H.lumCalib(:,2) = H.lumCalib(:,2) ./ max(H.lumCalib(:,2));
H.lumChannelContrib = [0.185506 0.743230 0.071263];
H.white = 255;
table = LumToColor(H, ((0:1023)./1023.0)');
table = table * 1/255; % HACK
PsychColorCorrection('SetLookupTable', H.screenWindow, table);

Screen('BlendFunction', H.screenWindow, ...
    GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

% Specify key to interrupt experiment
KbName('UnifyKeyNames');
H.escapeKey = KbName('ESCAPE');

% Initialize Plexon & parallel port data connection
H.usePlexonFlag = true;
if H.usePlexonFlag
    H.PLserver = PL_InitClient(0);

    LPTSetup();
    LPT_Stimulus_Trigger = 4;
    LPT_Stimulus_End= 1;
end

%% Build the image for the end-of-blink signal
oneStim = BuildBinoCheckStim(A, E, 0);                % whichEye argument is 0 -> no checkerboards
colorCodes255 = uint8(round(mean(oneStim.colorCodes, 2) * 255)); % Convert real values from 0-1 to 0-255. Colors are changed to grayscale.
image2D = colorCodes255(oneStim.images(:,:,1));     % Convert image from color codes to gray values
hTextureWarning = Screen('MakeTexture', H.screenWindow, image2D);

%% Run the trials
nTrial = length(trialOrder);
result = cell(1, nTrial);

% Wait and allow subject to blink between trials
WaitSecs(E.trial.ITIsec - E.trial.warnNoBlinkSec);    % Intertrial interval for blinking
Screen('DrawTexture', H.screenWindow, hTextureWarning);
DrawFixationMark(A, E, H, E.warnSignalColor);
Screen(H.screenWindow, 'Flip');
WaitSecs(E.trial.warnNoBlinkSec);

for iTrial = 1:nTrial
    needToPresent = true; % whether to present (again)
    result{iTrial} = {};
    while needToPresent
        
        if H.usePlexonFlag
            LPTTrigger(LPT_Stimulus_Trigger);
            go_ts = []; GetEventsPlexon(H.PLserver);
            fprintf('%s', 'Waiting for go...');
            while isempty(go_ts)
                [~,~,go_ts,~]=GetEventsPlexon(H.PLserver);
                pause(1e-2); % prevent 100% CPU usage
            end
            fprintf('%s\n', 'Going now!');
        end
        
        latestResult = DoBinoCheckerTrial(A, E, H, E.expt.trialOrder(iTrial));  % Do a trial of type 1, 2, or 3 (LE, RE, both) depending on trial type
        result{iTrial} = { result{iTrial}{:} latestResult };  % List of any blink trials (-1 values) followed by vector of stimulus times upon success 
        
        if H.usePlexonFlag
            LPTTrigger(LPT_Stimulus_End);

            % Check for blinks ("Stop" signal sent from Plexon)
            [~,~,~,stop_ts]=GetEventsPlexon(H.PLserver);
            needToPresent = ~(isempty(stop_ts) && ~isscalar(latestResult));  % latestResult is -1 upon failure, or a vector upon success
            if needToPresent
                fprintf('%s\n', 'Blink or interrupt detected!');
            end
        else
            needToPresent = false;
        end
        
        % Write to data file
        if needToPresent
            stimTimes = zeros(1, E.trial.nStimPerTrial);
        else
            stimTimes = [latestResult.totalTime];
        end
        datafile.append([iTrial, go_ts, ~needToPresent, E.expt.trialOrder(iTrial), stimTimes]);
        
        % Abort if holding down Esc key
        [~, ~, keyCode] = KbCheck;
        if keyCode(H.escapeKey)
            needToPresent = false;
        end
    end
    [~, ~, keyCode] = KbCheck;
    if keyCode(H.escapeKey) || (exist('latestResult', 'var') && isscalar(latestResult))
        break;
    end
    
    % Wait and allow subject to blink between trials
    WaitSecs(E.trial.ITIsec - E.trial.warnNoBlinkSec);    % Intertrial interval for blinking
    % Give warning signal
    Screen('DrawTexture', H.screenWindow, hTextureWarning);
    DrawFixationMark(A, E, H, E.warnSignalColor);
    Screen(H.screenWindow, 'Flip');
    WaitSecs(E.trial.warnNoBlinkSec);
    % Removal of warning signal is done by ShowStimulus
    
end

%% Close display and exit gracefully
Screen('CloseAll');
% Close data file
delete(datafile);
