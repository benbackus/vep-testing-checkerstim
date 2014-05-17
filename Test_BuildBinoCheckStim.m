% Test_BuildBinoCheckStim.m

A = SetParams_Apparatus();
E = SetParams_Expt_BinoChecks1();
whichEye = 1;

oneStim = BuildBinoCheckStim(A, E, whichEye);
imagesc(oneStim.images(:,:,1));