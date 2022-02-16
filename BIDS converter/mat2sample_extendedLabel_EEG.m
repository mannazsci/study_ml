function mat2sample_extendedLabel_EEG(EEG,label_file,filepath)
% this function converts a 3D matrix data to .mat samples and saves
% them in the foldername mat_files 
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
           save(filename,'data','-mat','-v7.3','-nocompression')
            
            sample_filepath = fullfile(filepath,filename);

            %sample_file_name, event_type, segment number, participant info, original file name
            label_info = [sample_filepath EEG.epoch(segment_num).eventtype segment_num EEG.BIDS.pInfo(2,:) EEG.filename ];
            writetable(cell2table(label_info),label_file,'Delimiter','tab',...
                 'WriteMode','append','WriteRowNames',false,'WriteVariableNames',false,'QuoteStrings',true);
        end
    end

   
end
