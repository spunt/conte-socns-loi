function defaults = loi1_defaults
% DEFAULTS  Defines defaults for LOI1 (Implicit)
%__________________________________________________________________________
% Copyright (C) 2014  Bob Spunt, Ph.D.

% Screen Resolution
%==========================================================================
defaults.screenres      = [1024 768];   % recommended screen resolution (if 
                                        % not supported by monitor, will
                                        % default to current resolution)

% Response Keys
%==========================================================================
defaults.trigger        = '5%'; % trigger key (to start ask)
defaults.valid_keys     = {'1!' '2@' '3#' '4$'}; % valid response keys
defaults.escape         = 'ESCAPE'; % escape key (to exit early)
                                
% Paths
%==========================================================================
defaults.path.base      = pwd;
defaults.path.data      = fullfile(defaults.path.base, 'data');
defaults.path.stim      = fullfile(defaults.path.base, 'stimuli');
defaults.path.design    = fullfile(defaults.path.base, 'design/loi1');
defaults.path.utilities = fullfile(defaults.path.base, 'utilities');

% Text 
%==========================================================================
defaults.font.name      = 'Arial'; % default font
defaults.font.size1     = 42; % default font size (smaller)
defaults.font.size2     = 46; % default font size (bigger)
defaults.font.wrap      = 42; % default font wrapping (arg to DrawFormattedText)

% Timing (specify in seconds)
%==========================================================================
defaults.maxDur         = 1.25;   % (max) dur of trial 
defaults.ISI            = 0.10;   % dur of interval between trials
defaults.maxRepDur      = 0.80;   % dur of interval between question and   
                                  % first trial of each block
                               
end