classdef ExpDatasetFMRI < ExpDataset
    
    methods
       function s = ExpDatasetFMRI()
            s = s@ExpDataset('fMRI', 'brain networks');
       end
       
       function [train_data, train_label, test_data, test_label] = load(...
               varargin)
            test_data = [];
            test_label = [];
            load('../fMRI_multi.mat');
            train_label = label;
            train_data{1} = data;
            train_data{2} = views;
            train_data{3} = index;
            return;
       end
    end
end