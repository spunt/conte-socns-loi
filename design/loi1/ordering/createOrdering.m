

% DATA KEY
% 1 - condition
% 2 - answer
% 3 - valence
% 4 - luminance
% 5 - hue 
% 6 - saturation
% 7 - value

%% SEEKER column key %%
% 1 - trial #
% 2 - condition (1=FACE, 2=HAND, 3=SCRAMBLE, 4=REPEAT)
% 3 - stimulus IDX (corresponds to order in stimulus directory)
% 4 - stimulus VALENCE (from MTurk normative data) [NaN for ps]
% 5 - stimulus LUMINANCE (from bob_rgb2lum) [NaN for ps]
% 6 - scheduled stimulus onset
% 7 - actual stimulus onset
% 8 - response (0 = No Response, 1 = Response)
% 9 - if response, response time (s)

clear all
taskdir = '/Users/bobspunt/Desktop/Dropbox/Bob/Research/Caltech/PEERS/tasks';
stimdir = [taskdir filesep 'stimuli/loi1'];
load contedesign.mat
designdir = [taskdir filesep 'design'];
[~,stimname] = files([stimdir filesep 'ps*jpg']);
design = load('design1.txt');
loi2 = load([designdir filesep 'design.mat']);
load([designdir filesep 'all_question_data.mat']);
qim2 = [repmat({'Scramble'}, length(stimname), 1) stimname];
qim = [qim; qim2];
qimidx = loi2.trialSeeker(loi2.trialSeeker(:,3) < 4,5);
qimidx = reshape(qimidx, 9, 18); 
psidx = cellstrfind(qim(:,1), 'Scramble');
psidx = psidx(randperm(length(psidx))); 
psidx = reshape(psidx, 9, 6); 
qimidx = [qimidx psidx];
qdata(qdata(:,1) > 3,1) = NaN;
qdata(end+1:end+length(stimname),:) = 4;
qdata(qdata(:,2)==4,2) = NaN; 
blockSeeker = design(:,1:3);
trialSeeker = zeros(24*9, 5);
tmp = repmat(1:24, 9, 1);
trialSeeker(:,1) = tmp(:); 
trialSeeker(:,2) = repmat(1:9, 1, 24);
tmp = repmat(blockSeeker(:,2), 1, 9)';
trialSeeker(:,3) = tmp(:); 


for i = 1:3
    
    newseekidx = find(trialSeeker(:,3)==i);
    oldseekidx = find(loi2.trialSeeker(:,3)==i);
    oldseek = loi2.trialSeeker(oldseekidx,:);
    oldseek = reshape(oldseek(:,5), 9, 6);
    for i = 1:size(oldseek, 2)
        oldseek(:,i) = oldseek(randperm(9), i); 
    end
    trialSeeker(newseekidx,5) = oldseek(:);
    trialSeeker(newseekidx,4) = qdata(oldseek(:),2);
    
end
newseekidx = find(trialSeeker(:,3)==4);
trialSeeker(newseekidx,5) = psidx(:);
trialSeeker(newseekidx,4) = qdata(psidx(:),2);

restBegin = 5; 
% add repeats
nreps = 2;
idx = [10 36 142 193];
tmp = [(1:length(trialSeeker))' trialSeeker];
new = [];
for i = 1:length(idx)
    if i==1, p1 = 1; else p1 = idx(i-1)+1; end
    tidx = find(tmp(:,1)==idx(i)); 
    t = tmp(tidx,:);
    t(4) = 5; 
    sect = [tmp(p1:tidx,:); t];
    new = [new; sect];
end
sect = tmp(idx(end)+1:end,:); 
new = [new; sect];
t = new(new(:,4)==5,2);
ons = blockSeeker(:,3);
soa = diff(ons);
tmp = blockSeeker; 
soa(t) = soa(t)+1;
soa = soa*.95;

tmp(1,3) = restBegin; 
tmp(2:end,3) = cumsum(soa) + restBegin;
blockSeeker = tmp; 
totalTime = floor(blockSeeker(end,3) + max(diff(blockSeeker(:,3))));
trialSeeker = new; 
design.totalTime = totalTime; 
design.trialSeeker = trialSeeker;
design.blockSeeker = blockSeeker; 
design.qim = qim; 
design.qdata = qdata; 
alldesign{1} = design;
save loi1_design.mat alldesign



