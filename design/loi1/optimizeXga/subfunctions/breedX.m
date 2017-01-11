function design = breedX(params, order, jitters)
% USAGE: design = breedX(params, order, jitters)
if nargin<3, display('USAGE: design = breedX(params, order, jitters)'), return, end

%-----------------------------------------------------------------
% Determine stimulus onset times
%-----------------------------------------------------------------
onset=zeros(1,params.ntrials);
onset(1)=params.restBegin;
for t=2:params.ntrials,
  onset(t)=onset(t-1) + params.trialDur + jitters(t-1);
end;

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
