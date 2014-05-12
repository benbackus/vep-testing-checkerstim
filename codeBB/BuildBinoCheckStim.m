function stim = BuildBinoCheckStim()
% 
% Create binocular stimulus to show on one trial of VEP experiment
% Stimulus is a flashing checkerboard shown to one or both eyes.
% The duration of one stimulus is limited because the stimulus will be
% shown again if there was a blink that occurred during presentation.

checkerImage = BinoChecks(imSizePixXY, checkSizePix, deadZonePix, whichEye, colors2use);

end