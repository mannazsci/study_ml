% pop_bids_dl() - Export EEGLAB study into ML/DL data format
%
% Usage:
%     pop_bids_dl(STUDY, ALLEEG, 'key', val);
%
% Inputs:
%   ...

% Copyright (C)
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

function pop_bids_dl(STUDY, ALLEEG, varargin)

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
    options = { 'targetdir' restag.outputfolder 'License' restag.license 'comments' restag.changes 'createids' fastif(restag.newids, 'on', 'off') 'events' restag.events};
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

g = finputcheck(options, { 'targetdir' 'string'  {}   fullfile(STUDY.filepath, '..', 'ML_EXPORT'); ...
    'License'   'string'  {}    'CC0';
    'comments' 'string'  {}    '';
    'events'   'string'  {}    '';
    'createids' 'string' { 'on' 'off' } 'on' }, 'pop_bids_dl');
if isstr(g), error(g); end

%aws_path = ['s3://openneuro.org/' STUDY.BIDS_dataset_name];
label_file = fullfile(g.targetdir, 'labels_s3.csv');

for iSet = 1:length(ALLEEG)
    EEG =  ALLEEG(iSet);

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

    bids2mat(EEG,label_file,g.targetdir)
end
