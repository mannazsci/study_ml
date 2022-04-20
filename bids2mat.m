function bids2mat(EEG,label_file,filepath)
% this function converts a 3D matrix data to .mat samples and saves
% the raw data, 12x12 and 6x6 interpolated grid data data in the foldername mat_files 
%
% EEG is the output of pop_epoch or eeg_regepochs for 1 subject and 1
% particular task
%
% label_file is the name of the .txt file where all the label info with the
% file location will be saved.
%
% filepath is the absolute path to the dataset where the final dataset will reside 
% for AWS s3 bucket, it could be
% filepath = 's3://openneuro.org/ds003061'
% else by default it is the present working directory (pwd)
%
% Authors: Manisha Sinha


 if isempty(filepath)
        filepath = pwd; %path to the dataset folder, default pwd
 end   

%     % delete any pre-exisiting label file with the same name
%     if isfile(label_file)
%         disp('Deleting old label file ...')
%         delete label_file
%     else
%         disp('Creating new lable file')
%     end

    if ~exist('mat_files','dir')
        mkdir('mat_files')  %mat files will be written in a new folder created in the pwd
    end
        
    subject_dir = ['mat_files/' EEG.subject];
    if ~exist(subject_dir,'dir')
        mkdir(subject_dir)
    end

    eeg_dir = [subject_dir '/eeg']
    if ~exist(eeg_dir,'dir')
        mkdir(eeg_dir)
    end
     
    
    % get the type of epoch and any other interesting field
    epoch_type = std_maketrialinfo([], EEG); 
    trial_info = struct2cell(epoch_type.datasetinfo.trialinfo')';

    num_samples = size(EEG.data,3);
    for segment_num = 1:num_samples
       filename = [ eeg_dir '/' EEG.subject '_task_' EEG.task '_run_' num2str(EEG.run) '_' num2str(segment_num) '.mat'];

        if isfile(filename)
            warning('Warning: File already exisits. Skipping...')
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

          
%          delete(poolobj)
          

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


        
           save(filename,'data','Z_12','Z_6','-mat','-v7.3','-nocompression')
           sample_filepath = fullfile(filepath,filename);

            %sample_file_name, event_type, segment number, participant info, original file name
            % label_info = [sample_filepath EEG.epoch(segment_num).eventtype segment_num EEG.BIDS.pInfo(2,:) EEG.filename ];
            if isempty(EEG.BIDS)
                label_info = [sample_filepath trial_info(end) segment_num EEG.filename];
            else
                 label_info = [sample_filepath trial_info(end) segment_num EEG.BIDS.pInfo(2,:) EEG.filename];
            end

            writetable(cell2table(label_info),label_file,'Delimiter','tab',...
                 'WriteMode','append','WriteRowNames',false,'WriteVariableNames',false,'QuoteStrings',true);
        end
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


