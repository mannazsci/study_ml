% eegplugin_bids_dl() - EEGLAB plugin to convert BIDS datasets for deep
%                       learning
% Usage:
%   >> eegplugin_bids_dl(fig, trystrs, catchstrs);
%
% Inputs:
%   fig        - [integer] eeglab figure.
%   trystrs    - [struct] "try" strings for menu callbacks.
%   catchstrs  - [struct] "catch" strings for menu callbacks.
%
% See also: eeglab()

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
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1.07  USA

function vers = eegplugin_bids_dl(fig, trystrs, catchstrs)
    
    vers = 'bids_dl1.0';
    if nargin < 3
        error('eegplugin_bids_dl requires 3 arguments');
    end
    
    % add folder to path
    % ------------------
    p = which('pop_bids_dl.m');
    p = p(1:findstr(p,'pop_bids_dl.m')-1);
    if ~exist('pop_bids_dl')
        addpath( p );
    end
    
    % find export data menu
    % ---------------------
    menui = findobj(fig, 'tag', 'export'); 
    
    % menu callbacks
    % --------------
    comcnt1 = [ trystrs.no_check 'pop_bids_dl(STUDY, ALLEEG); '  catchstrs.add_to_hist ];
                
    % create menus
    % ------------
    uimenu( menui, 'label', 'Export STUDY to ML/DL data format', 'separator', 'on', 'callback', comcnt1);

