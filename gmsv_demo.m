% Reference:
% Bokai Cao, Xiangnan Kong, Jingyuan Zhang, Philip S. Yu and Ann B. Ragin. 
% Mining Brain Networks using Multiple Side Views for Neurological Disorder
% Identification. In ICDM 2015.
%
% Dependency:
% [1] Xifeng Yan and Jiawei Han. 
% gSpan: Graph-Based Substructure Pattern Mining. In ICDM 2002.
% [2] Chih-Chung Chang and Chih-Jen Lin. 
% LIBSVM: A Library for Support Vector Machines.
% In ACM Transactions on Intelligent Systems and Technology 2011.
% Software available at http://www.csie.ntu.edu.tw/~cjlin/libsvm

clear
clc

addpath(genpath('./libsvm-3.22/matlab'));
javaaddpath gSpan/bin/java

dataset = ExpDatasetFMRI();
[train_data, train_label] = dataset.load();
test_data = train_data; % for demo purpose

classifier = ExpClassifierGMSV();
classifier.threshold = 0.9;
classifier.min_sup = 50;
classifier.num_features = 100;

[outputs, pre_labels, model] = classifier.classify(...
    train_data, train_label, test_data);
