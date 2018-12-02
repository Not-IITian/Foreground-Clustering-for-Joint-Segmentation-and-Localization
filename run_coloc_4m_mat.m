 rand('seed',1);
 randn('seed',1);
clear
close all

obj_disc_classes = {'Car_89','Horse_93', 'Aero_82'};
class_names = {'Car_89'};
   
 for Im =1:numel(param_cell)     
    typeObj = class_names{Im};
         
   param.typeObj = typeObj;                         
   save_file = ['save_mat/', typeObj, '.mat'];
   load(save_file);
   
    param.wt_BoxSaliency = .001; param.max_pixels =.9; param.optim.lambda0 =.3;
    param.wt_saliency = .001; param.noBoxes = 20; param.lapWght = .001; param.lap_box = 0;
     
    param.lambda_b = .01; param.pascal_07_06 =0;   param.Utube=0; param.mu =10;
    param.no_scaling = 1 ;    param.sal_factor = 1; % this decides the weighing factor of 
                 
   exp_name = [ 'sal_', num2str(param.wt_saliency), '_sal_b_', num2str(param.wt_BoxSaliency), '_lap_', num2str(param.lapWght), '_min_', num2str(param.optim.lambda0), '_lap_b_l2_', num2str(param.lap_box), '_disc_b_', num2str(param.disc_box),'_', num2str(param.max_pixels), '_mu_', num2str( param.mu)]     
     
   param.exp_name = [exp_name, '.mat']; 
   folder_name = ['acc_val_new/',  typeObj,'/',];  
   param.res_folder_name = folder_name;
   accuracy_file = [folder_name,param.exp_name];   
      
   
   C_box = compute_box_mat(param) ;   
            
   Lap_mat = param.lapWght*lapMatrix;
   C   = Disc_mat + Lap_mat;
    C   = C ./ param.nDescr;
   descr= []; descr_im= [] ;
    
   trC     = trace(C);
    C       = C/trC;
