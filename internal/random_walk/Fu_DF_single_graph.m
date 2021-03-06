function [lambdacoef, phi] = Fu_DF_single_graph( L,  data, opts)
%
% [lambdacoef, phi] = Fu_DF_single_graph( L,  data, opts)
%
%
% opts = getPrmDflt(opts,{'no',6180,'metric','Gaussian', ...
%                                    'c',exp(0), 'k',300, 'alpha',0.3, ...    % parameters for Knn graph structure
%                                           'delta',1/100, 't',5},-1);  % parameters for diffusion metric:
%
% Diffusion metric
%
% Derived from  [sLabels, Zmat, sL1Labels] = Fu_rw_single_graph( L,  data, opts)
%
% use Gaussian similarity as the weights on the spherical space on the projected CCA 
%
%
% derived from 
%               [sLabels, Zmat, sL1Labels] = Fu_singlesslL2_v2( L,  data, opts)
%
%
% [sLabels, cLabels] = mvssl_v2(v1, v2, v3, L, k, alpha, no)
% label propagation on multiple graphs respectively, and on the combined
% graph.
%
% INPUT:
% no - the number of testing data points. 
% pn - the prototype number (initial labeling number). In our case, each
%      class only has one prototype.
% d  - the dimension of the feature vector in the common latent space.
% data - d x (no+pn) data matrix of view-1
%      We put the feature vectors of the prototype instances to 
%      the end of the data matrix on each view.
% L  - (no+pn) x pn labeling matrix. We use the 1-0 representation for the initial labels.
% k  - the parameter for k-nearest-neighbor graph construction.
% alpha - the parameter of the manifold regularization term in label propagation.
% 
% OUTPUT:
% sLabels - label propagation result on each view (model)
% cLabels - label propagation result on the multi-graph

% setting default parameters:
% cita is the normalization parameters for each graph.
opts = getPrmDflt(opts,{'no',6180,'metric','Gaussian', ...
                                    'c',exp(0), 'k',10, 'alpha',0.3, ...    % parameters for Knn graph structure
                                           'delta',1/100, 't',2,'e',0.15},-1);  % parameters for diffusion metric:

k = opts.k; alpha = opts.alpha; no = opts.no; c = opts.c;


 gNum = length(data);
% vdata = cell(gNum,1);
% vdata{1} = v1;
% vdata{2} = v2;
% vdata{3} = v3;


gK = cell(gNum, 1);
gvol = zeros(gNum, 1);
X_l2norm = cell(gNum, 1);
dN = length(L);
    
% do normalization--> to spherical space:
X = data;
XtX = X'*X;
data = sqrt(diag(XtX));    
%    gK{i} = X./(X_l2norm{i}*X_l2norm{i}');
data = X./repmat(data', size(X,1),1);

%% construct the multiple graphs.
%for i = 1:gNum,
    % compute the similarity, the inverse of the distance in our current
    % implementation.
dist = slmetric_pw(data, data,'sqdist');
  %  gK{i} = 1./dist; %1./(1+dist);
md = median(dist(:));

  
%      gK{i} = 1./(1+dist/(2*opts.cita(i)));
 %     gK{i} = 1./(1+dist/(c*md));
%W = exp(-dist./(c*md));


W=exp(-dist./opts.e);

% tanh kernel:
%a1=10; a2 =1;
%W= (tanh(a1*(dist/md-a2))+1)/2;



% % knn graph
% dN = size(W,1);
% Wk = zeros(size(W));
%     for j = 1:dN,
%         % collect the k-nearest neighbors
%         [~, indx] = sort(W(j,:), 'descend');
%         ind = indx(2:k+1);
%         % only store the k-nearest neighbors in the similarity matrix
%         Wk(j, ind) = W(j, ind);
%     end;
%     % compute the final symmetric similarity matrix
% Wk = (Wk+Wk')/2; clear Kn;

Wk=W; 

drow = sum(Wk,2);
ndim = length(drow);
% do normalization for transition matrix:
P = Wk./repmat(drow,1,ndim );

P = (P+P')/2;

% gKnn is the similarity of one graph:
%Pt = power(P,opts.t); % X.^Y
Pt = mpower(P,opts.t);

[V,D]= eig(Pt);

lambda = abs(diag(D));
thre =opts.delta*abs(lambda(1));

flg = lambda>thre;
idx = find(flg~=0);
index = idx(end);

phi = V(:,1:index);
lambdacoef = lambda(1:index);


