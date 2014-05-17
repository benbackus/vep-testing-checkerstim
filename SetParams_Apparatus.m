function A = SetParams_Apparatus(A)
% SetParams_Apparatus
%   Set the hardware, viewing distance, and other parameters
%
% BB 2014-05-16

if ~exist('A', 'var')
    A = [];
end
 
A.testRoom      = '1419';        % room in which experiment will be run
A.viewDistCm    = 70;            % optical distance from eyes to screen in cm
A.displaySizeCm = [50 30];       % size of display in cm [x y]
A.lumCalibFile  = '';            % full name including path of luminance calibration file
A.screenNumber  = 0;             % Screen number to use with PsychToolbox window

end % of function
