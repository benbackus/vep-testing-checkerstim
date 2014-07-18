function report = ShowStimulus(A, E, H, oneStim)
% function report = ShowStimulus(A, E, oneStim)
%
% Show a stimulus in the VEP experiment.
%
% At present there is no capability to collect responses or abort the trial
% due to fixation errors during any single stimulus.
%
% Input:
%
%   A                      Apparatus structure
%   E                      Experiment structure
%   H                      Handles structure (for open windows, graphics textures if pre-loaded) 
%   oneStim                a stimulus object with fields 
%     .images                   uint8 3D array of color numbers (values 1 to 255): nRow x nCol x nImage. 
%     .colorCodes               256 x 1, entries are gray levels (0=black to 255=white) for the different color numbers (1 to 255);
%                                  or 256 x 3, where each entry is the RGB for a different color number (0 to 255).                    
%     .imageListTimes           nImage x 2: First column is time in sec at which to show image, 2nd is image number
% 
% Output:
%   
%   report                 Used to return trial timing
%     .stimStartTime           GetSecs() time recorded just before stimulus display begins
%     .stimEndTime             GetSecs() time recorded just after stimulus display ends
%     .totalTime               Time in seconds for stimulus display within inner display loop
%
% As time passes, change the stimulus as appropriate at the right time. Note that in this first
% version, we put the images into textures every time they're used. Much more efficient would be
% to build the images first and save each one to the graphics card ahead of time. Alex suggests
% creating them dynamically in real time using drawing/rescaling routines, that might work but 
% whole images is conceptually easier I think.
%
% BB 2014-05-17, 2014-07-17

% Load all images into the graphics card. 
% NOTE: currently we assume images are grayscale images (or convert them) 
nImage = size(oneStim.images,3);
colorCodes255 = uint8(round(mean(oneStim.colorCodes, 2) * 255)); % Convert real values from 0-1 to 0-255. Colors are changed to grayscale.
%colorCodesReal = mean(oneStim.colorCodes, 2);
for iImage = 1:nImage
    %image2D = colorCodesReal(oneStim.images(:,:,iImage));
    image2D = colorCodes255(oneStim.images(:,:,iImage));     % Convert image from color codes to gray values
    %fprintf('Making %ith texture\n', iImage);
    hTexture(iImage) = Screen('MakeTexture', H.screenWindow, image2D);
end

% Show the stimuli (add moving fixation mark later?)
report.stimStartTime = []; % Will be filled in at first flip
tic
for listEntry = 1:size(oneStim.imageListTimes, 1)        % Show the images in the stimulus
    startTime = oneStim.imageListTimes(listEntry,1);
    texNumber = oneStim.imageListTimes(listEntry,2);
    
    % Wait until the next image's start time
    t = toc;
    while t < startTime
        t = toc;
    end
    
    % It's time to show the next image
    if texNumber > 0
        Screen('DrawTexture', H.screenWindow, hTexture(texNumber));
        DrawFixationMark(A, E, H, 255.0);
        %fprintf('Ready for texture %i (iImage #%i)\n', texNumber, listEntry);
        flipTimestamp = Screen(H.screenWindow, 'Flip');
        if isempty(report.stimStartTime)
            report.stimStartTime = flipTimestamp;
        end
    elseif texNumber == -1 % image number code that terminates the stimulus
        totalTime = toc;
        break                                  % Terminate while loop
    end
end
% Technically, this records the timing of the final texture prior to the
% '-1' termination code, i.e. when the grey screen comes up - NOT the -1
% itself.
report.stimEndTime = flipTimestamp;

for iImage = 1:nImage
    Screen('Close', hTexture(iImage));
end

report.totalTime = totalTime;

end
