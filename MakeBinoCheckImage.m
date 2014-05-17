function checkerImage = MakeBinoCheckImage(imSizeXYpix, checkSizePix, deadZonePix, whichEye, colors2use)
% function checkerImage = MakeBinoCheckImage(imSizePixXY, checkSizePix, deadZonePix, whichEye, colors2use)
%
% Create a checkerboard stimulus for display in a mirror stereoscope. The image is a
% uint8 matrix, usually it will be the same size as the display. The actual colors have to
% be assigned by the calling functions. whichEye determines whether the checkerboard is
% shown to the left eye, right eye, neither, or both.
%
% Input:
%   checkSizePix   scalar, size of edge of each square in pixels
%   imSizePixXY    2x1, Size of image in pixels, [x y]
%   deadZonePix    scalar, width of dead zone in the middle in pix
%   whichEye       scalar, 0 (neither eye), 1 (left), 2 (right), or 3 (both).
%   colors2use     4x1 or 6x1, color codes for: dead zone, background, color1, and color2.  
%                     If colors2use is 6x1 then it specifies 
%                        [dead zone, background, color1_L, color2_L, color1_R, color2_R]
%                     Note that the background color is used only when whichEye specifies
%                        no image for that eye.
%                     Colors will be converted to unint8 for use in matrix.
%  
% Output:
%   checkerImage   uint8 matrix of size imSizePix with entries from colors2use. This is an
%                     image, not an [x,y] matrix, in terms of its indexing.
%
% BB 2014-05-12 wrote it

xSize = imSizeXYpix(1);
ySize = imSizeXYpix(2);
xSizeMonoc = floor((xSize - deadZonePix)/2);            % Width of monocular image 
monocImBlank = repmat(uint8(0), ySize, xSizeMonoc);     % Monocular image matrix with row, col indexing

% Create monocular image with x,y indexing
[X,Y] = meshgrid(1:xSizeMonoc, 1:ySize);
checks = mod(floor((X-1)/checkSizePix)+floor((Y-1)/checkSizePix), 2);  % 0 or 1 depending whether pixel is foreground check        

% In most cases the two monocular images will be the same, so compute it here  
monocIm = checks;
monocIm(checks==0) = colors2use(3);
monocIm(checks==1) = colors2use(4);

% Set the left and right eye images, depending on whichEye and whether the left and right eyes
% 
switch whichEye
    case 0   % Checks in neither eye
        monocImL = monocImBlank + colors2use(2);    % Pure background color
        monocImR = monocImL;
    case 1   % Checks in left eye only
        monocImL = monocIm;
        monocImR = monocImBlank + colors2use(2);    % Pure background color
    case 2   % Checks in right eye only
        monocImL = monocImBlank + colors2use(2);    % Pure background color
        if length(colors2use)==4
            monocImR = monocIm;
        else % length is 6 so use different colors in RE
            monocImR = checks;
            monocImR(checks==0) = colors2use(5);
            monocImR(checks==1) = colors2use(6);
        end
    case 3   % Checks in both eyes
        monocImL = monocIm;
        if length(colors2use)==4
            monocImR = monocIm;        % Same in both eyes
        else % length is 6 so use different colors in RE
            monocImR = checks;
            monocImR(checks==0) = colors2use(5);
            monocImR(checks==1) = colors2use(6);
        end
    otherwise
        error('whichEye must be 0,1,2,or 3');
end

deadZoneImage = repmat(uint8(colors2use(1)), ySize, deadZonePix);
checkerImage = [monocImL deadZoneImage monocImR];

