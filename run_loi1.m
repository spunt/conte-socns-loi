function run_loi1(test_tag)
if nargin < 1, test_tag = 0; end

%% Check for Psychtoolbox %%
try
    ptbVersion = PsychtoolboxVersion;
catch
    url = 'https://github.com/Psychtoolbox-3/Psychtoolbox-3';
    fprintf('Psychophysics Toolbox may not be installed or in your search path.\nSee: %s\n', url);
end

%% Print Title %%
script_name='-- Image Observation Test --'; boxTop(1:length(script_name))='=';
fprintf('\n%s\n%s\n%s\n',boxTop,script_name,boxTop)

%% DEFAULTS %%
defaults = loi1_defaults; 
trigger = KbName(defaults.trigger);
addpath(defaults.path.utilities)

%% Load Design and Setup Seeker Variable %%
load([defaults.path.design filesep 'loi1_design.mat'])
randidx = randperm(length(alldesign));
designnum = randidx(1);
design = alldesign{randidx(1)};
blockSeeker = design.blockSeeker;
trialSeeker = design.trialSeeker;
trialSeeker(:,6:9) = 0;
qim = design.qim;
qdata = design.qdata;
totalTime = design.totalTime;

%% Print Defaults %%
fprintf('Test Duration:         %d seconds', totalTime);
fprintf('\nTrigger Key:           %s', defaults.trigger);
fprintf(['\nValid Response Keys:   %s' repmat(', %s', 1, length(defaults.valid_keys)-1)], defaults.valid_keys{:});
fprintf('\nForce Quit Key:        %s\n', defaults.escape);
fprintf('%s\n', repmat('-', 1, length(script_name)));

%% Get Subject ID %%
if ~test_tag
    subjectID = ptb_get_input_string('\nEnter Subject ID: ');
else
    subjectID = 'TEST';
end

%% Setup Input Device(s) %%
switch upper(computer)
  case 'MACI64'
    inputDevice = ptb_get_resp_device;
  case {'PCWIN','PCWIN64'}
    % JMT:
    % Do nothing for now - return empty chosen_device
    % Windows XP merges keyboard input and will process external keyboards
    % such as the Silver Box correctly
    inputDevice = [];
  otherwise
    % Do nothing - return empty chosen_device
    inputDevice = [];
end
resp_set = ptb_response_set(defaults.valid_keys); % response set

%% Initialize Screen %%
ss = get(0, 'Screensize');
ss = ss(3:4);
if ss(1)/ss(2)==2560/1440, defaults.screenres = ss; end
try
    w = ptb_setup_screen(0,250,defaults.font.name,defaults.font.size1, defaults.screenres); % setup screen
catch
    disp('Could not change to recommend screen resolution. Using current.');
    w = ptb_setup_screen(0,250,defaults.font.name,defaults.font.size1);
end


%% Initialize Logfile (Trialwise Data Recording) %%
d=clock;
logfile=fullfile(defaults.path.data, sprintf('logfile_implicit_socnsloi_sub%s.txt', subjectID));
fprintf('\nA running log of this session will be saved to %s\n',logfile);
fid=fopen(logfile,'a');
if fid<1,error('could not open logfile!');end;
fprintf(fid,'Started: %s %2.0f:%02.0f\n',date,d(4),d(5));

% blockSeeker
% -------------
% 1 - block #
% 2 - condition (1=EH,2=AH,3=EL,4=AL)
% 3 - onset (s)
% 4 - cue # (corresponds to variables preblockcues & isicues, which are
% cell arrays containing the filenames for the cue screens contained in the
% folder "questions")

% trialSeeker
% -------------
% 1 - block #
% 2 - trial #
% 2 - condition (1=FH,2=AH,3=FL,4=AL)
% 4 - normative response (1=Yes, 2=No)
% 5 - stimulus # (corresponds to order in qim+qdata)
% 6 - actual onset
% 7 - response time (s) [0 if NR]
% 8 - actual response [0 if NR]
% 9 - actual offset

%% Make Images Into Textures %%
DrawFormattedText(w.win,sprintf('LOADING\n\n0%% complete'),'center','center',w.white,42);
Screen('Flip',w.win);
stimdir = [defaults.path.stim filesep 'loi1'];
stimidx = trialSeeker(:,5);
slideName = cell(size(qim,1),1); slideTex= slideName; 
for i = 1:length(stimidx)
    slideName{stimidx(i)} = qim{stimidx(i),2};
    tmp1 = imread([stimdir filesep slideName{stimidx(i)}]);
    tmp2 = tmp1;
    slideTex{stimidx(i)} = Screen('MakeTexture',w.win,tmp2);
    DrawFormattedText(w.win,sprintf('LOADING\n\n%d%% complete', ceil(100*i/length(stimidx))),'center','center',w.white,42);
    Screen('Flip',w.win);
