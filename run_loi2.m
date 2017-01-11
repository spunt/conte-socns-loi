function run_loi2(test_tag)
% RUN_TEST  Run Why/How Social/Nonsocial
%  
%   USAGE: run_loi2([test_tag])
%
% Copyright (C) 2014  Bob Spunt, Ph.D.
if nargin<2, test_tag = 0; end

%% Check for Psychtoolbox %%
try
    ptbVersion = PsychtoolboxVersion;
catch
    url = 'https://github.com/Psychtoolbox-3/Psychtoolbox-3';
    fprintf('Psychophysics Toolbox may not be installed or in your search path.\nSee: %s\n', url);
end

%% Print Title %%
script_name='--------- Photo Judgment Test ---------'; boxTop(1:length(script_name))='=';
fprintf('\n%s\n%s\n%s\n',boxTop,script_name,boxTop)

%% DEFAULTS %%
defaults = loi2_defaults; 
trigger = KbName(defaults.trigger);
addpath(defaults.path.utilities)

%% Load Design and Setup Seeker Variable %%
design = load([defaults.path.design filesep 'design.mat']); 
load([defaults.path.design filesep 'all_question_data.mat'])
load([defaults.path.design filesep 'add_ordered_qvalence.mat'])
blockSeeker = design.blockSeeker;
trialSeeker = design.trialSeeker;
preblockcues = design.preblockcues; 
ordered_questions = preblockcues(blockSeeker(:,4));
firstclause = {'Is the person ' 'Is the photo ' 'Is it a result of ' 'Is it going to result in '};
pbc1 = preblockcues;
pbc2 = pbc1; 
for i = 1:length(firstclause)
    
    tmpidx = ~isnan(cellfun(@mean, regexp(preblockcues, firstclause{i})));
    pbc1(tmpidx) = cellstr(firstclause{i}(1:end-1));
    pbc2 = regexprep(pbc2, firstclause{i}, '');

end

nTrialsBlock = length(unique(trialSeeker(:,2)));
trialSeeker(:,6:9) = 0;
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
logfile=fullfile(defaults.path.data, sprintf('logfile_explicit_socnsloi_sub%s.txt', subjectID));
fprintf('\nA running log of this session will be saved to %s\n',logfile);
fid=fopen(logfile,'a');
if fid<1,error('could not open logfile!');end;
fprintf(fid,'Started: %s %2.0f:%02.0f\n',date,d(4),d(5));

%% Make Images Into Textures %%
DrawFormattedText(w.win,sprintf('LOADING\n\n0%% complete'),'center','center',w.white,defaults.font.wrap);
Screen('Flip',w.win);
slideName = cell(length(qim));
slideTex = slideName; 
for i = 1:length(qim)
    slideName{i} = qim{i,2};
    tmp1 = imread([defaults.path.stim filesep 'loi2' filesep slideName{i}]);
    tmp2 = tmp1;
    slideTex{i} = Screen('MakeTexture',w.win,tmp2);
    DrawFormattedText(w.win,sprintf('LOADING\n\n%d%% complete', ceil(100*i/length(qim))),'center','center',w.white,defaults.font.wrap);
    Screen('Flip',w.win);
end;
instructTex = Screen('MakeTexture', w.win, imread([defaults.path.stim filesep 'loi2_instruction.jpg']));
fixTex = Screen('MakeTexture', w.win, imread([defaults.path.stim filesep 'fixation.jpg']));

%% Get Coordinates for Centering ISI Cues
isicues_xpos = zeros(length(design.isicues),1);
isicues_ypos = isicues_xpos; 
for q = 1:length(design.isicues)
    [isicues_xpos(q), isicues_ypos(q)] = ptb_center_position(design.isicues{q},w.win);
end

%==========================================================================
%
% START TASK PRESENTATION
% 
%==========================================================================

%% Present Instruction Screen %%
Screen('DrawTexture',w.win, instructTex); Screen('Flip',w.win);

%% Wait for Trigger to Begin %%
DisableKeysForKbCheck([]);
secs=KbTriggerWait(trigger,inputDevice);	
anchor=secs;	

