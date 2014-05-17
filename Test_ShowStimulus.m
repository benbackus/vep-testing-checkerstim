% Test_ShowStimulus.m

A = SetParams_Apparatus();
E = SetParams_Expt_BinoChecks1();
whichEye = 1;

oneStim = BuildBinoCheckStim(E, A, whichEye);

Screen('Preference', 'SkipSyncTests', 1);
whichScreen = 1;
H.screenWindow = Screen(whichScreen, 'OpenWindow')
    
report = ShowStimulus(A, E, H, oneStim);

Screen('CloseAll');
    
