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

%% Specify whether to use debug mode (no Plexon calls) or not
H = struct();
H.usePlexonFlag = true;   % Set this to true for eye position monitoring, false for debugging

%% Get experimental variables, set up necessary parameters, open data files for the experiment

% Seed the random number generator based on current time
rng('shuffle');

A = SetParams_Apparatus;           % Parameters controlling the stimuli in the experiment
E = SetParams_Expt_BinoChecks3;    % Parameters controlling the experiment
% L = LowLevelParams;              % Parameters and constants for low-level communcation between parts

% Set the trial order (1=OS, 2=OD, 3=OU) using random permutations of 1, 2, and 3 (L, R, both)
% Note that 1,2,3 are for check size 1; 4,5,6 are for check size 2; and 7,8,9 are for check size 3, etc.
trialOrder = [];
nCond = 3 * length(E.stim.checkSizeDeg);  % Number of conditions equals 3 eye conds (OD,OS,OU) x n check sizes
for iRep = 1:E.expt.nTrialPerCond         % Same as number of trials for R, both
    trialOrder = [trialOrder, randperm(nCond)];
end
E.expt.trialOrder = trialOrder;    % Set this parameter here

% Open data file for record of stimuli presented and responses to task
% Create a cell array (vector) of strings that will be written as the first line of the data file,
%   of the form {'Presentation 1', 'Presentation 2', ...}
presentationStrs1 = cellfun(...
    @(stimNum){sprintf('Stim %i dur',stimNum)}, num2cell(1:E.trial.nStimPerTrial));
presentationStrs2 = cellfun(...
    @(stimNum){sprintf('Stim %i start',stimNum)}, num2cell(1:E.trial.nStimPerTrial));
presentationStrs3 = cellfun(...
    @(stimNum){sprintf('Stim %i end',stimNum)}, num2cell(1:E.trial.nStimPerTrial));
dataColumns = [{'iTrial', 'plexonGoTime', 'Success', 'trialType', 'eyeCond', 'Check Size (arcmin)', 'trialLocalGoTime'} presentationStrs1 presentationStrs2 presentationStrs3 ];  % Catenate to prepend more items to the list 
subjectCode = input('Subject Code: ', 's');
runNumber   = input('Enter run number (a,b,...) and hit Enter to start the experiment: ', 's');
curDate = datestr(now, 'yyyy_mmdd');

sessionName = [subjectCode 'vCHK' '_' curDate '_' runNumber];
datafile = DataFile(DataFile.defaultPath(sessionName), dataColumns);  % Open the data file
fprintf('VEP Checker Stim Expt for session %s is now starting.\n', sessionName);

%% Prepare the display
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'FinalFormatting', 'DisplayColorCorrection',...
    'LookupTable');
PsychImaging('AddTask', 'General', 'UseFastOffscreenWindows');
PsychImaging('AddTask', 'General', 'FloatingPoint32Bit');

%Screen('Preference', 'SkipSyncTests', 1); % for debug only!
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
if H.usePlexonFlag
    H.PLserver = PL_InitClient(0);
    PLEXON_FILE_START_EVENT_STROBE = 258;
    PLEXON_FILE_END_EVENT_STROBE = 259;

    LPTSetup();
    LPT_Stimulus_Trigger = 4;
    LPT_Stimulus_End= 1;
end

%% Build the image for the end-of-blink signal
oneStim = BuildBinoCheckStim(A, E, 0);                % whichEye argument is 0 -> no checkerboards
colorCodes255 = uint8(round(mean(oneStim.colorCodes, 2) * 255)); % Convert real values from 0-1 to 0-255. Colors are changed to grayscale.
image2D = colorCodes255(oneStim.images(:,:,1));     % Convert image from color codes to gray values
hTextureWarning = Screen('MakeTexture', H.screenWindow, image2D);

% Create a warning tone during blinking period (not currently used)
% pitch = 440;
% rate = 8192;
% duration = 0.2;
% soundwave = sin(pitch*(0:(2*pi/rate):(2*pi*duration)))';
% warnTonePlayer = audioplayer(soundwave, rate);
% warnPeriod = 1.0;

