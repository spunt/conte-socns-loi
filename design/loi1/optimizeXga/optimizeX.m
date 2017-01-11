
clear all; home; addpath('subfunctions')

%% User Settings %%
paramfile='params.mat'; % file containing Xparams
keep=20; % number of designs to save
% conditions. 1: Face, 2: Hand, 3: Nonsocial, 4: Scramble
L = [1 0 0 -1; ...
     0 1 0 -1; ...
     1 0 -1 0; ...
     0 1 -1 0]; % contrasts of interest (rows are contrast vectors)
conWeights=[.75 .75 1 1]; % how to weight each contrast in overall efficiency estimation?
gensize = 1000; % generation size
ngen = 100; % maximum number of generations to run
maxtime = 20; % maximum time (in minutes)

%% Derive Some Settings %%
nalpha = round(gensize*.01);
halfgen = gensize/2;
quartgen = gensize/4;
threequartgen = halfgen + quartgen;
L(:,end+1) = 0;
L = L';
ncontrasts = size(L,2);
genbins = gensize/10:gensize/10:gensize;

%% Check Settings %%
try load(paramfile), catch ME, disp('ERROR: Problem loading paramfile'); end
if size(L,1)~=Xparams.nconds+1, disp('ERROR: # of columns in contrast matrix ''L'' does not equal # of conditions defined in Xparams'); return; end
if length(conWeights)~=size(L,2), disp('ERROR: # of contrast weights does not equal # of contrasts'); return; end

%% Begin Optimization %%
[d t] = bob_timestamp;
fprintf('\nDesign Optimization Started %s on %s', t, d); 
fprintf('\n\n\tDESIGN PARAMETERS\n');
strucdisp(Xparams)
tic; % start the timer

%% Create First Generation %%
fprintf('\nGeneration 1 of %d ', ngen);
efficiency = zeros(gensize,1);
order = cell(gensize,1);
jitter = cell(gensize,1);
for i = 1:gensize
    
    d=makeX(Xparams);
    X=d.X;
    X(:,end+1) = 1;
    for c = 1:ncontrasts
        eff(c) = 1/trace(L(:,c)'*pinv(X'*X)*L(:,c));
    end
    efficiency(i) = eff*conWeights';
    order{i} = d.combined(:,2);
    jitter{i} = d.combined(:,5);
    if ismember(i,genbins), fprintf('.'), end

end
fprintf(' Max Efficiency = %2.15f', max(efficiency));
maxgeneff(1) = max(efficiency);


%% Loop Over Remaining Generations %%
for g = 2:ngen

    fprintf('\nGeneration %d of %d ', g, ngen);
    
    %% Grab the Alphas %%
    tmp = sortrows([(1:length(efficiency))' efficiency], -2);
    fitidx = tmp(1:nalpha,1);
    fit.efficiency = efficiency(fitidx);
    fit.order = order(fitidx);
    fit.jitter = jitter(fitidx);
    
    %% Use the Alphas to Breed %%
    cross.efficiency = zeros(halfgen,1);
    cross.order = cell(halfgen,1);
    cross.jitter = cell(halfgen,1);
    for i = 1:halfgen
        
        %% Combine Orders %%
        conidx = randperm(Xparams.nconds);
        orderidx = randperm(length(fit.order));
        fixcon = conidx(1); 
        varcon = conidx(2:end);
        calpha = fit.order{orderidx(1)};
        mate = fit.order{orderidx(2)};
        calpha(ismember(calpha,varcon)) = mate(ismember(mate,varcon));
        d=makeX(Xparams, calpha);
        X=d.X;
        X(:,end+1) = 1;
        for c = 1:ncontrasts
            eff(c) = 1/trace(L(:,c)'*pinv(X'*X)*L(:,c));
        end
        cross.efficiency(i) = eff*conWeights';
        cross.order{i} = d.combined(:,2);
        cross.jitter{i} = d.combined(:,5);
        if ismember(i,genbins), fprintf('.'), end

    end
    
    %% Introduce Some Nasty Mutants %%
    if g>2 && maxgeneff(g-1)==maxgeneff(g-2)
        mutsize = gensize;
    else
        mutsize = halfgen;
    end
    mut.efficiency = zeros(mutsize,1);
    mut.order = cell(mutsize,1);
    mut.jitter = cell(mutsize,1);
    for i = 1:mutsize
        d=makeX(Xparams);
        X=d.X;
        X(:,end+1) = 1;
        for c = 1:ncontrasts
            eff(c) = 1/trace(L(:,c)'*pinv(X'*X)*L(:,c));
        end
        mut.efficiency(i) = eff*conWeights';
        mut.order{i} = d.combined(:,2);
        mut.jitter{i} = d.combined(:,5);
        if ismember(i,genbins), fprintf('.'), end
    end
    
     %% Combine this Genertation and Compute Max Efficiency %%
    efficiency = [fit.efficiency; cross.efficiency; mut.efficiency];
    order = [fit.order; cross.order; mut.order];
    jitter = [fit.jitter; cross.jitter; mut.jitter];
    fprintf(' Max Efficiency = %2.15f', max(efficiency));
    maxgeneff(g) = max(efficiency);
    
    %% Break if Over Time %%
    if toc>=maxtime*60, break, end
    
end

%% Save Best Designs %%
[d t] = bob_timestamp;
outdir = sprintf('best_designs_%s_%s', d, t); mkdir(outdir);
tmp = sortrows([(1:length(efficiency))' efficiency], -2);
fitidx = tmp(1:keep,1);
best.efficiency = efficiency(fitidx);
best.order = order(fitidx);
best.jitter = jitter(fitidx);
design = cell(keep,1);
for i = 1:keep
    design{i}=breedX(Xparams, best.order{i}, best.jitter{i});
    fname = [outdir filesep 'design' num2str(i) '.txt'];
    dlmwrite(fname, design{i}.combined, 'delimiter', '\t')
end
save([outdir filesep 'designinfo.mat'], 'design');
fprintf('\n\nFinished in %d minutes at %s on %s\n\n', round(toc/60), t, d);

rmpath('subfunctions')





  