end;
instructTex = Screen('MakeTexture', w.win, imread([defaults.path.stim filesep 'loi1_instruction.jpg']));
fixTex = Screen('MakeTexture', w.win, imread([defaults.path.stim filesep 'fixation.jpg']));
% 
% %% Test Button Box %%
% bbtester(inputDevice,w.win)

% ====================
% START TASK
% ====================

%% Present Instruction Screen %%
Screen('DrawTexture',w.win, instructTex); Screen('Flip',w.win);

%% Wait for Trigger to Begin %%
DisableKeysForKbCheck([]);
secs=KbTriggerWait(trigger,inputDevice);	
anchor=secs;	

try

if test_tag, nBlocks = 1; totalTime = 15; % for test run
else nBlocks = length(blockSeeker); end

for b = 1:nBlocks
    
    %% Present Fixation %%
    Screen('DrawTexture',w.win, fixTex); Screen('Flip',w.win);
    
    %% Grab Data for Current Block %%
    tmpSeeker = trialSeeker(trialSeeker(:,1)==b,:);
    nTrialsBlock = length(tmpSeeker(:,1));
    offset = 0; 
    
    for t = 1:nTrialsBlock
        
        %% Prep Trial Stim %%
        Screen('DrawTexture',w.win,slideTex{tmpSeeker(t,5)});
        
        %% Check for Escape Key
        if t==1
            winopp = (anchor + blockSeeker(b,3)*.99) - GetSecs; 
        else
            winopp = (anchor + offset + defaults.ISI*.99) - GetSecs; 
        end
        doquit = ptb_get_force_quit(inputDevice, KbName(defaults.escape), winopp);
        if doquit
            sca; rmpath(defaults.path.utilities)
            fprintf('\nESCAPE KEY DETECTED\n'); return
        end
        
        %% Present Photo Stimulus, Prepare Next Stimulus %%
        Screen('Flip',w.win);
        onset = GetSecs; tmpSeeker(t,6) = onset - anchor;
        if t==nTrialsBlock
            Screen('DrawTexture', w.win, fixTex);
        else
            Screen('FillRect', w.win, w.black);
        end
        
        resp = [];
        if tmpSeeker(t,3)==5
            %% Look for Response %%
            resp = [];
            [resp, rt] = ptb_get_resp_windowed_noflip(inputDevice, resp_set, defaults.maxRepDur);
            Screen('Flip', w.win);
            WaitSecs(.10);
        else
            WaitSecs('UntilTime',anchor + (onset-anchor) + defaults.maxDur);
            Screen('Flip', w.win);
        end
        offset = GetSecs - anchor;
        if ~isempty(resp)
            tmpSeeker(t,8) = str2num(resp(1));
            tmpSeeker(t,7) = rt;
        end
        tmpSeeker(t,9) = offset;

        
    end % TRIAL LOOP

    %% Store Block Data & Print to Logfile
    trialSeeker(trialSeeker(:,1)==b,:) = tmpSeeker;
    for t = 1:size(tmpSeeker,1), fprintf(fid,[repmat('%d\t',1,size(tmpSeeker,2)) '\n'],tmpSeeker(t,:)); end

end % BLOCK LOOP

    WaitSecs('UntilTime', anchor + totalTime);

catch
    
    Screen('CloseAll');
    Priority(0);
    psychrethrow(psychlasterror);
    rmpath(utilitydir)
    
end;

%% Results Structure %%
result.blockSeeker = blockSeeker; 
result.trialSeeker = trialSeeker;
result.qim = qim;
result.qdata = qdata;

%% Save Data to Matlab Variable %%
d=clock;
outfile=sprintf('implicit_socnsloi_%s_design%d_%s_%02.0f-%02.0f.mat',subjectID,designnum,date,d(4),d(5));
try
    save([datadir filesep outfile], 'subjectID', 'result', 'slideName', 'defaults'); 
catch
	fprintf('couldn''t save %s\n saving to implicit_socnsloi.mat\n',outfile);
	save implicit_socnsloi.mat
end;

%% Exit %%
sca; 
try
    disp('Backing up data... please wait.');
    bob_sendemail({'bobspunt@gmail.com'},'peers asd loi behavioral data','see attached', [datadir filesep outfile]);
    disp('All done!');
catch
    disp('Could not email data... internet may not be connected.');
end
rmpath(defaults.path.utilities)

