# Foreground-Clustering-for-Joint-Segmentation-and-Localization
Source code for the NIPS 2018 paper: The source code is tested with Matlab 2018b on Linux 18.04. This is the first version which replicates the results in Table 3 and Table 4 of paper. So, basically it provides the constraint generation code to couple the two classifiers as described in paper. The second version of code, with foreground model, will be released very soon.


# Dependencies
1) Quadratic Program solver such as Mosek. Please download  it from https://www.mosek.com/products/mosek/.
2) Please download the feature matrix file from here  https://drive.google.com/open?id=1853bRuWt-8LXqLRsbXTjkoY00Pe71pvp and save it in the directory named save_mat.
3) For now, I upload the precomputed feature matrices without any dependency on VL-Feat Library. However, future version of this code depends upon VLFEAT library

Clone the code from this repository and download the feature matrix from the link above. run_coloc_4m_mat.m is the main script that first generates the linear constraints and formulates the quadratic programme. It assumes the feature matrices are stored in save_mat directory.


If you use this code, please cite our paper as well as Joulin et. al 2010 (Discriminative Clutering for image cosegmentation)CVPR 2010.

