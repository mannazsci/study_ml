function label_info = mat2sample(m_data, labels, filepath)
% this function converts a 3D mat file to grey scale 2-s .mat samples and saves
% them in the current folder by default
%
% filepath is the absolute path to the dataset where the final dataset will reside 
% for AWS s3 bucket, it could be (e.g. for training data)
% filepath = 's3://childminddata/train'
% else by default it is the present working directory (pwd)
  
  
    subjects = string(labels(:,1)); % The first column of labels contains the subject identifier
   % foldernames =unique(subjects);
 %   num_subjects = length(foldernames);
   

%     if ~exist(foldernames(1),'dir')
%         cellfun(@mkdir,foldernames);
%     end

     if isempty(filepath)
        filepath = pwd; %path to the dataset folder, default pwd
    end

    num_samples = size(m_data,3);
    subject_sample_count = 1;

    for i = 1:num_samples
        
        filename = [subjects(i)+'_sample_'+num2str(subject_sample_count)+'.mat'];
        data = m_data(:,:,i);
     %   save(filename,'data');
        label_col1 = fullfile(filepath,filename);
        label_info(i,:) = [label_col1 labels(i,:) subject_sample_count];

%         writematrix(label_info,label_file,'Delimiter','tab','WriteMode','append');
    
        if  i<num_samples && subjects(i)==subjects(i+1)
            subject_sample_count = subject_sample_count+1;
        else
           subject_sample_count = 1;
        end

    end

%     movefile(label_file, fileparts(pwd));
end
