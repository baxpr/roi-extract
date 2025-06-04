#!/usr/bin/env bash

out_dir=../OUTPUTS

# Combine ASLROIS ROI images
if 0
cd "${out_dir}"
roi_dir=../INPUTS/ASLROIS/ROIS
fslmaths "${roi_dir}"/lh.hippoAmygLabels-T1.v21.HBT.FSvoxelSpace_ant.nii.gz -mul 1 tmp1
fslmaths "${roi_dir}"/rh.hippoAmygLabels-T1.v21.HBT.FSvoxelSpace_ant.nii.gz -mul 2 tmp2
fslmaths "${roi_dir}"/lh.hippoAmygLabels-T1.v21.HBT.FSvoxelSpace_post.nii.gz -mul 3 tmp3
fslmaths "${roi_dir}"/rh.hippoAmygLabels-T1.v21.HBT.FSvoxelSpace_post.nii.gz -mul 4 tmp4
fslmaths tmp1 -add tmp2 -add tmp3 -add tmp4 rois
rm -f tmp?.nii.gz
cat << EOF > rois-labels.csv
Label,Region
1,L_Hipp_Ant
2,R_Hipp_Ant
3,L_Hipp_Post
4,R_Hipp_Post
EOF
fi


t1=../INPUTS/fmriprep_v24/fmriprepBIDS/sub-200007109/ses-242539/anat/sub-200007109_ses-242539_space-MNI152NLin2009cAsym_desc-preproc_T1w.nii.gz

hurst=../INPUTS/hurst_v1/HURST/hurst.nii.gz

# Resample image to native ROI geom
tfm=../INPUTS/fmriprep_v24/fmriprepBIDS/sub-200007109/ses-242539/anat/sub-200007109_ses-242539_from-MNI152NLin2009cAsym_to-T1w_mode-image_xfm.h5


antsApplyTransforms \
    -i "${hurst}" \
    -r "${out_dir}/rois.nii.gz" \
    -t "${tfm}" \
    -n Linear \
    -o "${out_dir}"/resampled_hurst.nii.gz

# Extract
./extract-rois.py \
    --tgt_niigz "${out_dir}"/resampled_hurst.nii.gz \
    --roi_niigz "${out_dir}"/rois.nii.gz \
    --roilabels_csv "${out_dir}"/rois-labels.csv \
    --output_csv "${out_dir}"/rois-values.csv \
    --value_label Hurst




# Seg fault for some reason
./entrypoint.sh \
    --roi_niigz ../OUTPUTS/rois.nii.gz \
    --ants_transform "${tfm}" \
    --out_dir "${out_dir}" \
    --img_niigzs "${hurst}"