%             sum(sum(C))/param.nDescr*param.nDescr
%          
    Lap_mat= []; lapMatrix = []; Disc_mat = [];    
    max_ratio = param.max_pixels;
           
	% set up options
     opts = optimset('Diagnostics', 'on', 'Algorithm', 'interior-point-convex');	
     no_supPix_var = numel(saliency_vec);
     param.no_supPix_var = no_supPix_var ;      
                        
     C_box = param.mu*C_box ;             
     A = blkdiag(C,C_box);
     C = []; C_box = [];
  
     N = no_supPix_var + param.nPics* param.noBoxes ; 
     sal_vec_box = param.saliency_vec_box/sum(param.saliency_vec_box) ;
     sal_vec_box = param.wt_BoxSaliency *sal_vec_box;
     sal_vec_box = param.mu*sal_vec_box;
   
     saliency_vec = saliency_vec/sum(saliency_vec);
     saliency_vec = param.wt_saliency*saliency_vec;              
    saliency_vec_joint = [saliency_vec', sal_vec_box] ;                 
    % constraints..............................      
% 	% set up inequality matrix    
% first for loop for less than case (upper bound)
     projMatrix= []; C_box=[];
       kk = 1; cum_no_supbox_vec = [0];
       Aineq = [] ;
       total_supPix_var = param.total_supPix_var ; % this is cumulative of all boxes ie. X Vector
%        tot_constraints = 2*param.nPics*param.noBoxes +no_supPix_var;
%        
%        Aineq = zeros(tot_constraints, total_supPix_var + param.nPics*param.noBoxes, 'uint8');
       bineq = [] ; num_constraints = 0;              
%     if param.no_upper_bound == 0
       for i = 1:param.nPics      
           
            cum_count_vec = [0,cumsum(im_supPix_var_cell{i})'];              
            sup_pix_before_this_img = cum_no_supbox_vec(end) ;        
            cum_no_supbox_vec = [cum_no_supbox_vec ,cum_count_vec(end)+ sup_pix_before_this_img]; % for each image   
            
            for j = 1:param.noBoxes
                supPix_vec = zeros(1,total_supPix_var);
                starting_idx = cum_no_supbox_vec(i) + cum_count_vec(j) +1;
                end_idx = cum_no_supbox_vec(i) + cum_count_vec(j+1);             
                supPix_vec(starting_idx:end_idx) = ones(1,numel(box_supPix_non_zeros{i}{j}));                 
                box_idx = (i-1)*param.noBoxes + j ;
                box_vec = zeros(1,param.nPics*param.noBoxes);
                box_vec(box_idx) = -(max_ratio)*sum(supPix_vec) ;
            
                SupPix_box_vec = [supPix_vec, box_vec] ;  
                Aineq(kk,:) = SupPix_box_vec;
                kk = kk+1;        
            end	
       end    
        
        bineq = zeros(param.nPics*param.noBoxes,1);
        num_constraints = kk-1 ;  
%     end     
       
      kk = 1; cum_no_supbox_vec = [0];    
      fg_box = 1;
    % this is for lower bound 
       for i = 1:param.nPics  
           
            cum_count_vec = [0,cumsum(im_supPix_var_cell{i})'];       
            sup_pix_before_this_img = cum_no_supbox_vec(end) ;        
            cum_no_supbox_vec = [cum_no_supbox_vec ,cum_count_vec(end)+ sup_pix_before_this_img]; % for each image
        
           for j = 1:param.noBoxes
               
              supPix_vec = zeros(1,total_supPix_var);
              starting_idx = cum_no_supbox_vec(i) + cum_count_vec(j) +1;
              end_idx = cum_no_supbox_vec(i) + cum_count_vec(j+1);            
              supPix_vec(starting_idx:end_idx) = ones(1,numel(box_supPix_non_zeros{i}{j}));
                      
              box_idx = (i-1)*param.noBoxes + j ;
              box_vec = zeros(1,param.nPics*param.noBoxes);
                       
              box_vec(box_idx) = (-1*param.optim.lambda0)*sum(supPix_vec) ;  % if foreground is considered only inside box                                
              SupPix_box_vec = -1*[supPix_vec, box_vec] ;         
              Aineq(kk+ num_constraints,:) = SupPix_box_vec;
              kk = kk +1;      
              
          end
       end
     
     bineq = [bineq; zeros(param.nPics*param.noBoxes,1)];    
     num_constraints = num_constraints + kk -1 ; % this is a golbal term to keep track of no of  constraints at any point    
 
    % add the inequality constraint that fg could be present in only one
    % box         
     box_full_vec = param.noBoxes *ones(1,param.nPics);
     box_full_vec_idx = [0, cumsum( box_full_vec)];    
     kk = 1; cum_no_supbox_vec = [0];
%    
     for i = 1:param.nPics 
         
        cum_count_vec = [0,cumsum(im_supPix_var_cell{i})'];      
        sup_pix_before_this_img = cum_no_supbox_vec(end) ;    
        cum_no_supbox_vec = [cum_no_supbox_vec ,cum_count_vec(end)+ sup_pix_before_this_img]; % for each image
        
        for j = 1:param.lW_supPix(i)                      
           active_boxes_idx = find(param.box_supPix{i}(:,j));   % active wrt the particular supPix                                        
           sup_Pix_lin_idx = [];
            
               if numel(active_boxes_idx)
                  sup_Pix_vec = zeros(1,total_supPix_var);               
                  for k = 1:numel(active_boxes_idx)
                      idx_box = active_boxes_idx(k);                  
                      non_zeros_supPix_idx = find(param.box_supPix{i}(idx_box,:));  % it gives non zero supPix idx for active box                 
                      sup_var_idx = find(non_zeros_supPix_idx==j) ;                  
                      sup_lin_idx = cum_no_supbox_vec(i) + cum_count_vec(idx_box) + sup_var_idx;                 
                      sup_Pix_lin_idx = [sup_Pix_lin_idx, sup_lin_idx];
                  end  
                  
                  sup_Pix_vec(sup_Pix_lin_idx) = 1;
                  box_vec = zeros(1,param.nPics*param.noBoxes);               
                  box_vec_idx = box_full_vec_idx(i)+ active_boxes_idx;
                  box_vec(box_vec_idx ) = -1;
                  
                  SupPix_box_vec = [sup_Pix_vec, box_vec] ;                  
                  Aineq(kk+ num_constraints,:) = SupPix_box_vec;
%                     Aineq(kk,:) = SupPix_box_vec;  % when no bounds const
                  kk = kk+1;
               end
           end
      end
            bineq = [bineq; zeros(kk-1,1)];  
            
       
     % this is for joint optimisation over (y+z)
       box_supPix_non_zeros = [];im_supPix_var_cell = [];cum_no_supbox_vec = []; C_box = [];sup_Pix_vec= [];
       A_ineq_in_y =  Aineq*Proj_box_supPix_mat ; Aineq = [];
    % setup equality matrix   
      for i = 1:param.nPics
            box_id = (i-1)*param.noBoxes  ;
            box_vec = zeros(1,param.nPics*param.noBoxes);
            box_vec(box_id+1:box_id+param.noBoxes) = 1 ;
            assert(sum(box_vec)==param.noBoxes);            
            supPi_box_vec = [zeros(1,no_supPix_var), box_vec] ;            
            Aeq(i,:) = supPi_box_vec;       
      end   
      beq = ones(param.nPics,1);    
%     clear Proj_box_supPix_mat 
      SupPix_box_vec= []; 
      [y_sol, fval, exitflag, output, lambda] = quadprog(A, saliency_vec_joint', A_ineq_in_y, bineq, Aeq, beq, zeros(1,N), ones(1,N), [], opts);   
    
      A_ineq_in_y= []; bineq = [];saliency_vec_joint= []; A= [];  Aeq = [];beq = [];C= []; C_box= [];
            
      no_supPix_var = numel(saliency_vec) ;
      supPix_var = y_sol(1:no_supPix_var) ;
      box_scores_mat = reshape(y_sol(no_supPix_var+1:end), param.noBoxes, []);
      [~, box_sol_inds] = max(box_scores_mat); % in case, more than 1 max, take the biggest
      param.box_sol_inds = box_sol_inds; 
      
      eval_coloc_fast;
         
      save(accuracy_file, 'corLoc_val');
       close all      
      clear A saliency_vec_joint A_ineq_in_y bineq Aeq beq y_sol param
        param = [];y_sol = [];
 
  
 end