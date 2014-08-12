function result = DoBinoCheckerTrial(A, E, H, trialType, onFlipFunction)
%
% Run one trial of the experiment. This is a generic function that assumes
% a PsychToolbox display window is already open. It shows as many stimuli
% as are needed to complete a single trial.
%
% At present there is no capability to collect responses or abort the trial
% due to fixation errors during any single trial. This is currently done in
% the calling program, which will repeat the entire trial.
%
% Inputs:
%    A, E, H, trialType
%    optional: onFlipFunction
%   
% Outputs:
%    result
%
% BB 2014-05-17

if nargin < 5 || isempty(onFlipFunction)
    onFlipFunction = @()[];
end

% Build the stimulus type (this should rather be done once at the start of experiment for all images)
oneStim = BuildBinoCheckStim(A, E, trialType);

% Show the stimulus the correct number of times for the trial
for iStim = 1:E.trial.nStimPerTrial
    result(iStim) = ShowStimulus(A, E, H, oneStim, onFlipFunction);
    
    [~, ~, keyCode] = KbCheck;
    if keyCode(H.escapeKey)
        result(1).stimStartTime = -1; % replace with error code
        break
    end
end