%% Run the trials
try
    % Allow experimenter to get the subject ready while subject views blank
    % screen
    Screen('DrawTexture', H.screenWindow, hTextureWarning);
    DrawFixationMark(A, E, H, 255.0);
    Screen(H.screenWindow, 'Flip');
    
    % Extract file-start timestamp offset (GetEventsPlexon will record a
    % positive number, while the actual plx file will record approximately
    % zero)
    fileStartTs = [];
    while isempty(fileStartTs)
        [~, eventTs] = PL_GetTS(H.PLserver);
        if ~isempty(eventTs)
            fileStartEventIdx = find(eventTs(:,2) == PLEXON_FILE_START_EVENT_STROBE, 1, 'last');
            fileEndEventIdx = find(eventTs(:,2) == PLEXON_FILE_END_EVENT_STROBE, 1, 'last');
            
            if fileStartEventIdx < fileEndEventIdx
                fileEndEventIdx = []; % Last file opened is already closed!
            end
        else
            fileStartEventIdx = [];
        end
        
        if isempty(fileStartEventIdx)
            fprintf('No or old plexon file open? (Re)start plexon data collection, then press any key...');
            pause();
            fprintf('\n');
        else
            fileStartTs = eventTs(fileStartEventIdx, 4);
        end
    end
    fprintf('File start timestamp (approximate offset?): %f\n', fileStartTs);
    
    nTrial = length(trialOrder);
    result = cell(1, nTrial);
    
    for iTrial = 1:nTrial
        needToPresent = true; % whether to present (again)
        result{iTrial} = {};
        while needToPresent
            fprintf('Trial %i (stim condition = %i)...', iTrial, E.expt.trialOrder(iTrial));
            
            % Waiting period to allow subject to blink
            startTime = GetSecs();
            endTime = startTime + E.trial.ITIsec;
            warningTriggeredFlag = false;
            % Draw regular fixation screen at start of intertrial interval
            Screen('DrawTexture', H.screenWindow, hTextureWarning);
            DrawFixationMark(A, E, H, 255.0);
            Screen(H.screenWindow, 'Flip');
            while GetSecs() < endTime
                % If close to end time, show warning to blink once and then keep eyes open
                if (GetSecs() > (endTime - E.trial.warnNoBlinkSec)) && ~warningTriggeredFlag
                    if H.usePlexonFlag
                        LPTTrigger(LPT_Stimulus_Trigger);
                    end
                    Screen('DrawTexture', H.screenWindow, hTextureWarning);
                    DrawFixationMark(A, E, H, E.warnSignalColor);
                    Screen(H.screenWindow, 'Flip');
                    warningTriggeredFlag = true;
                end
                WaitSecs(min(0.1, 0.99*(endTime - GetSecs())));
            end
            
            % Wait for GO from Plexon, indicating that eyes are open and tracked
            if H.usePlexonFlag
                go_ts = []; GetEventsPlexon(H.PLserver);
                fprintf('Waiting for go...');
                while isempty(go_ts)
                    [~,~,go_ts,~]=GetEventsPlexon(H.PLserver);
                    
                    % Allow override by experimenter (usually to exit)
                    [~, ~, keyCode] = KbCheck;
                    if keyCode(H.escapeKey)
                        break;
                    end

                    pause(1e-4); % prevent 100% CPU usage
                end
                localGoTime = GetSecs();
                fprintf('Going now!');
            else
                localGoTime = GetSecs();
            end
            fprintf('\n');

            % Show the stimulus. After ensuring that the subject's eyes are open, show fixation screen
            % briefly just prior to first stimulus of the trial.
            Screen('DrawTexture', H.screenWindow, hTextureWarning);
            DrawFixationMark(A, E, H, 255.0);
            Screen(H.screenWindow, 'Flip');
            WaitSecs(E.trial.blankStartSec);
            
            if H.usePlexonFlag
                onFlipFunction = @()LPTTrigger(LPT_Stimulus_Trigger);
            else
                onFlipFunction = @()[]; % do-nothing function
            end

            latestResult = DoBinoCheckerTrial(A, E, H, E.expt.trialOrder(iTrial), onFlipFunction);  % Do a trial of eyeCond = 1, 2, or 3 (LE, RE, both) depending on trial type
            result{iTrial} = { result{iTrial}{:} latestResult };  % List of any blink trials (-1 values) followed by vector of stimulus times upon success 

            if H.usePlexonFlag
                LPTTrigger(LPT_Stimulus_End);

                % Check for blinks ("Stop" signal sent from Plexon)
                [~,~,~,stop_ts]=GetEventsPlexon(H.PLserver);
                needToPresent = ~(isempty(stop_ts) && isstruct(latestResult));  % latestResult is -1 upon failure, or a structure upon success
                if needToPresent
                    fprintf('%s\n', 'Blink or interrupt detected!');
                end
            else
                needToPresent = false;
            end

            % Write to data file
            if needToPresent
                stimTimes = zeros(1, E.trial.nStimPerTrial);
                stimStartTimes = zeros(1, E.trial.nStimPerTrial);
                stimEndTimes = zeros(1, E.trial.nStimPerTrial);
            else
                stimTimes  = [latestResult.totalTime];   % This creates a vector from latestResult{:}.totalTime
                stimStartTimes = [latestResult.stimStartTime];
                stimEndTimes   = [latestResult.stimEndTime];
            end
            if ~H.usePlexonFlag
                go_ts = -1;
            end
            
            % Append data from this trial to the data file
            trialType = E.expt.trialOrder(iTrial);
            whichEye = 1+mod(trialType-1,3);          % 1, 2 or 3
            indxCheckSize = ceil(trialType/3 - eps);  % 1, 2, ..., length(E.stim.checkSizeDeg)
            checkSizeArcmin = 60 * E.stim.checkSizeDeg(indxCheckSize);
            datafile.append([iTrial, go_ts, ~needToPresent, trialType, whichEye, checkSizeArcmin, ...
                localGoTime, stimTimes, stimStartTimes, stimEndTimes]);

            % Abort if holding down Esc key
            [~, ~, keyCode] = KbCheck;
            if keyCode(H.escapeKey)
                needToPresent = false;
            end
        end
        [~, ~, keyCode] = KbCheck;
        if keyCode(H.escapeKey) || (exist('latestResult', 'var') && latestResult(1).stimStartTime == -1)  % -1 is error code
            break;
        end
    end
    
    % Grab the data for a quick analysis
    cancelAnalysis = false;
    while ~cancelAnalysis
        goodPLXPath = false;
        while ~goodPLXPath && ~cancelAnalysis
            plxFileName = input('Which plx filename to analyze? Just press Enter to skip: ', 's');

            if isempty(plxFileName)
                cancelAnalysis = true;
            else
                % Ensure that file name has the '.plx'
                if length(plxFileName) < 4 || ~strcmpi(plxFileName(1,end-3:end), '.plx')
                    plxFileName = [plxFileName '.plx'];
                end

                % Make sure the file actually exists
                plxFilePath = plxFileName;
                if exist(plxFilePath, 'file')
                    goodPLXPath = true;
                else
                    plxFilePath = ['\\plexon-1705\VEPData\BackusData' filesep plxFileName];
                    if exist(plxFilePath, 'file')
                        goodPLXPath = true;
                    else
                        fprintf('No such file ''%s'' found - trying again...\n', plxFilePath);
                    end
                end
            end
        end
        if ~cancelAnalysis
            QuickAnalyze(datafile.data, plxFilePath);
        end
    end
catch caughtException
end

%% Close display and exit gracefully
Screen('CloseAll');
% Close data file
fprintf('Closing datafile %s for session %s.\n', fopen(datafile.fileHandle), sessionName);
delete(datafile);

if exist('caughtException', 'var')
    rethrow(caughtException);
end
