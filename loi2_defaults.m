function defaults = loi2_defaults
% DEFAULTS  Defines defaults for LOI2 (Explicit)
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
defaults.path.design    = fullfile(defaults.path.base, 'design/loi2');
defaults.path.utilities = fullfile(defaults.path.base, 'utilities');

% Text 
%==========================================================================
defaults.font.name      = 'Arial'; % default font
defaults.font.size1     = 42; % default font size (smaller)
defaults.font.size2     = 46; % default font size (bigger)
defaults.font.wrap      = 42; % default font wrapping (arg to DrawFormattedText)

% Timing (specify in seconds)
%==========================================================================
defaults.cueDur         = 2.50;   % dur of question presentation
defaults.maxDur         = 2.00;   % (max) dur of trial 
defaults.ISI            = 0.30;   % dur of interval between trials
defaults.firstISI       = 0.15;   % dur of interval between question and   
                                  % first trial of each block
                               
end