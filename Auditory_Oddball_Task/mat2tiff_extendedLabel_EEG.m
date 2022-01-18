function mat2tiff_extendedLabel_EEG(EEG,label_file,filepath)
% this function converts a 3D matrix data to grey scale tiff images and saves
% them in the foldername tif_files 
%
% EEG is the output of pop_epoch for 1 subject and 1
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

    if ~exist('tif_files','dir')
        mkdir('tif_files')  %tif files will be written in a new folder created in the pwd
    end
     
    % get the type of epoch and any other interesting field
    epoch_type = std_maketrialinfo([], EEG); 
    trial_info = struct2cell(epoch_type.datasetinfo.trialinfo')';

    num_samples = size(EEG.data,3);
    for i = 1:num_samples
       filename = ['tif_files/' EEG.subject '_task_' EEG.task '_run_' num2str(EEG.run) '_' num2str(i) '.tif'];

        if isfile(filename)
            warning('Warning: File already exisits. Skipping...')
        else
            t = Tiff(filename, 'w');
            tagstruct.ImageLength = size(EEG.data,1);
            tagstruct.ImageWidth = size(EEG.data,2);
            tagstruct.Photometric = 1; %Tiff.Photometric.MinIsWhite;
            tagstruct.BitsPerSample = 32;
            tagstruct.SamplesPerPixel = 1; %3 for RGB
            tagstruct.Software = 'appasamy-sc';
            tagstruct.SampleFormat = 3;
            tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
            t.setTag(tagstruct);
            
            t.write(single(EEG.data(:,:,i)));
            t.close();  
            
            label_col1 = fullfile(filepath,filename);
            label_info = [label_col1 EEG.BIDS.pInfo(2,:) i EEG.task EEG.run trial_info(i,:)];
            writetable(cell2table(label_info),label_file,'Delimiter','tab',...
                 'WriteMode','append','WriteRowNames',false,'WriteVariableNames',false);
        end
    end
   
end
