

nPics = numel(param.imFileList);
eval_path = ['eval_coloc_files/'];
overlap_list = zeros(nPics,1);
% success or not (0: fail, 1: success, 2: negative class)
success_list = zeros(nPics, 1, 'uint8');
  
for iIm = 1:nPics
   [~ ,file_name, ~] = fileparts(param.imFileList{iIm});
    GT_file = [eval_path, typeObj, '/',file_name, '.mat'] ;  
    load(GT_file)
    gt_boxes = cell2mat(bbox_list');
	ngtboxes = size(gt_boxes, 1);
	% ignore images without GT boxes (or negative images)
	if isempty(gt_boxes)
		overlap_list(iidx, :) = -1;
		success_list(iidx, :) = 2;
		continue;
    end
	% box to rect
	gt_rects = gt_boxes;
    if param.pascal_07_06
        gt_rects(:, 3:4) = gt_rects(:, 3:4) - gt_rects(:, 1:2) + 1;
    end
	ngtrect = size(gt_rects, 1);	
		% load localization results ('saliency', 'conf_acc')	
        best_rect = param.boxes(iIm).coords(box_sol_inds(iIm),:);
		best_rect(:, 3:4) = best_rect(:, 3:4) - best_rect(:, 1:2) + 1;
		% intersection/union areas
		int_area = rectint(best_rect, gt_rects);
		uni_area = zeros(1, ngtrect);
		for gidx = 1 : ngtrect
			uni_area(gidx) = prod(best_rect(3:4)) + prod(gt_rects(gidx, 3:4));
		end
		uni_area = uni_area - int_area;
		ovl_ratio = int_area ./ uni_area;
		overlap_list(iIm) = max(ovl_ratio);
		if max(ovl_ratio) > 0.5
			success_list(iIm) = 1;
		end
end
% summary per class
fprintf('Summarize performance\n');

ioverlap_list = overlap_list(overlap_list(:, 1) >= 0);	% ignore negative images
cls_nimage = size(overlap_list, 1);
	
corLoc_val = sum(overlap_list>0.5, 1) ./ cls_nimage 

