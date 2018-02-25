classdef ExpClassifierGMSV < ExpClassifier
    
    properties
        miner;
        baseLearner;
        threshold = 0.5;
        min_sup = 50;
        num_features = 100;
    end
    
    methods
        function s = ExpClassifierGMSV()
            s = s@ExpClassifier('gMSV', 'classification');
            s.miner = de.parmol.GSpan.GSpan;
            s.baseLearner = ExpClassifierSVM();
        end
        
        function [outputs, pre_labels, s] = classify(...
                s, train_data, train_label, test_data)
            index = train_data{3};
            train_view = train_data{2};
            train_data = train_data{1};
            test_view = test_data{2};
            test_data = test_data{1};
            t = cputime;
            num_train = size(train_data, 2);
            num_test = size(test_data, 2);
            num_nodes = size(train_data{1}, 1);
            
            % node index
            str_node = cell(num_nodes, 1);
            for k = 1 : num_nodes
                str_node{k} = ['v ' num2str(k - 1) ' ' num2str(k - 1)];
            end
            
            TrG = cell(num_train, 1);
            for k = 1 : num_train
                % thresholding
                train_data{k}(abs(train_data{k}) <= s.threshold) = 0;
                [eg_row, eg_col, eg_pr] = find(train_data{k});
                idx = eg_row >= eg_col;
                eg_row(idx) = []; eg_col(idx) = []; eg_pr(idx) = [];
                idx = eg_pr < 0;
                eg_row(idx) = []; eg_col(idx) = []; eg_pr(idx) = [];
                % edge label
                eg_label = num_nodes .* eg_row + eg_col;
                num_edge = length(eg_pr);
                str_edges = cell(num_edge, 1);
                for x = 1 : num_edge
                    str_edges{x} = [
                        'e ' num2str(eg_row(x) - 1) ...
                        ' ' num2str(eg_col(x) - 1) ...
                        ' ' num2str(eg_label(x)) ...
                        ' ' num2str(1)];
                end
                TrG{k} = [str_node; str_edges];
            end
            
            TeG = cell(num_test, 1);
            for k = 1 : num_test
                % thresholding
                test_data{k}(abs(test_data{k}) <= s.threshold) = 0;
                [eg_row, eg_col, eg_pr] = find(test_data{k});
                idx = eg_row >= eg_col;
                eg_row(idx) = []; eg_col(idx) = []; eg_pr(idx) = [];
                idx = eg_pr < 0;
                eg_row(idx) = []; eg_col(idx) = []; eg_pr(idx) = [];
                % edge label
                eg_label = num_nodes .* eg_row + eg_col;
                num_edge = length(eg_pr);
                str_edges = cell(num_edge, 1);
                for x = 1 : num_edge
                    str_edges{x} = [
                        'e ' num2str(eg_row(x) - 1) ...
                        ' ' num2str(eg_col(x) - 1) ...
                        ' ' num2str(eg_label(x)) ...
                        ' ' num2str(1)];
                end
                TeG{k} = [str_node; str_edges];
            end
     
            % find frequent subgraphs
            [train_data, test_data] = gSpan(TrG, TeG, s.min_sup);
            
            % find discriminative subgraphs
            [order, ~] = gSide(...
                train_data, train_view, train_label, index, ...
                test_data, test_view);
            k = s.num_features;
            train_graph = train_data(order(1 : k), :);
            test_graph = test_data(order(1 : k), :);
            train_data = [train_graph; train_view];
            test_data = [test_graph; test_view];
            s.time_train = cputime - t;
            
            [outputs, pre_labels] = s.baseLearner.classify(...
                train_data, train_label, test_data);
            s.time = cputime - t;
            s.time_test = s.time - s.time_train;
            
            % save running state discription
            s.abstract = [
                s.name  '(' ...
                '-time:' num2str(s.time) ...
                '-time_train:' num2str(s.time_train) ...
                '-time_test:' num2str(s.time_test) ...
                '-base:' s.baseLearner.name ...
                '-dim:' num2str(s.num_features) ')'];
        end
    end
end

function [train_fea, test_fea] = gSpan(train_data, test_data, min_sup)
    minertype = 'de.parmol.';
    miner = eval([minertype 'GSpan.GSpan']);
    
    num_train = length(train_data);
    num_test = length(test_data);
    data = [train_data; test_data];
    num_data = num_train + num_test;

    % prepare inputs for gSpan
    class_data = cell(num_data, 1);
    graph_data = [];
    for k = 1 : num_data
        if k <= num_train
            class_data{k} = [num2str(k-1) ' => 1.0,0.0'];
        else
            class_data{k} = [num2str(k-1) ' => 0.0,1.0'];
        end
        graph_data = [graph_data; {['t # ' num2str(k-1)]}; data{k}];
    end
    
    class_filename = ['gSpan_class.' num2str(rand(1))];
    cell2file(class_data, class_filename);
    graph_filename = ['gSpan_graph.' num2str(rand(1))];
    cell2file(graph_data, graph_filename);
    
    % run gSpan
    cmd = [
        '-minimumFrequencies=' num2str(min_sup) '%,0 ' ...
        '-maximumFrequencies=100%,100% ' ...
        '-parserClass=' minertype 'parsers.LineGraphParser ' ...
        '-graphFile=' graph_filename ' ' ...
        '-classFrequencyFile=' class_filename ' ' ...
        '-closedFragmentsOnly=false'];
    features = miner.start2(cmd);
    features(:, end) = [];
    features = double(features);
    train_fea = features(:, 1 : num_train);
    test_fea = features(:, num_train + 1 : end);
    
    % clean up
    delete(class_filename, graph_filename);
end

function cell2file(T, filename)
    fid = fopen(filename, 'w');
    n = length(T);
    for i = 1 : n
        fprintf(fid, '%s\r\n', T{i});
    end
    fclose(fid);
end

function [order, evals] = gSide(...
        train_data, train_view, train_label, index, ...
        test_data, test_view)
    X = [train_data test_data];
    V = [train_view test_view];
    num_train = size(train_data, 2);
    num_test = size(test_data, 2);
    n = size(X, 2);
    numk = length(index);
    index = [0 index];
    for i = 1 : numk
      fstart(i) = index(i) + 1;
      fend(i) = index(i + 1);
    end
    num_p = sum(train_label == 1);
    num_n = sum(train_label == -1);
    nc = num_p * num_n * 2;
    nm = num_p ^ 2 + num_n ^ 2;
    M = train_label' * train_label;
    N = zeros(size(M));
    N(M == 1) = 1 / nm;
    N(M == -1) = -1 / nc;
    W = [N zeros(num_train, num_test); ...
        zeros(num_test, num_train) zeros(num_test, num_test)];
    for k = 1 : numk
        K{k} = zeros(n);
        for i = 1 : n
            for j = 1 : n
                K{k}(i, j) = exp(-1 / (index(k + 1) - index(k)) ...
                    * sum((V(fstart(k) : fend(k), i) - ...
                    V(fstart(k) : fend(k), j)) .^ 2));
            end;
        end;
        K{k} = K{k} - mean(K{k}(:));
        nc = sum(sum(K{k} < 0));
        nm = sum(sum(K{k} >= 0));
        K{k}(K{k} < 0) = -1 / nc;
        K{k}(K{k} >= 0) = 1 / nm;
    end;
    for k = 1 : numk
        W = W + K{k};
    end;
    [dim, ~] = size(X);
    D = diag(sum(W, 2));
    L = D - W;
    for d = 1 : dim
        tmp_evals(d) = X(d, :) * L * X(d, :)';
    end
    [evals, order] = sort(real(tmp_evals), 'ascend');
end
