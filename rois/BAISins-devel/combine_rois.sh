#!/usr/bin/env bash

# Deen dAI (left and right)
# Deen vAI (left and right)
# Deen PI (left and right)
# dAmy (left and right)
# aMCC (left and right)
# pACC (left and right)
# sgACC (left and right)

# Label file
cat << EOF > ../atlas-BAISins_dseg.tsv
index	label
1	dAI_L
2	dAI_R
3	vAI_L
4	vAI_R
5	PI_L
6	PI_R
7	dAmy_L
8	dAmy_R
9	aMCC_L
10	aMCC_R
11	pACC_L
12	pACC_R
13	sgACC_L
14	sgACC_R
EOF

fslmaths InsulaCluster_K3_L-dAI -bin -mul 1 tmp
fslmaths InsulaCluster_K3_R-dAI -bin -mul 2 -add tmp tmp

fslmaths InsulaCluster_K3_L-vAI -bin -mul 3 -add tmp tmp
fslmaths InsulaCluster_K3_R-vAI -bin -mul 4 -add tmp tmp

fslmaths InsulaCluster_K3_L-PI -bin -mul 5 -add tmp tmp
fslmaths InsulaCluster_K3_R-PI -bin -mul 6 -add tmp tmp

fslmaths Kittleson_Sphere_dAmy_-27_3_-12_L -bin -mul 7 -add tmp tmp
fslmaths Kittleson_Sphere_dAmy_27_3_-12_R -bin -mul 8 -add tmp tmp

fslmaths Kittleson_Sphere_aMCC_-9_22_33_L -bin -mul 9 -add tmp tmp
fslmaths Kittleson_Sphere_aMCC_9_22_33_R -bin -mul 10 -add tmp tmp

fslmaths Kittleson_Sphere_pACC_-13_44_0_L -bin -mul 11 -add tmp tmp
fslmaths Kittleson_Sphere_pACC_13_44_0_R -bin -mul 12 -add tmp tmp

fslmaths Kittleson_Sphere_sgACC_-2_14_-6_L -bin -mul 13 -add tmp tmp
fslmaths Kittleson_Sphere_sgACC_2_41_-6_R -bin -mul 14 -add tmp tmp

mv tmp.nii.gz ../atlas-BAISins_space-MNI152NLin6Asym_res-02_dseg.nii.gz



