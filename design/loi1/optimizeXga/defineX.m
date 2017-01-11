
%% Pulse Sequence Parameters %%
Xparams.TR = 1;
Xparams.nslices = 56;

%% Design Parameters %%
Xparams.nconds=4;                       % number of conditions
Xparams.trialsPerCond=[6 6 6 6];     % number of trials in each condition (length must much nconds)
Xparams.maxRep=1;                       % maximum number of repeat trials from same condition
Xparams.trialDur=12.6;               % trial length (in seconds)
Xparams.minISI=2;               % mininimum interstimulus interval (in seconds)
Xparams.maxISI=8;               % maximum interstimulus interval (in seconds)
Xparams.meanISI=4;              % desired mean interstimulus interval (in seconds)
Xparams.restBegin=6;            % amount of rest to add in beginning of scan (in seconds)
Xparams.restEnd=8;             % amount of rest to add at end of scan (in seconds)

%% Analysis Parameters %%
Xparams.hpf = 100;

%% Derive Some Additional Parameters %%
Xparams.ntrials=sum(Xparams.trialsPerCond);  % computes total number of trials
Xparams.scan_length=ceil((Xparams.restBegin + Xparams.restEnd + Xparams.ntrials*(Xparams.meanISI+Xparams.trialDur))/Xparams.TR);  % computes total scan length (in TRs)
Xparams.TReff=Xparams.TR/Xparams.nslices;            % computes effective TR

%% Get a pseudoexponential distribution of ISIs %%
minISI = Xparams.minISI;
maxISI = Xparams.maxISI;
meanISI = Xparams.meanISI;
TReff = Xparams.TReff;
ntrials = Xparams.ntrials;
f1 = 0:20; % adjust this to adjust the number of different distributions to test
f2 = 0:20;
factor2 = repmat(f2, 1, length(f1))';
factor1 = repmat(f1,length(f2),1);
factor1 = reshape(factor1,numel(factor1),1);
factors = [factor1 factor2];
jitSample = cell(length(factors),1);
bs1 = minISI:TReff:maxISI;
bs2 = minISI:TReff:meanISI;
bs3 = meanISI:TReff:meanISI+1;
for s = 1:length(factor1)
    
    bs4 = repmat(bs2,1,factors(s,1));
    bs5 = repmat(bs3,1,factors(s,2));
    jitSample{s} = [bs1 bs4 bs5];
    ct = [];
    for i = 1:20
        tic
        goodJit=0;
        while goodJit==0
            jitters=randsample(jitSample{s},ntrials-1,1);
            if mean(jitters) < meanISI+TReff && mean(jitters) > meanISI-TReff
               goodJit=1;
            end
            if toc>.01
                goodJit=1;
            end
        end
        ct(i) = toc;
    end
    sampletimes(s) = nanmedian(ct);
end

minIDX = find(sampletimes==min(sampletimes));
if length(minIDX)>1, minIDX = minIDX(1); end
Xparams.jitSample = jitSample{minIDX}; % save the fastest sample of jitters
save params.mat Xparams % save the Xparams variable