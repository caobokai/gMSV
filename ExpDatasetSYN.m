classdef ExpDatasetSYN < ExpDataset
    
    methods
       function s = ExpDatasetSYN()
            s = s@ExpDataset('Synthetic', 'brain networks');
       end
       
       function [train_data, train_label, test_data, test_label] = load(...
               varargin)
            num_samples = randi(100);
            num_nodes = randi([50, 100]);
            for i = 1 : num_samples
                graphs{i} = randn(num_nodes, num_nodes);
            end;
            num_view = randi(10);
            index = [];
            for i = 1 : num_view
                view_dim = randi(100);
                index = [index view_dim];
            end;
            index = cumsum(index);
            views = randn(max(index), num_samples);
            labels = randn(1, num_samples);
            labels(labels >= 0) = 1;
            labels(labels < 0) = -1;
            train_label = labels;
            train_data{1} = graphs;
            train_data{2} = views;
            train_data{3} = index;
            test_data = [];
            test_label = [];
            return;
       end
    end
end