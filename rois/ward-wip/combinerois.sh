#!/usr/bin/env bash

# Labels:
# cravingchange_cluster1.nii.gz
#   39  craving1
#
# Deen_L-AI_union.nii.gz
#    1  Deen_L-AI_union
#
# TMS.nii.gz
#    1  L_DLPFC
#    2  R_DLPFC
#    3  L_Parietal
#    4  R_Parietal

# List the labels in use for each source image
for x in \
    cravingchange_cluster1.nii.gz \
    Deen_L-AI_union.nii.gz \
    TMS.nii.gz \
; do
    echo " "
    echo ROI SET ${x}
    fslstats -K ${x} ${x} -m -v
done

# Start with TMS. Make a "keep" multiplicative mask to exclude its voxels from others
fslmaths TMS -binv mask

# Add the others
fslmaths cravingchange_cluster1 -bin -mul mask -mul 5 -add TMS wip1
fslmaths wip1 -binv mask
fslmaths Deen_L-AI_union -bin -mul mask -mul 6 -add wip1 ../atlas-TMSset_space-MNI152NLin6Asym_dseg.nii.gz

# Labels
cat << EOF > ../atlas-TMSset_dseg.tsv
index	label
1	L_DLPFC
2	R_DLPFC
3	L_Parietal
4	R_Parietal
5	R_craving1
6	L_AI_Deen
EOF
