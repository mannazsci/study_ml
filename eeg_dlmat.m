% eeg_dlmat - this function converts a 3D matrix data to .mat samples and saves
%             the raw data, 12x12 and 6x6 interpolated grid data data in the 
%             foldername mat_files
%
% Usage:
%    eeg_dlmat(EEG, 'key', val);
%
% Inputs:
%    EEG - EEGLAB dataset
%
% Optional parameters:
%  'outputdir' - [string] output directory
%  'cloudpath' - [string] if a path on the cloud is available, a second
%                label file containing this path will be created (usefull for DataStore
%                object). For example 's3://openneuro.org/ds003061'
%
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

function eeg_dlmat(EEG,varargin)

if nargin < 2
    help bids2mat;
end

g = finputcheck(varargin, { 'cloudpath'  'string'  {}   '';
                            'outputdir'  'string'  {}   ''; ...
                            'verbose'  'string'  { 'on' 'off' }   'on' });
if isstr(g)
    error(g);
end

% create folders if necessary
eeg_dir = fullfile('mat_files', EEG.subject, 'eeg');
label_file1 = fullfile(g.outputdir, 'labels_local.csv');
label_file2 = fullfile(g.outputdir, 'labels_cloud.csv');
if ~exist(fullfile(g.outputdir, eeg_dir))
    mkdir(fullfile(g.outputdir, eeg_dir))
end

