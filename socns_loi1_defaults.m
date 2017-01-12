function defaults = socns_loi1_defaults
% DEFAULTS  Defines defaults for LOI1 (Implicit)
%__________________________________________________________________________
% Copyright (C) 2014  Bob Spunt, Ph.D.

% Screen Resolution
%==========================================================================
defaults.screenres      = [1280 960];   % recommended screen resolution (if
                                        % not supported by monitor, will
                                        % default to current resolution)

% Response Keys
%==========================================================================
defaults.trigger        = '5%'; % trigger key (to start ask)
defaults.valid_keys     = {'1!' '2@' '3#' '4$'}; % valid response keys
defaults.escape         = 'ESCAPE'; % escape key (to exit early)
defaults.testbuttonbox  = false; % set to either true or false
defaults.motionreminder = false; % set to either true or false

% Paths
%==========================================================================
defaults.path.base      = pwd;
defaults.path.data      = fullfile(defaults.path.base, 'data');
defaults.path.stim      = fullfile(defaults.path.base, 'stimuli');
defaults.path.design    = fullfile(defaults.path.base, 'design/loi1');
defaults.path.utilities = fullfile(defaults.path.base, 'ptb-utilities');

% Text
%==========================================================================
defaults.font.name      = 'Helvetica'; % default font
defaults.font.size1     = 42; % default font size (smaller)
defaults.font.size2     = 46; % default font size (bigger)
defaults.font.wrap      = 42; % default font wrapping (arg to DrawFormattedText)

% Timing (specify in seconds)
%==========================================================================
defaults.prestartdur    = 4;      % duration of fixation period after trigger
                                  % and before first block
defaults.maxDur         = 1.25;   % dur of image presentation
defaults.ISI            = 0.15;   % dur of interval between iamges
defaults.maxRepDur      = 0.75;   % (max) dur of catch images
defaults.ignoreDur      = 0.10;   % dur after trial presentation in which
                                  % button presses are ignored (this is
                                  % useful when participant provides a late
                                  % response to the previous trial)
                                  % DEFAULT VALUE = 0.15
defaults.TR             = 1;      % Your TR (in secs) - Task runtime will be adjusted
                                  % to a multiple of the TR
end