try

    if test_tag, nBlocks = 1; totalTime = 25; % for test run
    else nBlocks = length(blockSeeker); end
    %======================================================================
    % BEGIN BLOCK LOOP
    %======================================================================
    for b = 1:nBlocks 

        %% Present Fixation Screen %%
        Screen('DrawTexture',w.win, fixTex); Screen('Flip',w.win);

        %% Get Data for This Block %%
        tmpSeeker = trialSeeker(trialSeeker(:,1)==b,:);
        pbcue1 = pbc1{blockSeeker(b,4)}; 
        pbcue2 = pbc2{blockSeeker(b,4)}; % preblock question stimulus
        isicue = design.isicues{blockSeeker(b,4)}; % isi stimulus
        isicue_x = isicues_xpos(blockSeeker(b,4));
        isicue_y = isicues_ypos(blockSeeker(b,4));

        %% Prepare Question Cue Screen While Waiting %%
        Screen('TextSize',w.win,defaults.font.size1); Screen('TextStyle',w.win,0);
        DrawFormattedText(w.win,[pbcue1 '\n\n\n'],'center','center',w.white,defaults.font.wrap);
        Screen('TextStyle',w.win,1); Screen('TextSize',w.win,defaults.font.size2);
        DrawFormattedText(w.win,pbcue2,'center','center',w.white,defaults.font.wrap);

        %% Present Question Screen and Prepare First ISI (Blank) Screen %%
        WaitSecs('UntilTime',anchor + blockSeeker(b,3)); Screen('Flip', w.win);
        Screen('FillRect', w.win, w.black);

        %% Present Blank Screen Prior to First Trial %%
        WaitSecs('UntilTime',anchor + blockSeeker(b,3) + defaults.cueDur); Screen('Flip', w.win);
        
        %==================================================================
        % BEGIN TRIAL LOOP
        %==================================================================
        for t = 1:nTrialsBlock 

            %% Prepare Screen for Current Trial %%
            Screen('DrawTexture',w.win,slideTex{tmpSeeker(t,5)})
            
            %% Check for Escape Key
            if t==1
                winopp = (anchor + blockSeeker(b,3) + defaults.cueDur + defaults.firstISI*.99) - GetSecs; 
            else
                winopp = (anchor + offset_dur + defaults.ISI*.99) - GetSecs; 
            end
            doquit = ptb_get_force_quit(inputDevice, KbName(defaults.escape), winopp);
            if doquit
                sca; rmpath(defaults.path.utilities)
                fprintf('\nESCAPE KEY DETECTED\n'); return
            end
            
            %% Present Screen for Current Trial & Prepare ISI Screen %%
            Screen('Flip',w.win);
            onset = GetSecs; tmpSeeker(t,6) = onset - anchor;
            if t==nTrialsBlock % present fixation after last trial of block
                Screen('DrawTexture', w.win, fixTex);
            else % present question reminder screen between every block trial
                Screen('DrawText', w.win, isicue, isicue_x, isicue_y);
            end
            WaitSecs(.20) % Ignore unreasonably fast button presses

            %% Look for Button Press %%
            resp = [];
            [resp, rt] = ptb_get_resp_windowed_noflip(inputDevice, resp_set, defaults.maxDur);
            offset_dur = GetSecs - anchor;

            %% Present ISI, and Look a Little Longer for a Response if None Was Registered %%
            Screen('Flip', w.win);
            isiflag = isempty(resp);
            if isiflag, [resp, rt] = ptb_get_resp_windowed_noflip(inputDevice, resp_set, .20); end
            if ~isempty(resp)
                tmpSeeker(t,8) = str2num(resp(1));
                tmpSeeker(t,7) = rt + (defaults.maxDur*isiflag);
            end
            tmpSeeker(t,9) = offset_dur;

        end % END TRIAL LOOP

        %% Store Block Data & Print to Logfile %%
        trialSeeker(trialSeeker(:,1)==b,:) = tmpSeeker;
        for t = 1:size(tmpSeeker,1), fprintf(fid,[repmat('%d\t',1,size(tmpSeeker,2)) '\n'],tmpSeeker(t,:)); end
        

    end % END BLOCK LOOP
    
    %% Present Fixation Screen Until End of Scan %%
    WaitSecs('UntilTime', anchor + totalTime);

catch
    
    sca; rmpath(defaults.path.utilities)
    psychrethrow(psychlasterror);
    
end;

%% End of Test Screren %%
DrawFormattedText(w.win,'TEST COMPLETE\n\nPress any key to exit.','center','center',w.white,defaults.font.wrap);
Screen('Flip', w.win); 
KbWait; 

%% Create Results Structure %%
result.blockSeeker = blockSeeker; 
result.trialSeeker = trialSeeker;
result.qim = qim;
result.preblockcues = preblockcues; 
result.isicues = design.isicues; 

%% Save Data to Matlab Variable %%
d=clock;
outfile=sprintf('explicit_socnsloi_%s_%s_%02.0f-%02.0f.mat',subjectID,date,d(4),d(5));
try
    save([defaults.path.data filesep outfile], 'subjectID', 'result', 'slideName', 'defaults'); 
catch
	fprintf('couldn''t save %s\n saving to explicit_socnsloi.mat\n',outfile);
	save explicit_socnsloi.mat
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

end
