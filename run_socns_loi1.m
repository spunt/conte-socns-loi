function run_socns_loi1(test_tag)
% RUN_SOCNS_LOI1 - USAGE: run_task([order], [test_tag])
%
if nargin < 1, test_tag = 0; end

%% Check for Psychtoolbox %%
try
    ptbVersion = PsychtoolboxVersion;
catch
    url = 'https://psychtoolbox.org/PsychtoolboxDownload';
    fprintf('\n\t!!! WARNING !!!\n\tPsychophysics Toolbox does not appear to on your search path!\n\tSee: %s\n\n', url);
    return
end

%% Print Title %%
script_name='-- Image Observation Test --'; boxTop(1:length(script_name))='=';
fprintf('\n%s\n%s\n%s\n',boxTop,script_name,boxTop)

%% DEFAULTS %%
defaults = socns_loi1_defaults;
KbName('UnifyKeyNames');
KbQueueRelease();
trigger = KbName(defaults.trigger);
addpath(defaults.path.utilities)

%% Load Design and Setup Seeker Variable %%
load([defaults.path.design filesep 'loi1_design.mat'])
randidx            = randperm(length(alldesign));
designnum          = 1;
design             = alldesign{randidx(1)};
blockSeeker        = design.blockSeeker;
trialSeeker        = design.trialSeeker;
trialSeeker(:,6:9) = 0;
qim                = design.qim;
qdata              = design.qdata;
totalTime          = design.totalTime;
BOA                = diff([blockSeeker(:,3); design.totalTime]);
nTrialsBlock       = length(unique(trialSeeker(:,2)));
eventTimes         = cumsum([defaults.prestartdur; BOA]);
blockSeeker(:,3)   = eventTimes(1:end-1);
numTRs             = ceil(eventTimes(end)/defaults.TR);
totalTime          = defaults.TR*numTRs;

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
logfile=fullfile(defaults.path.data, sprintf('logfile_socns_loi1_sub%s.txt', subjectID));
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
fixTex      = Screen('MakeTexture', w.win, imread([defaults.path.stim filesep 'fixation.jpg']));
reminderTex = Screen('MakeTexture', w.win, imread([defaults.path.stim filesep 'motion_reminder.jpg']));

%% Test Button Box %%
if defaults.testbuttonbox, ptb_bbtester(inputDevice, w.win); end

% ====================
% START TASK
% ====================

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

            %% Wait
            if t==1
                WaitSecs('UntilTime', anchor + blockSeeker(b,3));
            else
                WaitSecs('UntilTime', anchor + offset + defaults.ISI);
            end

            %% Present Photo Stimulus, Prepare Next Stimulus %%
            Screen('Flip',w.win);
            onset = GetSecs; tmpSeeker(t,6) = onset - anchor;
            if t==nTrialsBlock
                Screen('DrawTexture', w.win, fixTex);
            else
                Screen('FillRect', w.win, w.black);
            end
            ShowCursor;

            resp = [];
            if tmpSeeker(t,3)==5
                %% Look for Response %%
                [resp, rt] = ptb_get_resp_windowed_noflip(inputDevice, resp_set, defaults.maxRepDur, defaults.ignoreDur);
                Screen('Flip', w.win);
                WaitSecs(.15);
            else
                resp = ptb_get_resp_windowed_noflip(inputDevice, KbName(defaults.escape), defaults.maxDur);
                if resp
                    ptb_exit; rmpath(defaults.path.utilities)
                    fprintf('\nESCAPE KEY DETECTED\n'); return
                end
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

    ptb_exit;
    rmpath(defaults.path.utilities)
    psychrethrow(psychlasterror);

end;

%% Results Structure %%
result.blockSeeker = blockSeeker;
result.trialSeeker = trialSeeker;
result.qim = qim;
result.qdata = qdata;

%% Save Data to Matlab Variable %%
d=clock;
outfile=sprintf('socns_loi1_%s_design%d_%s_%02.0f-%02.0f.mat',subjectID,designnum,date,d(4),d(5));
try
    save([defaults.path.data filesep outfile], 'subjectID', 'result', 'slideName', 'defaults');
catch
	fprintf('couldn''t save %s\n saving to socns_loi1.mat\n',outfile);
	save socns_loi1.mat
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
        emailsubject = '[TEST RUN] Conte Social/Nonsocial LOI1 Behavioral Data';
    else
        emailto = {'bobspunt@gmail.com','conte3@caltech.edu'};
        emailsubject = 'Conte Social/Nonsocial LOI1 Behavioral Data';
    end
    emailbackup(emailto, emailsubject, 'See attached.', [defaults.path.data filesep outfile]);
    disp('All done!');
catch lasterr
    disp('Could not email data... internet may not be connected.');
    rethrow(lasterr)
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



