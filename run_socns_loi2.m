function run_socns_loi2(test_tag)
% RUN_SOCNS_LOI2  Run Why/How Social/Nonsocial
%
%   USAGE: run_loi2([test_tag])
%
% Copyright (C) 2014  Bob Spunt, Ph.D.
if nargin<1, test_tag = 0; end

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
defaults = socns_loi2_defaults;
KbName('UnifyKeyNames');
KbQueueRelease();
trigger = KbName(defaults.trigger);
addpath(defaults.path.utilities)

%% Load Design and Setup Seeker Variable %%
load([defaults.path.design filesep 'design.mat'])
design = alldesign{1};
blockSeeker = design.blockSeeker;
trialSeeker = design.trialSeeker;
trialSeeker(:,6:9) = 0;
nTrialsBlock = length(unique(trialSeeker(:,2)));
BOA  = diff([blockSeeker(:,3); design.totalTime]);
maxBlockDur = defaults.cueDur + defaults.firstISI + (nTrialsBlock*defaults.maxDur) + (nTrialsBlock-1)*defaults.ISI;
BOA   = BOA + (maxBlockDur - min(BOA));
eventTimes          = cumsum([defaults.prestartdur; BOA]);
blockSeeker(:,3)    = eventTimes(1:end-1);
numTRs              = ceil(eventTimes(end)/defaults.TR);
totalTime           = defaults.TR*numTRs;

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
resp_set = ptb_response_set([defaults.valid_keys defaults.escape]); % response set

%% Initialize Screen %%
try
    w = ptb_setup_screen(0,250,defaults.font.name,defaults.font.size1, defaults.screenres); % setup screen
catch
    disp('Could not change to recommend screen resolution. Using current.');
    w = ptb_setup_screen(0,250,defaults.font.name,defaults.font.size1);
end

%% Initialize Logfile (Trialwise Data Recording) %%
d=clock;
logfile=fullfile(defaults.path.data, sprintf('logfile_socns_loi2_sub%s.txt', subjectID));
fprintf('\nA running log of this session will be saved to %s\n',logfile);
fid=fopen(logfile,'a');
if fid<1,error('could not open logfile!');end;
fprintf(fid,'Started: %s %2.0f:%02.0f\n',date,d(4),d(5));

%% Make Images Into Textures %%
DrawFormattedText(w.win,sprintf('LOADING\n\n0%% complete'),'center','center',w.white,defaults.font.wrap);
Screen('Flip',w.win);
slideName = cell(length(design.qim), 1);
slideTex = slideName;
for i = 1:length(design.qim)
    slideName{i} = design.qim{i,2};
    tmp1 = imread([defaults.path.stim filesep 'loi2' filesep slideName{i}]);
    slideTex{i} = Screen('MakeTexture',w.win,tmp1);
    DrawFormattedText(w.win,sprintf('LOADING\n\n%d%% complete', ceil(100*i/length(design.qim))),'center','center',w.white,defaults.font.wrap);
    Screen('Flip',w.win);
end;
instructTex = Screen('MakeTexture', w.win, imread([defaults.path.stim filesep 'loi2_instruction.jpg']));
fixTex = Screen('MakeTexture', w.win, imread([defaults.path.stim filesep 'fixation.jpg']));
reminderTex = Screen('MakeTexture', w.win, imread([defaults.path.stim filesep 'motion_reminder.jpg']));

%% Get Cues %%
ordered_questions  = design.preblockcues(blockSeeker(:,4));
firstclause = {'Is the person ' 'Is the photo ' 'Is it a result of ' 'Is it going to result in '};
pbc1 = design.preblockcues;
pbc2 = pbc1;
for i = 1:length(firstclause)
    tmpidx = ~isnan(cellfun(@mean, regexp(design.preblockcues, firstclause{i})));
    pbc1(tmpidx) = cellstr(firstclause{i}(1:end-1));
    pbc2 = regexprep(pbc2, firstclause{i}, '');
end
pbc1 = strcat(pbc1, repmat('\n', 1, defaults.font.linesep));

%% Get Coordinates for Centering ISI Cues
isicues_xpos = zeros(length(design.isicues),1);
isicues_ypos = isicues_xpos;
for q = 1:length(design.isicues), [isicues_xpos(q), isicues_ypos(q)] = ptb_center_position(design.isicues{q},w.win); end

%% Test Button Box %%
if defaults.testbuttonbox, ptb_bbtester(inputDevice, w.win); end

%==========================================================================
%
% START TASK PRESENTATION
%
%==========================================================================

%% Present Instruction Screen %%
Screen('DrawTexture',w.win, instructTex); Screen('Flip',w.win);

%% Wait for Trigger to Start %%
DisableKeysForKbCheck([]);
secs=KbTriggerWait(trigger, inputDevice);
anchor=secs;
% RestrictKeysForKbCheck([resp_set defaults.escape]);

%% Present Motion Reminder %%
if defaults.motionreminder
    Screen('DrawTexture',w.win,reminderTex)
    Screen('Flip',w.win);
    WaitSecs('UntilTime', anchor + blockSeeker(1,3) - 2);
end

