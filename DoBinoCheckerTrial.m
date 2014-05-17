function result = DoBinoCheckerTrial(A, E, H, trialType)
%
% Run one trial of the experiment. This is a generic function that assumes
% a PsychToolbox display window is already open. 
%
% Inputs:
%    A, E, H, trialType
%   
% Outputs:
%    result
%
% BB 2014-05-17

% Build the stimulus type (this should rather be done once at the start of experiment for all images)
oneStim = BuildBinoCheckStim(A, E, trialType);

% Show the stimulus the correct number of times for the trial
for iStim = 1:E.trial.nStimPerTrial
    result(iStim) = ShowStimulus(A, E, H, oneStim);
    
    [~, ~, keyCode] = KbCheck;
    if keyCode(H.escapeKey)
        result = -1; % replace vector of times with error code
        break
    end
end
