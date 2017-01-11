function design = makeX(params, order)
if nargin==1, makeorder = 1; else makeorder = 0; end

%-----------------------------------------------------------------
% Get a pseudoexponential distribution of ISIs 
%-----------------------------------------------------------------
goodJit=0;
while goodJit==0
    jitters=randsample(params.jitSample,params.ntrials-1,1);
    if mean(jitters) < params.meanISI+params.TReff && mean(jitters) > params.meanISI-params.TReff
       goodJit=1;
    end
end

%-----------------------------------------------------------------
% Determine stimulus onset times
%-----------------------------------------------------------------
onset=zeros(1,params.ntrials);
onset(1)=params.restBegin;
for t=2:params.ntrials,
  onset(t)=onset(t-1) + params.trialDur + jitters(t-1);
end;
jitters(end+1)=params.restEnd;

%-----------------------------------------------------------------
% Make some trial orders
%-----------------------------------------------------------------
if makeorder
    move_on=0;
    while move_on<(params.ntrials-params.maxRep)
        order=zeros(params.ntrials,1);
        orderIDX=randperm(params.ntrials);
        tmp=cumsum(params.trialsPerCond);
        for i=1:params.nconds
            order(orderIDX(1+(tmp(i)-params.trialsPerCond(i)):tmp(i)))=i;
        end;
        for i = 1:(params.ntrials-params.maxRep) 	
            checker=0;
            for r = 1:params.maxRep
                if order(r+i)~=order(i)
                   checker=0; break;
                else
                   checker=checker+1;
                end;
            end;
            if checker==params.maxRep,
               move_on=0;
               break;
            else
               move_on=move_on+1;
            end;
        end
    end
end

%------------------------------------------------------------------------
% Create the design matrix (oversample the HRF depending on effective TR)
%------------------------------------------------------------------------
cond=order;
oversamp_rate=params.TR/params.TReff;
dmlength=params.scan_length*oversamp_rate;
oversamp_onset=(onset/params.TR)*oversamp_rate;
hrf=spm_hrf(params.TReff);  
desmtx=zeros(dmlength,params.nconds);
for c=1:params.nconds
  r=zeros(1,dmlength);
  cond_trials= cond==c;
  cond_ons=fix(oversamp_onset(cond_trials))+1;
  r(cond_ons)=1;
  cr=conv(r,hrf);
  desmtx(:,c)=cr(1:dmlength)';
  onsets{c}=onset(cond==c);  % onsets in actual TR timescale
end;
% sample the design matrix back into TR timescale
desmtx=desmtx(1:oversamp_rate:dmlength,:);

%------------------------------------------------------------------------
% Filter the design matrix
%------------------------------------------------------------------------
K.RT = params.TR;
K.HParam = params.hpf;
K.row = 1:length(desmtx);
K = spm_filter(K);
for c=1:params.nconds
    desmtx(:,c)=spm_filter(K,desmtx(:,c));
end

%------------------------------------------------------------------------
% Save the design matrix
%------------------------------------------------------------------------
design.X = desmtx;
design.combined=zeros(params.ntrials,5);
design.combined(:,1)=1:params.ntrials;
design.combined(:,2)=cond;
design.combined(:,3)=onset;
design.combined(:,4)=repmat(params.trialDur,params.ntrials,1);
design.combined(:,5)=jitters;
design.duration=(params.scan_length*params.TR)/60;