try

    if test_tag, nBlocks = 1; totalTime = ceil(totalTime/(size(blockSeeker, 1))); % for test run
    else nBlocks = length(blockSeeker); end
    %======================================================================
    % BEGIN BLOCK LOOP
    %======================================================================
    for b = 1:nBlocks

        %% Present Fixation Screen %%
        Screen('DrawTexture',w.win, fixTex); Screen('Flip',w.win);

        %% Get Data for This Block (While Waiting for Block Onset) %%
        tmpSeeker   = trialSeeker(trialSeeker(:,1)==b,:);
        line1       = pbc1{blockSeeker(b,4)};  % line 1 of question cue
        pbcue       = pbc2{blockSeeker(b,4)};  % line 2 of question cue
        isicue      = design.isicues{blockSeeker(b,4)};  % isi cue
        isicue_x    = isicues_xpos(blockSeeker(b,4));  % isi cue x position
        isicue_y    = isicues_ypos(blockSeeker(b,4));  % isi cue y position

        %% Prepare Question Cue Screen (Still Waiting) %%
        Screen('TextSize',w.win, defaults.font.size1); Screen('TextStyle', w.win, 0);
        DrawFormattedText(w.win,line1,'center','center',w.white, defaults.font.wrap);
        Screen('TextStyle',w.win, 1); Screen('TextSize', w.win, defaults.font.size2);
        DrawFormattedText(w.win,pbcue,'center','center', w.white, defaults.font.wrap);

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
            if t==1, WaitSecs('UntilTime',anchor + blockSeeker(b,3) + defaults.cueDur + defaults.firstISI);
            else WaitSecs('UntilTime',anchor + offset_dur + defaults.ISI); end

            %% Present Screen for Current Trial & Prepare ISI Screen %%
            Screen('Flip',w.win);
            onset = GetSecs; tmpSeeker(t,6) = onset - anchor;
            if t==nTrialsBlock % present fixation after last trial of block
                Screen('DrawTexture', w.win, fixTex);
            else % present question reminder screen between every block trial
                Screen('DrawText', w.win, isicue, isicue_x, isicue_y);
            end

            %% Look for Button Press %%
            [resp, rt] = ptb_get_resp_windowed_noflip(inputDevice, resp_set, defaults.maxDur, defaults.ignoreDur);
            offset_dur = GetSecs - anchor;

           %% Present ISI, and Look a Little Longer for a Response if None Was Registered %%
            Screen('Flip', w.win);
            norespyet = isempty(resp);
            if norespyet, [resp, rt] = ptb_get_resp_windowed_noflip(inputDevice, resp_set, defaults.ISI*0.90); end
            if ~isempty(resp)
                if strcmpi(resp, defaults.escape)
                    ptb_exit; rmpath(defaults.path.utilities)
                    fprintf('\nESCAPE KEY DETECTED\n'); return
                end
                tmpSeeker(t,8) = find(strcmpi(KbName(resp_set), resp));
                tmpSeeker(t,7) = rt + (defaults.maxDur*norespyet);
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

    ptb_exit;
    rmpath(defaults.path.utilities);
    psychrethrow(psychlasterror);

end;

%% Create Results Structure %%
result.blockSeeker  = blockSeeker;
result.trialSeeker  = trialSeeker;
result.qim          = design.qim;
result.qdata        = design.qdata;
result.preblockcues = design.preblockcues;
result.isicues      = design.isicues;

%% Save Data to Matlab Variable %%
d=clock;
outfile=sprintf('socns_loi2_%s_%s_%02.0f-%02.0f.mat',subjectID,date,d(4),d(5));
try
    save([defaults.path.data filesep outfile], 'subjectID', 'result', 'slideName', 'defaults');
catch
	fprintf('couldn''t save %s\n saving to socns_loi2.mat\n',outfile);
	save socns_loi2.mat
end;

%% End of Test Screen %%
DrawFormattedText(w.win,'TEST COMPLETE\n\nPlease wait for further instructions.','center','center',w.white,defaults.font.wrap);
Screen('Flip', w.win);
ptb_any_key;

%% Exit & Attempt Backup %%
ptb_exit;
try
    disp('Backing up data... please wait.');
    if test_tag
        emailto = {'bobspunt@gmail.com'};
        emailsubject = '[TEST RUN] Conte Social/Nonsocial LOI2 Behavioral Data';
    else
        emailto = {'bobspunt@gmail.com','conte3@caltech.edu'};
        emailsubject = 'Conte Social/Nonsocial LOI2 Behavioral Data';
    end
    emailbackup(emailto, emailsubject, 'See attached.', [defaults.path.data filesep outfile]);
    disp('All done!');
catch
    disp('Could not email data... internet may not be connected.');
end
rmpath(defaults.path.utilities)
end
function emailbackup(to,subject,message,attachment)

if nargin == 3, attachment = ''; end

% set up gmail SMTP service
setpref('Internet','E_mail','neurospunt@gmail.com');
setpref('Internet','SMTP_Server','smtp.gmail.com');
setpref('Internet','SMTP_Username','neurospunt@gmail.com');
setpref('Internet','SMTP_Password','socialbrain');

% gmail server
props = java.lang.System.getProperties;
props.setProperty('mail.smtp.auth','true');
props.setProperty('mail.smtp.socketFactory.class', 'javax.net.ssl.SSLSocketFactory');
props.setProperty('mail.smtp.socketFactory.port','465');

% send
if isempty(attachment)
    sendmail(to,subject,message);
else
    sendmail(to,subject,message,attachment)
end

end
