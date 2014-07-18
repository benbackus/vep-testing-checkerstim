function oneStim = BuildBinoCheckStim(A, E, trialType)
% function oneStim = BuildBinoCheckStim(A, E, trialType)
%
% Create binocular stimulus to show on one trial of VEP experiment,
% suitable for passing to the function ShowStimulus.
% Stimulus is a flashing checkerboard shown to one or both eyes.
% The duration of one stimulus is limited because the stimulus will be
% shown again if there was a blink that occurred during presentation.
% 
% There is no color animation coded here, however the same image can be
% generated with different colors and shown at different times.
%
% Input 
%
%   Fields of A used:
%     .viewDistCm                optical distance from eyes to screen in cm
%     .displaySizeCm             size of display in cm [x y]
%   
%   Fields of E used:
%     .screenResXY               [x y] Screen resolution to use
%     .stim.checkSizeDeg         Size of Checks in degrees         
%     .stim.checkHz              Flicker rate for contrast reversal of the pulse
%     .stim.flickerDurSec        Duration of the stimulus pulse (e.g. 0.200 sec)
%     .stim.stimDurSec           Duration of the entire stimulus including blank time (e.g. 0.500 sec)
%     .stim.checkContrast        Scalar, 0 to 1
%     .stim.deadZoneDeg          Size of dead zone between the left and right images
%
%   trialType                    1, 2, or 3 for LE, RE, or Both (can also be 0 for neither)
%                                   When 4,5,6 it's L,R,both for 2nd check size, etc.
%   
% Output
%
%   oneStim                     Structure containing a list of images, a list of color codes, and list of image numbers and display times 
%     .images                   uint8 3D array of color numbers: nRow x nCol x nImage. 
%     .colorCodes               256 x 1, entries are gray levels (0=black to 255=white) for the different color numbers (1 to 255);
%                                  or 256 x 3, where each entry is the RGB for a different color number (0 to 255).                    
%     .imageListTimes           nStim x 2 matrix of times (in sec) and image numbers. 
%   
% BB 2014-05-16

imSizeXYPix = E.screenResXY;              % Use full screen size for image size
if trialType == 0          % Check if it's supposed to be a blank screen
    whichEye = 0;
    indxCheckSize = 1;     % Not actually used to build the stimulus in this case
else
    whichEye = 1+mod(trialType-1,3);          % 1, 2 or 3
    indxCheckSize = ceil(trialType/3 - eps);  % 1, 2, ..., length(E.stim.checkSizeDeg)
end

% Size of checks is created assuming that pixels are square, i.e. it's OK to do this using xSize alone
pixPerCm  = imSizeXYPix(1) / A.displaySizeCm(1);
pixPerDeg = (pixPerCm * A.viewDistCm) / 180 * pi;  % pix per radian, converted to pix per deg
checkSizePix = round(E.stim.checkSizeDeg(indxCheckSize) * pixPerDeg);
deadZonePix = round(E.stim.deadZoneDeg * pixPerDeg);
if mod(deadZonePix,2)     % Make it even so that final image won't be 1 pixel shy
    deadZonePix = deadZonePix + 1;
end

% Build the images. Fixation mark to be added later.
colors2use1 = [1 2 3 4];    % Regular contrast checkerboard
checkerImage1 = MakeBinoCheckImage(imSizeXYPix, checkSizePix, deadZonePix, whichEye, colors2use1);
colors2use2 = [1 2 4 3];    % Reverse contrast checkerboard
checkerImage2 = MakeBinoCheckImage(imSizeXYPix, checkSizePix, deadZonePix, whichEye, colors2use2);
colors2use3 = [1 2 2 2];    % Blank stimulus
blankStim = MakeBinoCheckImage(imSizeXYPix, checkSizePix, deadZonePix, whichEye, colors2use3);
oneStim.images = cat(3, checkerImage1, checkerImage2, blankStim);

% Set the color maps. For now we assume a calibrated RGB color map.
colorDeadZone = [0 0 0];   % Black
colorBackground = [0.5 0.5 0.5];  % Mid gray (not yet calibrated) ###
color1 = colorBackground * (1 + E.stim.checkContrast); 
color2 = colorBackground * (1 - E.stim.checkContrast); 
oneStim.colorCodes = [...
    colorDeadZone   
    colorBackground 
    color1          
    color2          ];

% Set the list of images and times. First the flickering checkerboards, then the blank interval.
imageDurSec = 0.5/E.stim.checkHz;      % Each image lasts half a cycle
nFlicker = E.stim.flickerDurSec / imageDurSec;
if nFlicker < 1
    error('Number of flickering stimuli is less than 1!');
end
nFlicker = round(nFlicker);
timeImageMx = zeros(nFlicker+2, 2);
timeImageMx(:,1) = [(0:nFlicker) * imageDurSec, E.stim.stimDurSec]';   % Times at which to show the images, plus when to terminate 
timeImageMx(:,2) = [(mod(1:nFlicker,2)+1), 3, -1]';  % Which images to show: 2,1,...,2,1, then 3, then the last one is -1 = code to terminate
oneStim.imageListTimes = timeImageMx;

end