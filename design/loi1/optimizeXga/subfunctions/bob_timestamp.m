function [day time] = bob_timestamp(varargin)
% BOB_TIMESTAMP
%
%   USAGE: [day time] = bob_timestamp
%
%       day: mmm_DD_YYYY
%       time: HHMMSSPM
% ===============================================%
day = strtrim(datestr(now,'mmm_DD_YYYY'));
time = strtrim(datestr(now,'HHMMSSPM'));