% get the type of epoch and any other interesting field
epoch_type = std_maketrialinfo([], EEG);
trial_info = struct2cell(epoch_type.datasetinfo.trialinfo')';

num_samples = size(EEG.data,3);

if strcmpi(g.verbose, 'on')
    fprintf('Exporting %s segments (n=%d):', EEG.filename, EEG.trials);
end

for segment_num = 1:num_samples
    if strcmpi(g.verbose, 'on')
        fprintf('.');
    end

    % create file name
    filename = [ eeg_dir filesep EEG.subject ];
    if ~isempty(EEG.run) filename = [ filename '_run_' num2str(EEG.run) ]; end
    if ~isempty(EEG.session) filename = [ filename '_session_' num2str(EEG.session) ]; end
    filename = sprintf('%s_sample_%4.4d.mat', filename, segment_num);
    filenameAbs = fullfile(g.outputdir, filename);

    if isfile(filenameAbs)
        fprintf('Warning: File %s already exisits. Skipping...\n', filenameAbs);
    else

        data = EEG.data(:,:,segment_num);
        num_timestamps = size(data,2);
        Z_12 = zeros(12,12,num_timestamps);
        Z_6 = single(zeros(6,6,num_timestamps));

        % compute the relevant interpolated channel info
        % topoplot_DaSh default gridscale = 12
        DaSh_out_Z12 = topoplot_DaSh([], EEG.chanlocs,  'chaninfo', EEG.chaninfo);
        DaSh_out_Z6 = topoplot_DaSh([], EEG.chanlocs,  'chaninfo', EEG.chaninfo,'gridscale', 6);

        % attach the griddata_DaSh file to the pool object otherwise
        % workers can't access it
        %  poolobj = parpool;
        %  addAttachedFiles(poolobj,{'griddata_DaSh.m'})

        for time_step = 1:num_timestamps
            Z_12(:,:,time_step) = griddata_DaSh(data(:,time_step)', DaSh_out_Z12);
        end

        for time_step =1:num_timestamps
            Z_6(:,:,time_step) = griddata_DaSh(data(:,time_step)', DaSh_out_Z6);
        end

        %% z-score Z_12
        %           max_z12 = max(max(max(Z_12)));
        %           min_z12 = min(min(min(Z_12)));
        %           Z_12 =  (Z_12 - min_z12)./(max_z12 -min_z12);
        %%
        %change from double to single precision
        Z_12 = single(Z_12);
        Z_6  = single(Z_6);

        %convert all NaNs to zeros
        Z_12(isnan(Z_12))=0;
        Z_6(isnan(Z_6))=0;

        %           % calculate Z_6
        %          Z_6 = imresize(Z_12,0.5,'method','nearest');

        save(filenameAbs,'data','Z_12','Z_6','-mat','-v7.3','-nocompression')
        sample_filepath1 = fullfile('.',filename);
        sample_filepath2 = fullfile(g.cloudpath,filename);

        %sample_file_name, event_type, segment number, participant info, original file name
        if ~isfield(EEG, 'BIDS') || isempty(EEG.BIDS)
            label_info1 = [sample_filepath1 trial_info(end) segment_num EEG.filename];
            label_info2 = [sample_filepath2 trial_info(end) segment_num EEG.filename];
        else
            label_info1 = [sample_filepath trial_info(end) segment_num EEG.BIDS.pInfo(2,:) EEG.filename];
            label_info2 = [sample_filepath trial_info(end) segment_num EEG.BIDS.pInfo(2,:) EEG.filename];
        end

        writetable(cell2table(label_info1),label_file1,'Delimiter','tab','WriteMode','append','WriteRowNames',false,'WriteVariableNames',false,'QuoteStrings',true);
        if ~isempty(g.cloudpath)
            writetable(cell2table(label_info2),label_file2,'Delimiter','tab','WriteMode','append','WriteRowNames',false,'WriteVariableNames',false,'QuoteStrings',true);
        end
    end
end
if strcmpi(g.verbose, 'on')
    fprintf('\n');
end



function Zi = griddata_DaSh(Values,DaSh_out)

[r,c] = size(Values);
% if r>1 && c>1,
%   error('input data must be a single vector');
% end
Values = Values(:); % make Values a column vector

if ~isempty(Values)
    %       if length(Values) == length(DaSh_out.Th)  % if as many map Values as channel locs
    intValues      = Values(DaSh_out.intchans);

    %       end
end  % now channel parameters and values all refer to plotting channels only

Zi  = gdatav4(DaSh_out.inty,DaSh_out.intx,double(intValues), DaSh_out.Xi, DaSh_out.Yi);

%%%%%%%%%%%%%%%%%%%%%%% Mask out data outside the head %%%%%%%%%%%%%%%%%%%
mask = (sqrt(DaSh_out.Xi.^2 + DaSh_out.Yi.^2) <= DaSh_out.rmax); % mask outside the plotting circle
ii = find(mask == 0);
Zi(ii)  = NaN;                         % mask non-plotting voxels with NaNs

% grid = plotrad;                       % unless 'noplot', then 3rd output arg is plotrad
%
%%%%%%%%%% Return interpolated value at designated scalp location %%%%%%%%%%
%
%   if exist(DaSh_out.chanrad)   % optional first argument to 'noplot'
%       chantheta = (DaSh_out.chantheta/360)*2*pi;
%       chancoords = round(ceil(DaSh_out.GRID_SCALE/2)+DaSh_out.GRID_SCALE/2*2*chanrad*[cos(-DaSh_out.chantheta),...
%                                                       -sin(-DaSh_out.chantheta)]);
%       if chancoords(1)<1 ...
%          || chancoords(1) > DaSh_out.GRID_SCALE ...
%             || chancoords(2)<1 ...
%                || chancoords(2)>DaSh_out.GRID_SCALE
%           error('designated ''noplot'' channel out of bounds')
%       else
%         chanval = Zi(chancoords(1),chancoords(2));
%         grid = Zi;
%         Zi = chanval;  % return interpolated value instead of Zi
%       end
%   end
%


function vq = gdatav4(x,y,v,xq,yq)
%GDATAV4 MATLAB 4 GRIDDATA interpolation

%   Reference:  David T. Sandwell, Biharmonic spline
%   interpolation of GEOS-3 and SEASAT altimeter
%   data, Geophysical Research Letters, 2, 139-142,
%   1987.  Describes interpolation using value or
%   gradient of value in any dimension.

%    [x, y, v] = mergepoints2D(x,y,v);


xy = x(:) + 1i*y(:);

% Determine distances between points
d = abs(xy - xy.');

% Determine weights for interpolation
g = (d.^2) .* (log(d)-1);   % Green's function.
% Fixup value of Green's function along diagonal
g(1:size(d,1)+1:end) = 0;
weights = g \ v(:);

[m,n] = size(xq);
vq = zeros(size(xq));
xy = xy.';

%    Evaluate at requested points (xq,yq).  Loop to save memory.
for i=1:m
    for j=1:n

        d = abs(xq(i,j) + 1i*yq(i,j) - xy);
        g = (d.^2) .* (log(d)-1);   % Green's function.
        % Value of Green's function at zero
        g(d==0) = 0;
        vq(i,j) = g * weights;
    end
end






%         xyq = xq+1i*yq;
%
% %         fun = @(a,b) abs(a - b);
% %         d = bsxfun(@minus,xyq,xy);
% %         d= abs(d);
%
%         g = (d.^2) .* (log(d)-1);   % Green's function.
%         % Value of Green's function at zero
%         g(d==0) = 0;
%         vq = g * weights;


