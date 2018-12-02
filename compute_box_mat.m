function C_box = compute_box_mat(param)
% net = load('imagenet-caffe-alex.mat') ;

     Box_feat_file = ['./box_feat/Alex_feat_',  param.typeObj, '_', num2str(param.noBoxes),'.mat'];
     load(Box_feat_file, 'feat')
    X = feat;    
    disp('Computing ridge regression matrix for boxes...')
    nPics = param.nPics ;
    no_box =  param.noBoxes ; 

    N = size(X,1);
    assert(N ==nPics*no_box );
    P = sparse(1:N, 1:N, 1) - 1 / N;
    PX = P * X;
    D_box = P' * (sparse(1:N, 1:N, 1) - PX * (PX'*PX + N * param.lambda_b * sparse(1:size(X,2), 1:size(X,2), 1))^-1 * PX') * P;


trC     = trace(D_box);
C_box       = D_box/trC;




    