% pop_studydl() - Export EEGLAB study into ML/DL data format
%
% Usage:
%     pop_studydl(STUDY, ALLEEG, 'key', val);
%
% Inputs:
%   ...
% Authors: Manisha Sinha, Arnaud Delorme

% Copyright (C) 2022 Arnaud Delorme
%
% This file is part of EEGLAB, see http://www.eeglab.org
% for the documentation and details.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%
% 1. Redistributions of source code must retain the above copyright notice,
% this list of conditions and the following disclaimer.
%
% 2. Redistributions in binary form must reproduce the above copyright notice,
% this list of conditions and the following disclaimer in the documentation
% and/or other materials provided with the distribution.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
% THE POSSIBILITY OF SUCH DAMAGE.

function pop_studydl(STUDY, ALLEEG, varargin)

if nargin < 3
    com = [ 'bidsFolderxx = uigetdir(''Pick an output folder'');' ...
        'if ~isequal(bidsFolderxx, 0), set(findobj(gcbf, ''tag'', ''outputfolder''), ''string'', bidsFolderxx); end;' ...
        'clear bidsFolderxx;' ];

    cb_events       = 'pop_bids_dl(''edit_events'', gcbf);';
    uilist = { ...
        { 'Style', 'text', 'string', 'Export EEGLAB study to ML/DL format', 'fontweight', 'bold'  }, ...
        {} ...
        { 'Style', 'text', 'string', 'Output folder:' }, ...
        { 'Style', 'edit', 'string',   fullfile('.', 'ML_EXPORT') 'tag' 'outputfolder' }, ...
        { 'Style', 'pushbutton', 'string', '...' 'callback' com }, ...
        { 'Style', 'text', 'string', 'Licence for distributing:' }, ...
        { 'Style', 'edit', 'string', 'Creative Common 0 (CC0)' 'tag' 'license'  }, ...
        { 'Style', 'text', 'string', 'Comments:' }, ...
        { 'Style', 'edit', 'string', '' 'tag' 'changes'  'HorizontalAlignment' 'left' 'max' 3   }, ...
        { 'Style', 'text', 'string', 'Select events to export (default all)' 'tag' 'events' 'callback' cb_events }, ...
        { 'Style', 'edit', 'string',  '' 'tag' 'events' }, ...
        { 'Style', 'pushbutton', 'string', '...' 'callback' '' }, ...
        { 'Style', 'checkbox', 'string', 'Do not use participants ID and create anonymized participant ID instead' 'value' 1 'tag' 'newids' }, ...
        };

    relSize = 0.7;
    geometry = { [1] [1] [1-relSize relSize*0.8 relSize*0.2] [1-relSize relSize] [1] [1] [2 1 1] [1]};
    geomvert =   [1  0.2 1                                                   1  1   3    1        1];
    userdata.ALLEEG = ALLEEG;
    userdata.STUDY  = STUDY;
    [results,~,~,restag] = inputgui( 'geometry', geometry, 'geomvert', geomvert, 'uilist', uilist, 'helpcom', 'pophelp(''pop_bids_dl");', 'title', 'Export EEGLAB STUDY to BIDS for DL -- pop_bids_dl()', 'userdata', userdata );
    if isempty(results), return; end

    % decode some outputs
    if ~isempty(strfind(restag.license, 'CC0')), restag.license = 'CC0'; end
    options = { 'outputdir' restag.outputfolder 'License' restag.license 'comments' restag.changes 'createids' fastif(restag.newids, 'on', 'off') 'events' restag.events};
elseif isstr(STUDY)
    %     command = STUDY;
    %     fig = ALLEEG;
    %     userdata = get(fig, 'userdata');
    %
    %     switch command
    %         case 'edit_events'
    %             userdata.EEG = pop_eventinfo(userdata.EEG);
    %     end
else
    options = varargin;
end

g = finputcheck(options, { 'outputdir' 'string'  {}   fullfile(STUDY.filepath, '..', 'ML_EXPORT'); ...
    'License'   'string'  {}    'CC0';
    'comments' 'string'  {}    '';
    'events'   'string'  {}    '';
    'eraseall'   'string'  { 'on' 'off' } 'off';
    'createids' 'string' { 'on' 'off' } 'on' }, 'pop_studydl');
if isstr(g), error(g); end

if strcmpi(g.eraseall, 'on')
    rmdir(g.outputdir, 's');
end
for iSet = 1:length(ALLEEG)
    EEG =  ALLEEG(iSet);
    EEG.subject = STUDY.datasetinfo(iSet).subject;

    % check subject
    if isempty(EEG.subject)
        error('All datasets must have a subject ID')
    end
    
    % check for bidsevents
    if EEG.trials == 1
        EEG = pop_resample(EEG, 128);
        if isempty(EEG.event)
            disp('Continuous data. Regular 2s epochs will be generated')
            EEG = eeg_regepochs(EEG, 'limits', [0 2], 'recurrence', 2);
        else
            disp('Events file detected! Epochs will be generated with [-0.5, 1.5] s time window ')
            EEG = pop_epoch(EEG, unique({EEG.event.type}), [-0.5 1.5]);
        end
    else
        error('Cannot process epoched datasets');
    end

    eeg_dlmat(EEG, 'outputdir', g.outputdir)
end
