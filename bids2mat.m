function bids2mat(EEG,label_file,folder)
% this function converts a 3D matrix data to .mat samples and saves
% the raw data, 12x12 and 6x6 interpolated grid data data in the foldername mat_files
%
% EEG is the output of pop_epoch or eeg_regepochs for 1 subject and 1
% particular task
%
% label_file is the name of the .csv file where all the label info with the
% file location will be saved.
%
% filepath is the absolute path to the dataset where the final dataset will reside
% for AWS s3 bucket, it could be
% filepath = 's3://openneuro.org/ds003061'
%
%

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

subject_dir = fullfile(folder, 'mat_files', EEG.subject);
if ~exist(subject_dir,'dir')
    mkdir(subject_dir)
end

eeg_dir = fullfile(subject_dir, 'eeg');
if ~exist(eeg_dir,'dir')
    mkdir(eeg_dir)
end


% get the type of epoch and any other interesting field
epoch_type = std_maketrialinfo([], EEG);
trial_info = struct2cell(epoch_type.datasetinfo.trialinfo')';

num_samples = size(EEG.data,3);
for segment_num = 1:num_samples
    filename = [ eeg_dir filesep EEG.subject ];
    if ~isempty(EEG.run) filename = [ filename '_run_' num2str(EEG.run) ]; end
    if ~isempty(EEG.session) filename = [ filename '_session_' num2str(EEG.session) ]; end
    filename = [ filename '.mat' ];

    %if isfile(filename)
    %    warning('Warning: File already exisits. Skipping...')
    %else

        data = EEG.data(:,:,segment_num);
        num_timestamps = size(data,2);
        Z_12 = zeros(12,12,num_timestamps);
        Z_6 = single(zeros(6,6,num_timestamps));

        parfor time_step = 1:num_timestamps
            % topoplot_DaSh default gridscale = 12
            [~,Z_12(:,:,time_step),~,~,~] = topoplot_DaSh(data(:,time_step)', EEG.chanlocs,  'chaninfo', EEG.chaninfo);
            %             [~,Z_6(:,:,time_step),~,~,~] = topoplot_DaSh(EEG.data(:,time_step)', EEG.chanlocs, 'whitebk', 'on', 'gridscale', 6, 'numcontour', 0,  'chaninfo', EEG.chaninfo);
        end


        %%          z-score Z_12
        %           max_z12 = max(max(max(Z_12)));
        %           min_z12 = min(min(min(Z_12)));
        %           Z_12 =  (Z_12 - min_z12)./(max_z12 -min_z12);
        %%
        %change from double to single precision
        Z_12 = single(Z_12);

        %convert all NaNs to zeros
        Z_12(isnan(Z_12))=0;

        % calculate Z_6
        Z_6 = imresize(Z_12,0.5,'method','nearest');

        save(filename,'data','Z_12','Z_6','-mat','-v7.3','-nocompression')
        sample_filepath = fullfile(folder,filename);

        %sample_file_name, event_type, segment number, participant info, original file name
        % label_info = [sample_filepath EEG.epoch(segment_num).eventtype segment_num EEG.BIDS.pInfo(2,:) EEG.filename ];
        label_info = [sample_filepath trial_info(end) segment_num EEG.filename];

        writetable(cell2table(label_info),label_file,'Delimiter','tab',...
            'WriteMode','append','WriteRowNames',false,'WriteVariableNames',false,'QuoteStrings',true);
    %end
end
