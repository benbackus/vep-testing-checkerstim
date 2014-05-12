% Test_BinoChecks.m

imSizePixXY = [800 600]; 
checkSizePix = 10;
deadZonePix = 40;
whichEye = 3;
colors2use = [0 1 2 3 4 5];

checkerImage = binoChecks(imSizePixXY, checkSizePix, deadZonePix, whichEye, colors2use);
imagesc(checkerImage);
axis image