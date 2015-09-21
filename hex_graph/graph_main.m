clear all; close all;

addpath(genpath('../../hex_graph-master'));
addpath('../');


% % ----- load the data -----
% load the label name
t = load('../total_label.mat');

% load prob & fc8 data
% prob_data: 205 x 2000 x 205 (feature x data x scene)
% fc8_data : 205 x 2000 x 205 (feature x data x scene)
load('../feature_data_2000.mat');

% load ground truth
% groundtruth = {[1],[1,2],[1,3],[1,3,4],[1,5],[1,2,6],[1,2,7],[1,2,8],[1,2,9],[1,3,10],[1,3,4,11],[1,3,4,12],...
%     [1,2,6,13],[1,2,6,14],[1,2,6,15],[1,2,6,16],[1,2,7,17],[1,2,7,18],[1,2,8,19],[1,2,8,20],[1,2,21],[1,2,22],...
%     [1,3,10,23],[1,3,10,24],[1,3,10,25],[1,3,10,26],[1,3,10,27],[1,3,10,28],[1,3,4,11,29],[1,3,4,11,30],[1,3,4,12,31],...
%     [1,3,4,12,32],[1,3,4,12,33],[1,3,4,12,34],[1,3,4,12,35],[1,3,36],[1,3,37],[1,3,38],[1,3,39],[1,3,40]};
% groundtruth 1*40 cell
% gt_scene 1*205 double
load('../gt_scene.mat'); % gt_scene , groundtruth

% % ----- data setting ----
% set the parameter
data_len = size(prob_data,2);
train_amt = round(data_len*0.8); % 2000 -> 1600
test_amt = data_len - train_amt;

% set hierarchy adjacency matrix
adj_mat = genAdj( 40 , 'exclusive');
adj_mat = setHier( adj_mat , 6 , [13,14,15,16] ); % home
adj_mat = setHier( adj_mat , 7 , [17,18] ); % work_place
adj_mat = setHier( adj_mat , 8 , [19,20] ); % store
adj_mat = setHier( adj_mat , 2 , [6,7,8,21,22] ); % indoor
adj_mat = setHier( adj_mat , 10 , [23,24,25,26,27,28] ); % building
adj_mat = setHier( adj_mat , 11 , [29,30] ); % plants
adj_mat = setHier( adj_mat , 12 , [31:1:35] ); % water
adj_mat = setHier( adj_mat , 4 , [11:1:12 36:1:40] ); % landscape
adj_mat = setHier( adj_mat , 3 , [10,4] ); % outdoor
adj_mat = setHier( adj_mat , 1 , [2,3,9,5] ); % root
E_h = logical(adj_mat);

% set Exclusive adjacency matrix
adj_mat = genAdj( 40 , 'exclusive');
adj_mat = setRela( adj_mat , 6 , 7 ); % work_place - home
adj_mat = setRela( adj_mat , 2 , [5,9] ); % indoor - sports/industrial
adj_mat = setRela( adj_mat , 38 , 39 ); % mountain - ice
adj_mat = setRela( adj_mat , 31 , 35 ); % coast - ocean
adj_mat(1,:) = zeros(1,40);
adj_mat(:,1) = zeros(40,1);
E_e = logical(adj_mat);
% E_e = E_e | E_e';

% data pre-process
root_s = [1,2,3,5:1:22,24,25,26,28:1:38,40:1:49,51:1:63,65,66,...
    67,69:1:75,77:1:81,83:1:94,96:1:99,101:1:119,121:1:138,140,142,143,145,...
    147,148,150:1:158,160,162,163,164,166:1:172,174:1:185,189,190,194,195,196,...
    198,199,201,202,205];

for i = 1:5
    
    data = prob_data(:,i,1);
    sum_prob = sumProb_p(data);
    label = gt_scene(1);
    
    % show original data
    fprintf('  raw scores: ');
    fprintf('%.3f ', sum_prob);
    fprintf('\n');
    fprintf('  label: %d\n', label);
    
    % run the hex graph
    G = hex_setup(E_h, E_e);
    back_propagate = true;
    [loss, gradients, p_margin, p0] = hex_run(G, sum_prob, label, back_propagate);
    
    % show the result
    fprintf('Junction Tree results\n');
    fprintf('  marginal probability: ');
    fprintf('%.3f ', [p_margin; p0]);
    fprintf('\n');
    fprintf('  loss: %.3f\n', loss)
    fprintf('  gradients: ');
    fprintf('%.3f ', gradients');
    fprintf('\n');
end

% reference
% function test_passed = run_test_example(E_h, E_e, f, l)
% 
% 
% 
% 
% 
% [loss_bf, gradients_bf, p_margin_bf, p0_bf] = hex_test.brute_force_run(G, f, l);
% fprintf('Brute Force results\n');
% fprintf('  marginal probability: ');
% fprintf('%.3f ', [p_margin_bf; p0_bf]);
% fprintf('\n');
% fprintf('  loss: %.3f\n', loss_bf)
% fprintf('  gradients: ');
% fprintf('%.3f ', gradients_bf');
% fprintf('\n');
% 
% eps = 1e-4;
% p_margin_diff = abs([p_margin; p0] - [p_margin_bf; p0_bf]);
% loss_diff = abs(loss - loss_bf);
% gradients_diff = gradients_bf - gradients;
% 
% fprintf('probability difference: ');
% fprintf('%.3f ', p_margin_diff);
% fprintf('\n');
% fprintf('loss difference: %.3f\n', loss_diff);
% fprintf('gradient difference: ');
% fprintf('%.3f ', gradients_diff);
% fprintf('\n');
% 
% test_passed = all(p_margin_diff <= eps) ...
%   && all(loss_diff <= eps) ...
%   && all(gradients_diff <= eps);
% 
% if test_passed
%   fprintf('TEST PASSED\n');
% else
%   warning('TEST FAILED');
% end
% 
% end