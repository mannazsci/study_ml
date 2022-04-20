% topoplot_DaSh() - plot a topographic map of a scalp data field in a 2-D circular view 
%              (looking down at the top of the head) using interpolation on a fine 
%              cartesian grid. Can also show specified channel location(s), or return 
%              an interpolated value at an arbitrary scalp location (see 'noplot').
%              By default, channel locations below head center (arc_length 0.5) are 
%              shown in a 'skirt' outside the cartoon head (see 'plotrad' and 'headrad' 
%              options below). Nose is at top of plot; left is left; right is right.
%              Using option 'plotgrid', the plot may be one or more rectangular grids.
% Usage:
%       DaSh_out = topoplot_DaSH(data', EEG.chanlocs, 'whitebk', 'on', 'gridscale', 12, 'numcontour', 0,  'chaninfo', EEG.chaninfo);
%        >>  topoplot_DaSh(datavector, EEG.chanlocs);   % plot a map using an EEG chanlocs structure
%        >>  topoplot_DaSh(datavector, 'my_chan.locs'); % read a channel locations file and plot a map
%        >>  topoplot_DaSh('example');                  % give an example of an electrode location file
%        >>  [h grid_or_val plotrad_or_grid, xmesh, ymesh]= ...
%                           topoplot_DaSh(datavector, chan_locs, 'Input1','Value1', ...);
% Required Inputs:
%   datavector        - single vector of channel values. Else, if a vector of selected subset
%                       (int) channel numbers -> mark their location(s) using 'style' 'blank'.
%   chan_locs         - name of an EEG electrode position file (>> topoplot_DaSh example).
%                       Else, an EEG.chanlocs structure (>> help readlocs or >> topoplot_DaSh example)
% Optional inputs:
%   'maplimits'       - 'absmax'   -> scale map colors to +/- the absolute-max (makes green 0); 
%                       'maxmin'   -> scale colors to the data range (makes green mid-range); 
%                       [lo.hi]    -> use user-definined lo/hi limits
%                       {default: 'absmax'}
%   'style'           - 'map'      -> plot colored map only
%                       'contour'  -> plot contour lines only
%                       'both'     -> plot both colored map and contour lines
%                       'fill'     -> plot constant color between contour lines
%                       'blank'    -> plot electrode locations only {default: 'both'}
%   'electrodes'      - 'on','off','labels','numbers','ptslabels','ptsnumbers'. To set the 'pts' 
%                       marker,,see 'Plot detail options' below. {default: 'on' -> mark electrode 
%                       locations with points ('.') unless more than 64 channels, then 'off'}. 
%   'plotchans'       - [vector] channel numbers (indices) to use in making the head plot. 
%                       {default: [] -> plot all chans}
%   'plotgrid'        - [channels] Plot channel data in one or more rectangular grids, as 
%                       specified by [channels],  a position matrix of channel numbers defining 
%                       the topographic locations of the channels in the
%                       grid. Zero values are ignored (given the figure background color); 
%                       negative integers, the color of the polarity-reversed channel values.  
%                       Ex: >> figure; ...
%                             >> topoplot_DaSh(values,'chanlocs','plotgrid',[11 12 0; 13 14 15]);
%                       % Plot a (2,3) grid of data values from channels 11-15 with one empty 
%                       grid cell (top right) {default: no grid plot} 
%   'nosedir'         - ['+X'|'-X'|'+Y'|'-Y'] direction of nose {default: '+X'}
%   'chaninfo'        - [struct] optional structure containing fields 'nosedir', 'plotrad'. 
%                       See these (separate) field definitions above, below.
%                       {default: nosedir +X, plotrad 0.5, all channels}
%   'plotrad'         - [0.15<=float<=1.0] plotting radius = max channel arc_length to plot.
%                       See >> topoplot_DaSh example. If plotrad > 0.5, chans with arc_length > 0.5 
%                       (i.e. below ears-eyes) are plotted in a circular 'skirt' outside the
%                       cartoon head. See 'intrad' below. {default: max(max(chanlocs.radius),0.5);
%                       If the chanlocs structure includes a field chanlocs.plotrad, its value 
%                       is used by default}.
%   'headrad'         - [0.15<=float<=1.0] drawing radius (arc_length) for the cartoon head. 
%                       NOTE: Only headrad = 0.5 is anatomically correct! 0 -> don't draw head; 
%                       'rim' -> show cartoon head at outer edge of the plot {default: 0.5}
%   'intrad'          - [0.15<=float<=1.0] radius of the scalp map interpolation area (square or 
%                       disk, see 'intsquare' below). Interpolate electrodes in this area and use 
%                       this limit to define boundaries of the scalp map interpolated data matrix
%                       {default: max channel location radius}
%   'intsquare'       - ['on'|'off'] 'on' -> Interpolate values at electrodes located in the whole 
%                       square containing the (radius intrad) interpolation disk; 'off' -> Interpolate
%                       values from electrodes shown in the interpolation disk only {default: 'on'}.
%   'conv'            - ['on'|'off'] Show map interpolation only out to the convext hull of
%                       the electrode locations to minimize extrapolation. Use this option ['on'] when 
%                       plotting pvalues  {default: 'off'}. When plotting pvalues in totoplot, set 
%                       'conv' option to 'on' to minimize interpolation effects
%   'noplot'          - ['on'|'off'|[rad theta]] do not plot (but return interpolated data).
%                       Else, if [rad theta] are coordinates of a (possibly missing) channel, 
%                       returns interpolated value for channel location.  For more info, 
%                       see >> topoplot_DaSh 'example' {default: 'off'}
%   'verbose'         - ['on'|'off'] comment on operations on command line {default: 'on'}.
%   'chantype'        - deprecated
%
% Plot detail options:
%   'drawaxis'        - ['on'|'off'] draw axis on the top left corner.
%   'emarker'         - Matlab marker char | {markerchar color size linewidth} char, else cell array 
%                       specifying the electrode 'pts' marker. Ex: {'s','r',32,1} -> 32-point solid 
%                       red square. {default: {'.','k',[],1} where marker size ([]) depends on the number 
%                       of channels plotted}.
%   'emarker2'        - {markchans}|{markchans marker color size linewidth} cell array specifying 
%                       an alternate marker for specified 'plotchans'. Ex: {[3 17],'s','g'} 
%                       {default: none, or if {markchans} only are specified, then {markchans,'o','r',10,1}}
%   'hcolor'          - color of the cartoon head. Use 'hcolor','none' to plot no head. {default: 'k' = black}
%   'shading'         - 'flat','interp'  {default: 'flat'}
%   'numcontour'      - number of contour lines {default: 6}. You may also enter a vector to set contours 
%                       at specified values.
%   'contourvals'     - values for contour {default: same as input values}
%   'pmask'           - values for masking topoplot_DaSh. Array of zeros and 1 of the same size as the input 
%                       value array {default: []}
%   'color'           - color of the contours {default: dark grey}
%   'whitebk '        -  ('on'|'off') make the background color white (e.g., to print empty plotgrid channels) 
%                       {default: 'off'}
%   'gridscale'       - [int > 32] size (nrows) of interpolated scalp map data matrix {default: 67}
%   'colormap'        -  (n,3) any size colormap {default: existing colormap}
%   'circgrid'        - [int > 100] number of elements (angles) in head and border circles {201}
%   'emarkercolor'    - cell array of colors for 'blank' option.
%   'plotdisk'        - ['on'|'off'] plot disk instead of dots for electrodefor 'blank' option. Size of disk
%                       is controlled by input values at each electrode. If an imaginary value is provided, 
%                       plot partial circle with red for the real value and blue for the imaginary one.
%
% Dipole plotting options:
%   'dipole'          - [xi yi xe ye ze] plot dipole on the top of the scalp map
%                       from coordinate (xi,yi) to coordinates (xe,ye,ze) (dipole head 
%                       model has radius 1). If several rows, plot one dipole per row.
%                       Coordinates returned by dipplot() may be used. Can accept
%                       an EEG.dipfit.model structure (See >> help dipplot).
%                       Ex: ,'dipole',EEG.dipfit.model(17) % Plot dipole(s) for comp. 17.
%   'dipnorm'         - ['on'|'off'] normalize dipole length {default: 'on'}.
%   'diporient'       - [-1|1] invert dipole orientation {default: 1}.
%   'diplen'          - [real] scale dipole length {default: 1}.
%   'dipscale'        - [real] scale dipole size {default: 1}.
%   'dipsphere'       - [real] size of the dipole sphere. {default: 85 mm}.
%   'dipcolor'        - [color] dipole color as Matlab code code or [r g b] vector
%                       {default: 'k' = black}.
% Outputs:
%              handle - handle of the colored surface.If
%                       contour only is plotted, then is the handle of
%                       the countourgroup. (If no surface or contour is plotted,
%                       return "gca", the handle of the current plot)
%         grid_or_val - [matrix] the interpolated data image (with off-head points = NaN).  
%                       Else, single interpolated value at the specified 'noplot' arg channel 
%                       location ([rad theta]), if any.
%     plotrad_or_grid - IF grid image returned above, then the 'plotrad' radius of the grid.
%                       Else, the grid image
%     xmesh, ymesh    - x and y values of the returned grid (above)
%
% Chan_locs format:
%    See >> topoplot_DaSh 'example'
%
% Examples:
%
%    To plot channel locations only:
%    >> figure; topoplot_DaSh([],EEG.chanlocs,'style','blank','electrodes','labelpoint','chaninfo',EEG.chaninfo);
%    
% Notes: - To change the plot map masking ring to a new figure background color,
%            >> set(findobj(gca,'type','patch'),'facecolor',get(gcf,'color'))
%        - topoplot_DaShs may be rotated. From the commandline >> view([deg 90]) {default: [0 90])
%        - When plotting pvalues make sure to use the option 'conv' to minimize extrapolation effects 
%
% Authors: Manisha Sinha, Andy Spydell, Colin Humphries, Arnaud Delorme & Scott Makeig
%          CNL / Salk Institute, 8/1996-/10/2001; SCCN/INC/UCSD, Nov. 2001 -
%
% See also: timtopo(), envtopo()

% Deprecated options: 
%           'shrink' - ['on'|'off'|'force'|factor] Deprecated. 'on' -> If max channel arc_length 
%                       > 0.5, shrink electrode coordinates towards vertex to plot all channels
%                       by making max arc_length 0.5. 'force' -> Normalize arc_length 
%                       so the channel max is 0.5. factor -> Apply a specified shrink
%                       factor (range (0,1) = shrink fraction). {default: 'off'}
%   'electcolor' {'k'}  ... electrode marking details and their {defaults}. 
%   'emarker' {'.'}|'emarkersize' {14}|'emarkersizemark' {40}|'efontsize' {var} -
%                       electrode marking details and their {defaults}. 
%   'ecolor'          - color of the electrode markers {default: 'k' = black}
%   'interplimits'    - ['electrodes'|'head'] 'electrodes'-> interpolate the electrode grid; 
%                       'head'-> interpolate the whole disk {default: 'head'}.

% Unimplemented future options:

% Copyright (C) Colin Humphries & Scott Makeig, CNL / Salk Institute, Aug, 1996
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

% topoplot_DaSh Version 2.1


function [DaSh_out] = topoplot_DaSh(Values,loc_file,varargin)

%
%%%%%%%%%%%%%%%%%%%%%%%% Set defaults %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
icadefs                 % read defaults MAXtopoplot_DaShCHANS and DEFAULT_ELOC and BACKCOLOR
if ~exist('BACKCOLOR')  % if icadefs.m does not define BACKCOLOR
   BACKCOLOR = [.93 .96 1];  % EEGLAB standard
end
whitebk = 'on';  % by default

persistent warningInterp;

plotgrid = 'off';
plotchans = [];
noplot  = 'on';
handle = [];
Zi = [];
chanval = NaN;
rmax = 0.5;             % actual head radius - Don't change this!
INTERPLIMITS = 'head';  % head, electrodes
INTSQUARE = 'on';       % default, interpolate electrodes located though the whole square containing
                        % the plotting disk
default_intrad = 1;     % indicator for (no) specified intrad
MAPLIMITS = 'absmax';   % absmax, maxmin, [values]
GRID_SCALE = 12;        % plot map on a 67X67 grid
CIRCGRID   = 201;       % number of angles to use in drawing circles
AXHEADFAC = 1.3;        % head to axes scaling factor
CONTOURNUM = 0;         % number of contour levels to plot
STYLE = 'both';         % default 'style': both,straight,fill,contour,blank
HEADCOLOR = [0 0 0];    % default head color (black)
CCOLOR = [0.2 0.2 0.2]; % default contour color
ELECTRODES = [];        % default 'electrodes': on|off|label - set below
MAXDEFAULTSHOWLOCS = 64;% if more channels than this, don't show electrode locations by default
EMARKER = '.';          % mark electrode locations with small disks
ECOLOR = [0 0 0];       % default electrode color = black
EMARKERSIZE = [];       % default depends on number of electrodes, set in code
EMARKERLINEWIDTH = 1;   % default edge linewidth for emarkers
EMARKERSIZE1CHAN = 20;  % default selected channel location marker size
EMARKERCOLOR1CHAN = 'red'; % selected channel location marker color
EMARKER2CHANS = [];      % mark subset of electrode locations with small disks
EMARKER2 = 'o';          % mark subset of electrode locations with small disks
EMARKER2COLOR = 'r';     % mark subset of electrode locations with small disks
EMARKERSIZE2 = 10;      % default selected channel location marker size
EMARKER2LINEWIDTH = 1;
EFSIZE = get(0,'DefaultAxesFontSize'); % use current default fontsize for electrode labels
HLINEWIDTH = 2;         % default linewidth for head, nose, ears
BLANKINGRINGWIDTH = .035;% width of the blanking ring 
HEADRINGWIDTH    = .007;% width of the cartoon head ring
SHADING = 'flat';       % default 'shading': flat|interp
shrinkfactor = [];      % shrink mode (dprecated)
intrad       = [];      % default interpolation square is to outermost electrode (<=1.0)
plotrad      = [];      % plotting radius ([] = auto, based on outermost channel location)
headrad      = [];      % default plotting radius for cartoon head is 0.5
squeezefac = 1.0;
MINPLOTRAD = 0.15;      % can't make a topoplot_DaSh with smaller plotrad (contours fail)

ContourVals = Values;
PMASKFLAG   = 0;
COLORARRAY  = { [1 0 0] [0.5 0 0] [0 0 0] };
%COLORARRAY2 = { [1 0 0] [0.5 0 0] [0 0 0] };
gb = [0 0];
COLORARRAY2 = { [gb 0] [gb 1/4] [gb 2/4] [gb 3/4] [gb 1] };

%%%%%% Dipole defaults %%%%%%%%%%%%
DIPOLE  = [];           
DIPNORM   = 'on';
DIPNORMMAX = 'off';
DIPSPHERE = 85;
DIPLEN    = 1;
DIPSCALE  = 1;
DIPORIENT  = 1;
DIPCOLOR  = [0 0 0];
NOSEDIR   = '+X';
CHANINFO  = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%
%%%%%%%%%%%%%%%%%%%%%%% Handle arguments %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
if nargin< 1
   help topoplot_DaSh;
   return
end

% calling topoplot_DaSh from Fieldtrip
% -------------------------------
fieldtrip = 0;
if nargin < 2, loc_file = []; end
if isstruct(Values) || ~isstruct(loc_file), fieldtrip == 1; end
if ischar(loc_file), if exist(loc_file) ~= 2, fieldtrip == 1; end; end
if fieldtrip
    error('Wrong calling format, are you trying to use the topoplot_DaSh Fieldtrip function?');
end

nargs = nargin;
if nargs == 1
  if ischar(Values)
    if any(strcmp(lower(Values),{'example','demo'}))
      fprintf(['This is an example of an electrode location file,\n',...
               'an ascii file consisting of the following four columns:\n',...
               ' channel_number degrees arc_length channel_name\n\n',...
               'Example:\n',...
               ' 1               -18    .352       Fp1 \n',...
               ' 2                18    .352       Fp2 \n',...
               ' 5               -90    .181       C3  \n',...
               ' 6                90    .181       C4  \n',...
               ' 7               -90    .500       A1  \n',...
               ' 8                90    .500       A2  \n',...
               ' 9              -142    .231       P3  \n',...
               '10               142    .231       P4  \n',...
               '11                 0    .181       Fz  \n',...
               '12                 0    0          Cz  \n',...
               '13               180    .181       Pz  \n\n',...
                                                             ...
               'In topoplot_DaSh() coordinates, 0 deg. points to the nose, positive\n',...
               'angles point to the right hemisphere, and negative to the left.\n',...
               'The model head sphere has a circumference of 2; the vertex\n',...
               '(Cz) has arc_length 0. Locations with arc_length > 0.5 are below\n',...
               'head center and are plotted outside the head cartoon.\n',...
               'Option plotrad controls how much of this lower-head "skirt" is shown.\n',...
               'Option headrad controls if and where the cartoon head will be drawn.\n',...
               'Option intrad controls how many channels will be included in the interpolation.\n',...
               ])
      return
    end
  end
end
if nargs < 2
  loc_file = DEFAULT_ELOC;
  if ~exist(loc_file)
      fprintf('default locations file "%s" not found - specify chan_locs in topoplot_DaSh() call.\n',loc_file)
      error(' ')
  end
end
if isempty(loc_file)
  loc_file = 0;
end
if isnumeric(loc_file) && loc_file == 0
  loc_file = DEFAULT_ELOC;
end

if nargs > 2
    if ~(round(nargs/2) == nargs/2)
        error('Odd number of input arguments??')
    end
    for i = 1:2:length(varargin)
        Param = varargin{i};
        Value = varargin{i+1};
        if ~ischar(Param)
            error('Flag arguments must be strings')
        end
        Param = lower(Param);
        switch Param
%             case 'conv'
%                 CONVHULL = lower(Value);
%                 if ~strcmp(CONVHULL,'on') && ~strcmp(CONVHULL,'off')
%                     error('Value of ''conv'' must be ''on'' or ''off''.');
%                 end
%             case 'colormap'
%                 if size(Value,2)~=3
%                     error('Colormap must be a n x 3 matrix')
%                 end
%                 colormap(Value)
            case 'gridscale'
                GRID_SCALE = Value;
%             case 'plotdisk'
%                 PLOTDISK = lower(Value);
%                 if ~strcmp(PLOTDISK,'on') && ~strcmp(PLOTDISK,'off')
%                     error('Value of ''plotdisk'' must be ''on'' or ''off''.');
%                 end
%             case 'intsquare'
%                 INTSQUARE = lower(Value);
%                 if ~strcmp(INTSQUARE,'on') && ~strcmp(INTSQUARE,'off')
%                     error('Value of ''intsquare'' must be ''on'' or ''off''.');
%                 end
%             case 'emarkercolors'
%                 COLORARRAY = Value;
%             case {'interplimits','headlimits'}
%                 if ~ischar(Value)
%                     error('''interplimits'' value must be a string')
%                 end
%                 Value = lower(Value);
%                 if ~strcmp(Value,'electrodes') && ~strcmp(Value,'head')
%                     error('Incorrect value for interplimits')
%                 end
%                 INTERPLIMITS = Value;
%             case 'verbose'
%                 VERBOSE = Value;
%             case 'nosedir'
%                 NOSEDIR = Value;
%                 if isempty(strmatch(lower(NOSEDIR), { '+x', '-x', '+y', '-y' }))
%                     error('Invalid nose direction');
%                 end
            case 'chaninfo'
                CHANINFO = Value;
                if isfield(CHANINFO, 'nosedir'), NOSEDIR      = CHANINFO.nosedir; end
                if isfield(CHANINFO, 'shrink' ), shrinkfactor = CHANINFO.shrink;  end
                if isfield(CHANINFO, 'plotrad') && isempty(plotrad), plotrad = CHANINFO.plotrad; end
%             case 'chantype'
%             case 'drawaxis'
%                 DRAWAXIS = Value;
%             case 'maplimits'
%                 MAPLIMITS = Value;
%             case 'masksurf'
%                 MASKSURF = Value;
%             case 'circgrid'
%                 CIRCGRID = Value;
%                 if ischar(CIRCGRID) || CIRCGRID<100
%                     error('''circgrid'' value must be an int > 100');
%                 end
%             case 'style'
%                 STYLE = lower(Value);
            case 'numcontour'
                CONTOURNUM = Value;
%             case 'electrodes'
%                 ELECTRODES = lower(Value);
%                 if strcmpi(ELECTRODES,'pointlabels') || strcmpi(ELECTRODES,'ptslabels') ...
%                         | strcmpi(ELECTRODES,'labelspts') | strcmpi(ELECTRODES,'ptlabels') ...
%                         | strcmpi(ELECTRODES,'labelpts')
%                     ELECTRODES = 'labelpoint'; % backwards compatibility
%                 elseif strcmpi(ELECTRODES,'pointnumbers') || strcmpi(ELECTRODES,'ptsnumbers') ...
%                         | strcmpi(ELECTRODES,'numberspts') | strcmpi(ELECTRODES,'ptnumbers') ...
%                         | strcmpi(ELECTRODES,'numberpts')  | strcmpi(ELECTRODES,'ptsnums')  ...
%                         | strcmpi(ELECTRODES,'numspts')
%                     ELECTRODES = 'numpoint'; % backwards compatibility
%                 elseif strcmpi(ELECTRODES,'nums')
%                     ELECTRODES = 'numbers'; % backwards compatibility
%                 elseif strcmpi(ELECTRODES,'pts')
%                     ELECTRODES = 'on'; % backwards compatibility
%                 elseif ~strcmp(ELECTRODES,'off') ...
%                         & ~strcmpi(ELECTRODES,'on') ...
%                         & ~strcmp(ELECTRODES,'labels') ...
%                         & ~strcmpi(ELECTRODES,'numbers') ...
%                         & ~strcmpi(ELECTRODES,'labelpoint') ...
%                         & ~strcmpi(ELECTRODES,'numpoint')
%                     error('Unknown value for keyword ''electrodes''');
%                 end
%             case 'dipole'
%                 DIPOLE = Value;
%             case 'dipsphere'
%                 DIPSPHERE = Value;
%             case {'dipnorm', 'dipnormmax'}
%                 if strcmp(Param,'dipnorm')
%                     DIPNORM = Value;
%                     if strcmpi(Value,'on')
%                         DIPNORMMAX = 'off';
%                     end
%                 else
%                     DIPNORMMAX = Value;
%                     if strcmpi(Value,'on')
%                         DIPNORM = 'off';
%                     end
%                 end
%                 
%             case 'diplen'
%                 DIPLEN = Value;
%             case 'dipscale'
%                 DIPSCALE = Value;
            case 'contourvals'
                ContourVals = Value;
%             case 'pmask'
%                 ContourVals = Value;
%                 PMASKFLAG   = 1;
%             case 'diporient'
%                 DIPORIENT = Value;
%             case 'dipcolor'
%                 DIPCOLOR = Value;
%             case 'emarker'
%                 if ischar(Value)
%                     EMARKER = Value;
%                 elseif ~iscell(Value) || length(Value) > 4
%                     error('''emarker'' argument must be a cell array {marker color size linewidth}')
%                 else
%                     EMARKER = Value{1};
%                 end
%                 if length(Value) > 1
%                     ECOLOR = Value{2};
%                 end
%                 if length(Value) > 2
%                     EMARKERSIZE = Value{3};
%                 end
%                 if length(Value) > 3
%                     EMARKERLINEWIDTH = Value{4};
%                 end
%             case 'emarker2'
%                 if ~iscell(Value) || length(Value) > 5
%                     error('''emarker2'' argument must be a cell array {chans marker color size linewidth}')
%                 end
%                 EMARKER2CHANS = abs(Value{1}); % ignore channels < 0
%                 if length(Value) > 1
%                     EMARKER2 = Value{2};
%                 end
%                 if length(Value) > 2
%                     EMARKER2COLOR = Value{3};
%                 end
%                 if length(Value) > 3
%                     EMARKERSIZE2 = Value{4};
%                 end
%                 if length(Value) > 4
%                     EMARKER2LINEWIDTH = Value{5};
%                 end
%             case 'shrink'
%                 shrinkfactor = Value;
%             case 'intrad'
%                 intrad = Value;
%                 if ischar(intrad) || (intrad < MINPLOTRAD || intrad > 1)
%                     error('intrad argument should be a number between 0.15 and 1.0');
%                 end
%             case 'plotrad'
%                 plotrad = Value;
%                 if ~isempty(plotrad) && (ischar(plotrad) || (plotrad < MINPLOTRAD || plotrad > 1))
%                     error('plotrad argument should be a number between 0.15 and 1.0');
%                 end
%             case 'headrad'
%                 headrad = Value;
%                 if ischar(headrad) && ( strcmpi(headrad,'off') || strcmpi(headrad,'none') )
%                     headrad = 0;       % undocumented 'no head' alternatives
%                 end
%                 if isempty(headrad) % [] -> none also
%                     headrad = 0;
%                 end
%                 if ~ischar(headrad)
%                     if ~(headrad==0) && (headrad < MINPLOTRAD || headrad>1)
%                         error('bad value for headrad');
%                     end
%                 elseif  ~strcmpi(headrad,'rim')
%                     error('bad value for headrad');
%                 end
%             case {'headcolor','hcolor'}
%                 HEADCOLOR = Value;
%             case {'contourcolor','ccolor'}
%                 CCOLOR = Value;
%             case {'electcolor','ecolor'}
%                 ECOLOR = Value;
%             case {'emarkersize','emsize'}
%                 EMARKERSIZE = Value;
%             case {'emarkersize1chan','emarkersizemark'}
%                 EMARKERSIZE1CHAN= Value;
%             case {'efontsize','efsize'}
%                 EFSIZE = Value;
%             case 'shading'
%                 SHADING = lower(Value);
%                 if ~any(strcmp(SHADING,{'flat','interp'}))
%                     error('Invalid shading parameter')
%                 end
%                 if strcmpi(SHADING,'interp') && isempty(warningInterp)
%                     warning('Using interpolated shading in scalp topographies prevent to export them as vectorized figures');
%                     warningInterp = 1;
%                 end
            case 'noplot'
                noplot = Value;
                if ~ischar(noplot)
                    if length(noplot) ~= 2
                        error('''noplot'' location should be [radius, angle]')
                    else
                        chanrad = noplot(1);
                        chantheta = noplot(2);
                        noplot = 'on';
                    end
                end
            case 'gridscale'
                GRID_SCALE = Value;
%                 if ischar(GRID_SCALE) || GRID_SCALE ~= round(GRID_SCALE) || GRID_SCALE < 32
%                     error('''gridscale'' value must be integer > 32.');
%                 end
%             case {'plotgrid','gridplot'}
%                 plotgrid = 'on';
%                 gridchans = Value;
%             case 'plotchans'
%                 plotchans = Value(:);
%                 if find(plotchans<=0)
%                     error('''plotchans'' values must be > 0');
%                 end
%                 % if max(abs(plotchans))>max(Values) | max(abs(plotchans))>length(Values) -sm ???
            case {'whitebk','whiteback','forprint'}
                whitebk = Value;
%             case {'iclabel'} % list of options to ignore
            otherwise
                error(['Unknown input parameter ''' Param ''' ???'])
        end
    end
end

if strcmpi(whitebk, 'on')
    BACKCOLOR = [ 1 1 1 ];
end

if isempty(find(strcmp(varargin,'colormap')))
    if exist('DEFAULT_COLORMAP','var')
        cmap = colormap(DEFAULT_COLORMAP);
    else
        cmap = parula;
    end
else
    cmap = colormap;
end
if strcmp(noplot,'on'), close(gcf); end
cmaplen = size(cmap,1);

if strcmp(STYLE,'blank')    % else if Values holds numbers of channels to mark
    if length(Values) < length(loc_file)
        ContourVals = zeros(1,length(loc_file));
        ContourVals(Values) = 1;
        Values = ContourVals;
    end
end

%
%%%%%%%%%%%%%%%%%%%%%%%%%%% test args for plotting an electrode grid %%%%%%%%%%%%%%%%%%%%%%
%
% if strcmp(plotgrid,'on')
%    STYLE = 'grid';
%    gchans = sort(find(abs(gridchans(:))>0));
% 
%    % if setdiff(gchans,unique(gchans))
%    %      fprintf('topoplot_DaSh() warning: ''plotgrid'' channel matrix has duplicate channels\n');
%    % end
% 
%    if ~isempty(plotchans)
%      if intersect(gchans,abs(plotchans))
%         fprintf('topoplot_DaSh() warning: ''plotgrid'' and ''plotchans'' have channels in common\n');
%      end
%    end
% end

%
%%%%%%%%%%%%%%%%%%%%%%%%%%% misc arg tests %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
if isempty(ELECTRODES)                     % if electrode labeling not specified
  if length(Values) > MAXDEFAULTSHOWLOCS   % if more channels than default max
    ELECTRODES = 'off';                    % don't show electrodes
  else                                     % else if fewer chans,
    ELECTRODES = 'on';                     % do
  end
end

if isempty(Values)
   STYLE = 'blank';
end
[r,c] = size(Values);
% if r>1 && c>1,
%   error('input data must be a single vector');
% end
Values = Values(:); % make Values a column vector
ContourVals = ContourVals(:); % values for contour

if ~isempty(intrad) && ~isempty(plotrad) && intrad < plotrad
   error('intrad must be >= plotrad');
end

if ~strcmpi(STYLE,'grid')                     % if not plot grid only

%
%%%%%%%%%%%%%%%%%%%% Read the channel location information %%%%%%%%%%%%%%%%%%%%%%%%
% 
  if ischar(loc_file)
      [tmpeloc labels Th Rd indices] = readlocs( loc_file);
  elseif isstruct(loc_file) % a locs struct
      [tmpeloc labels Th Rd indices] = readlocs( loc_file );
      % Note: Th and Rd correspond to indices channels-with-coordinates only
  else
       error('loc_file must be a EEG.locs struct or locs filename');
  end
  Th = pi/180*Th;                              % convert degrees to radians
  allchansind = 1:length(Th);

  
  if ~isempty(plotchans)
      if max(plotchans) > length(Th)
          error('''plotchans'' values must be <= max channel index');
      end
  end

%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% channels to plot %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
if ~isempty(plotchans)
    plotchans = intersect_bc(plotchans, indices);
end
if ~isempty(Values) && ~strcmpi( STYLE, 'blank') && isempty(plotchans)
    plotchans = indices;
end
if isempty(plotchans) && strcmpi( STYLE, 'blank')
    plotchans = indices;
end

%
%%%%%%%%%%%%%%%%%%%%%%%%%%% filter channels used for components %%%%%%%%%%%%%%%%%%%%% 
%
if isfield(CHANINFO, 'icachansind') && ~isempty(Values) && length(Values) ~= length(tmpeloc)

    % test if ICA component
    % ---------------------
    if length(CHANINFO.icachansind) == length(Values)
        
        % if only a subset of channels are to be plotted
        % and ICA components also use a subject of channel
        % we must find the new indices for these channels
        
        plotchans = intersect_bc(CHANINFO.icachansind, plotchans);
        tmpvals   = zeros(1, length(tmpeloc));
        tmpvals(CHANINFO.icachansind) = Values;
        Values    = tmpvals;
        tmpvals   = zeros(1, length(tmpeloc));
        tmpvals(CHANINFO.icachansind) = ContourVals;
        ContourVals = tmpvals;
        
    end
end

%
%%%%%%%%%%%%%%%%%%% last channel is reference? %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
if length(tmpeloc) == length(Values) + 1 % remove last channel if necessary 
                                         % (common reference channel)
    if plotchans(end) == length(tmpeloc)
        plotchans(end) = [];
    end

end

%
%%%%%%%%%%%%%%%%%%% remove infinite and NaN values %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
if length(Values) > 1
    inds          = union_bc(find(isnan(Values)), find(isinf(Values))); % NaN and Inf values
    plotchans     = setdiff_bc(plotchans, inds);
end
if strcmp(plotgrid,'on')
    plotchans = setxor(plotchans,gchans);   % remove grid chans from head plotchans   
end

[x,y]     = pol2cart(Th,Rd);  % transform electrode locations from polar to cartesian coordinates
plotchans = abs(plotchans);   % reverse indicated channel polarities
allchansind = allchansind(plotchans);
Th        = Th(plotchans);
Rd        = Rd(plotchans);
x         = x(plotchans);
y         = y(plotchans);
labels    = labels(plotchans); % remove labels for electrodes without locations
labels    = strvcat(labels); % make a label string matrix
if ~isempty(Values) && length(Values) > 1
    Values      = Values(plotchans);
    ContourVals = ContourVals(plotchans);
end

%
%%%%%%%%%%%%%%%%%% Read plotting radius from chanlocs  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
if isempty(plotrad) && isfield(tmpeloc, 'plotrad'), 
    plotrad = tmpeloc(1).plotrad; 
    if ischar(plotrad)                        % plotrad shouldn't be a string
        plotrad = str2num(plotrad)           % just checking
    end
    if plotrad < MINPLOTRAD || plotrad > 1.0
       fprintf('Bad value (%g) for plotrad.\n',plotrad);
       error(' ');
    end
    if strcmpi(VERBOSE,'on') && ~isempty(plotrad)
       fprintf('Plotting radius plotrad (%g) set from EEG.chanlocs.\n',plotrad);
    end
end
if isempty(plotrad) 
  plotrad = min(1.0,max(Rd)*1.02);            % default: just outside the outermost electrode location
  plotrad = max(plotrad,0.5);                 % default: plot out to the 0.5 head boundary
end                                           % don't plot channels with Rd > 1 (below head)

if isempty(intrad) 
  default_intrad = 1;     % indicator for (no) specified intrad
  intrad = min(1.0,max(Rd)*1.02);             % default: just outside the outermost electrode location
else
  default_intrad = 0;                         % indicator for (no) specified intrad
  if plotrad > intrad
     plotrad = intrad;
  end
end                                           % don't interpolate channels with Rd > 1 (below head)
if ischar(plotrad) || plotrad < MINPLOTRAD || plotrad > 1.0
   error('plotrad must be between 0.15 and 1.0');
end

%
%%%%%%%%%%%%%%%%%%%%%%% Set radius of head cartoon %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% if isempty(headrad)  % never set -> defaults
%   if plotrad >= rmax
%      headrad = rmax;  % (anatomically correct)
%   else % if plotrad < rmax
%      headrad = 0;    % don't plot head
%      if strcmpi(VERBOSE, 'on')
%        fprintf('topoplot_DaSh(): not plotting cartoon head since plotrad (%5.4g) < 0.5\n',...
%                                                                     plotrad);
%      end
%   end
% elseif strcmpi(headrad,'rim') % force plotting at rim of map
%   headrad = plotrad;
% end

%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Shrink mode %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% if ~isempty(shrinkfactor) || isfield(tmpeloc, 'shrink'), 
%     if isempty(shrinkfactor) && isfield(tmpeloc, 'shrink'), 
%         shrinkfactor = tmpeloc(1).shrink;
%         if strcmpi(VERBOSE,'on')
%             if ischar(shrinkfactor)
%                 fprintf('Automatically shrinking coordinates to lie above the head perimter.\n');
%             else                
%                 fprintf('Automatically shrinking coordinates by %3.2f\n', shrinkfactor);
%             end
%         end
%     end
%     
%     if ischar(shrinkfactor)
%         if strcmpi(shrinkfactor, 'on') || strcmpi(shrinkfactor, 'force') || strcmpi(shrinkfactor, 'auto')  
%             if abs(headrad-rmax) > 1e-2
%              fprintf('     NOTE -> the head cartoon will NOT accurately indicate the actual electrode locations\n');
%             end
%             if strcmpi(VERBOSE,'on')
%                 fprintf('     Shrink flag -> plotting cartoon head at plotrad\n');
%             end
%             headrad = plotrad; % plot head around outer electrodes, no matter if 0.5 or not
%         end
%     else % apply shrinkfactor
%         plotrad = rmax/(1-shrinkfactor);
%         headrad = plotrad;  % make deprecated 'shrink' mode plot 
%         if strcmpi(VERBOSE,'on')
%             fprintf('    %g%% shrink  applied.');
%             if abs(headrad-rmax) > 1e-2
%                 fprintf(' Warning: With this "shrink" setting, the cartoon head will NOT be anatomically correct.\n');
%             else
%                 fprintf('\n');
%             end
%         end
%     end
% end; % if shrink
      
%
%%%%%%%%%%%%%%%%% Issue warning if headrad ~= rmax  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 

% if headrad ~= 0.5 && strcmpi(VERBOSE, 'on')
%    fprintf('     NB: Plotting map using ''plotrad'' %-4.3g,',plotrad);
%    fprintf(    ' ''headrad'' %-4.3g\n',headrad);
%    fprintf('Warning: The plotting radius of the cartoon head is NOT anatomically correct (0.5).\n')
% end
%
%%%%%%%%%%%%%%%%%%%%% Find plotting channels  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 

pltchans = find(Rd <= plotrad); % plot channels inside plotting circle

if strcmpi(INTSQUARE,'on') % interpolate channels in the radius intrad square
  intchans = find(x <= intrad & y <= intrad); % interpolate and plot channels inside interpolation square
else
  intchans = find(Rd <= intrad); % interpolate channels in the radius intrad circle only
end

%
%%%%%%%%%%%%%%%%%%%%% Eliminate channels not plotted  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 

allx      = x;
ally      = y;
% intchans; % interpolate using only the 'intchans' channels
% pltchans; % plot using only indicated 'plotchans' channels
% 
% if length(pltchans) < length(Rd) && strcmpi(VERBOSE, 'on')
%         fprintf('Interpolating %d and plotting %d of the %d scalp electrodes.\n', ...
%                    length(intchans),length(pltchans),length(Rd));    
% end;	


% fprintf('topoplot_DaSh(): plotting %d channels\n',length(pltchans));
% if ~isempty(EMARKER2CHANS)
%     if strcmpi(STYLE,'blank')
%        error('emarker2 not defined for style ''blank'' - use marking channel numbers in place of data');
%     else % mark1chans and mark2chans are subsets of pltchans for markers 1 and 2
%        [tmp1, mark1chans, tmp2] = setxor(pltchans,EMARKER2CHANS);
%        [tmp3, tmp4, mark2chans] = intersect_bc(EMARKER2CHANS,pltchans);
%     end
% end

if ~isempty(Values)
	if length(Values) == length(Th)  % if as many map Values as channel locs
		intValues      = Values(intchans);
		intContourVals = ContourVals(intchans);
        Values         = Values(pltchans);
		ContourVals    = ContourVals(pltchans);
	end;	
end;   % now channel parameters and values all refer to plotting channels only

allchansind = allchansind(pltchans);
intTh = Th(intchans);           % eliminate channels outside the interpolation area
intRd = Rd(intchans);
intx  = x(intchans);
inty  = y(intchans);
Th    = Th(pltchans);              % eliminate channels outside the plotting area
Rd    = Rd(pltchans);
x     = x(pltchans);
y     = y(pltchans);

labels= labels(pltchans,:);
%
%%%%%%%%%%%%%%% Squeeze channel locations to <= rmax %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 

squeezefac = rmax/plotrad;
intRd = intRd*squeezefac; % squeeze electrode arc_lengths towards the vertex
Rd = Rd*squeezefac;       % squeeze electrode arc_lengths towards the vertex
                          % to plot all inside the head cartoon
intx = intx*squeezefac;   
inty = inty*squeezefac;  
x    = x*squeezefac;    
y    = y*squeezefac;   
allx    = allx*squeezefac;    
ally    = ally*squeezefac;   
% Note: Now outermost channel will be plotted just inside rmax

else % if strcmpi(STYLE,'grid')
   intx = rmax; inty=rmax;
end % if ~strcmpi(STYLE,'grid')

%
%%%%%%%%%%%%%%%% rotate channels based on chaninfo %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
if strcmpi(lower(NOSEDIR), '+x')
     rotate = 0;
else
    if strcmpi(lower(NOSEDIR), '+y')
        rotate = 3*pi/2;
    elseif strcmpi(lower(NOSEDIR), '-x')
        rotate = pi;
    else rotate = pi/2;
    end
    allcoords = (inty + intx*sqrt(-1))*exp(sqrt(-1)*rotate);
    intx = imag(allcoords);
    inty = real(allcoords);
    allcoords = (ally + allx*sqrt(-1))*exp(sqrt(-1)*rotate);
    allx = imag(allcoords);
    ally = real(allcoords);
    allcoords = (y + x*sqrt(-1))*exp(sqrt(-1)*rotate);
    x = imag(allcoords);
    y = real(allcoords);
end

%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Make the plot %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% if ~strcmpi(STYLE,'blank') % if draw interpolated scalp map
%  if ~strcmpi(STYLE,'grid') %  not a rectangular channel grid
  %
  %%%%%%%%%%%%%%%% Find limits for interpolation %%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
%   if default_intrad % if no specified intrad
%    if strcmpi(INTERPLIMITS,'head') % intrad is 'head'
    xmin = min(-rmax,min(intx)); xmax = max(rmax,max(intx));
    ymin = min(-rmax,min(inty)); ymax = max(rmax,max(inty));

% %    else % INTERPLIMITS = rectangle containing electrodes -- DEPRECATED OPTION!
% %     xmin = max(-rmax,min(intx)); xmax = min(rmax,max(intx));
% %     ymin = max(-rmax,min(inty)); ymax = min(rmax,max(inty));
% %    end
%   else % some other intrad specified
%     xmin = -intrad*squeezefac; xmax = intrad*squeezefac;   % use the specified intrad value 
%     ymin = -intrad*squeezefac; ymax = intrad*squeezefac;
%   end
  %
  %%%%%%%%%%%%%%%%%%%%%%% Interpolate scalp map data %%%%%%%%%%%%%%%%%%%%%%%%
  %
  xi = linspace(xmin,xmax,GRID_SCALE);   % x-axis description (row vector)
  yi = linspace(ymin,ymax,GRID_SCALE);   % y-axis description (row vector)

%   try
%       [Xi,Yi,Zi] = griddata(inty,intx,double(intValues),yi',xi,'v4'); % interpolate data
%    %   [Xi,Yi,ZiC] = griddata(inty,intx,double(intContourVals),yi',xi,'v4'); % interpolate data
%   catch
     [Xi,Yi] = meshgrid(yi',xi);
   
     DaSh_out.Th = Th;
     DaSh_out.inty = inty;
     DaSh_out.intx = intx;
     DaSh_out.intchans = intchans;
%      DaSh_out.intValues = intValues;
     DaSh_out.Xi = Xi;
     DaSh_out.Yi = Yi; 
     DaSh_out.rmax = rmax;
     DaSh_out.plotrad = plotrad;
%      DaSh_out.chanrad = chanrad;
%      DaSh_out.chantheta = chantheta;
     DaSh_out.GRID_SCALE = GRID_SCALE;

