#!/usr/bin/env bash
#
# Study specific ROI creation. hipp pfc plus TMSset

# Inputs
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in      
        --fs_subj_dir)    export fs_subj_dir="$2";    shift; shift ;;
        --fmriprep_dir)   export fmriprep_dir="$2";   shift; shift ;;
        --hurst_niigz)    export hurst_niigz="$2";    shift; shift ;;
        --out_dir)        export out_dir="$2";        shift; shift ;;
        *) echo "Input ${1} not recognized"; shift ;;
    esac
done

# Find the ROI dir in our running container
roi_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../rois" &>/dev/null && pwd -P)"

# Work in output dir
cd "${out_dir}"

# Couple of paths
export SUBJECTS_DIR=$(dirname "${fs_subj_dir}")
export subj=$(basename "${fs_subj_dir}")


# ROIs in FS native geom, stored at 
#    ${out_dir}/rois.nii.gz
#    ${out_dir}/rois-labels.csv

# Hippocampus (6):
#   Head - Maureen anterior combination
#   Body - Maureen's less the tail
#   Tail - directly the freesurfer tail
mri_binarize \
    --i "${fs_subj_dir}"/mri/lh.hippoAmygLabels.mgz \
    --o lh-hipp-MM-head.mgz \
    --match 233 235 237 239 241 243 245 \
    --binval 11
mri_binarize \
    --i "${fs_subj_dir}"/mri/lh.hippoAmygLabels.mgz \
    --o lh-hipp-MM-headbody.mgz \
    --match 234 236 238 240 242 244 246 \
    --binval 13 \
    --merge lh-hipp-MM-head.mgz
mri_binarize \
    --i "${fs_subj_dir}"/mri/lh.hippoAmygLabels.mgz \
    --o lh-hipp-MM-headbodytail-hires.mgz \
    --match 226 \
    --binval 15 \
    --merge lh-hipp-MM-headbody.mgz
mri_convert \
    --like "${fs_subj_dir}"/mri/aparc+aseg.mgz \
    -rt nearest \
    lh-hipp-MM-headbodytail-hires.mgz \
    lh-hipp-MM-headbodytail.mgz

mri_binarize \
    --i "${fs_subj_dir}"/mri/rh.hippoAmygLabels.mgz \
    --o rh-hipp-MM-head.mgz \
    --match 233 235 237 239 241 243 245 \
    --binval 12
mri_binarize \
    --i "${fs_subj_dir}"/mri/rh.hippoAmygLabels.mgz \
    --o rh-hipp-MM-headbody.mgz \
    --match 234 236 238 240 242 244 246 \
    --binval 14 \
    --merge rh-hipp-MM-head.mgz
mri_binarize \
    --i "${fs_subj_dir}"/mri/rh.hippoAmygLabels.mgz \
    --o rh-hipp-MM-headbodytail-hires.mgz \
    --match 226 \
    --binval 16 \
    --merge rh-hipp-MM-headbody.mgz
mri_convert \
    --like "${fs_subj_dir}"/mri/aparc+aseg.mgz \
    -rt nearest \
    rh-hipp-MM-headbodytail-hires.mgz \
    rh-hipp-MM-headbodytail.mgz


# ACC (2):
#   Rostral anterior cingulate from DK (aparc) 1026, 2026
mri_binarize \
    --i "${fs_subj_dir}"/mri/aparc+aseg.mgz \
    --o acc1.mgz \
    --match 1026 \
    --binval 17
mri_binarize \
    --i "${fs_subj_dir}"/mri/aparc+aseg.mgz \
    --o acc.mgz \
    --match 2026 \
    --binval 18 \
    --merge acc1.mgz


# CSF (2):
#   Lateral ventricles 4, 43
mri_binarize \
    --i "${fs_subj_dir}"/mri/aparc+aseg.mgz \
    --o csf1.mgz \
    --match 4 \
    --binval 19
mri_binarize \
    --i "${fs_subj_dir}"/mri/aparc+aseg.mgz \
    --o csf.mgz \
    --match 43 \
    --binval 20 \
    --merge csf1.mgz



# DLPFC from script (4):
#   BA46.mgz
#   BA9_in_MFG.mgz
cp -R "${FREESURFER_HOME}"/subjects/fsaverage "${SUBJECTS_DIR}"

mri_annotation2label --subject "${subj}" --hemi lh --annotation aparc --outdir aparc_lh
mri_annotation2label --subject "${subj}" --hemi rh --annotation aparc --outdir aparc_rh

for h in lh rh; do

    # Convert rostral + caudal MFG to volume and combine
    for roi in rostralmiddlefrontal caudalmiddlefrontal; do
        mri_label2vol \
            --label aparc_${h}/${h}.${roi}.label \
            --temp  "${fs_subj_dir}"/mri/nu.mgz \
            --regheader "${fs_subj_dir}"/mri/nu.mgz \
            --o ${h}_${roi}.mgz \
            --fillthresh 0.5 \
            --subject "${subj}" \
            --fill-ribbon \
            --hemi ${h}
    done
    mri_binarize \
        --i ${h}_rostralmiddlefrontal.mgz \
        --merge ${h}_caudalmiddlefrontal.mgz \
        --min 0.5 \
        --o ${h}_DK_dlpfc.mgz

    # Project BA9 and BA46 annotation from fsaverage
    mri_surf2surf \
        --srcsubject fsaverage \
        --trgsubject "${subj}" \
        --hemi ${h} \
        --sval-annot "${SUBJECTS_DIR}"/fsaverage/label/${h}.PALS_B12_Brodmann.annot \
        --tval "${fs_subj_dir}"/label/${h}.PALS_B12_Brodmann.annot
    
    # Extract BA9 and BA46 labels
    mkdir -p brod_${h}
    mri_annotation2label --subject "${subj}" --hemi ${h} --annotation PALS_B12_Brodmann --outdir brod_${h}
    
    # Convert BA9 and BA46 to volume
    for ba in 9 46; do
        mri_label2vol \
            --label brod_${h}/${h}.Brodmann.${ba}.label \
            --temp "${fs_subj_dir}"/mri/nu.mgz \
            --regheader "${fs_subj_dir}"/mri/nu.mgz \
            --o ${h}_BA${ba}.mgz \
            --fillthresh 0.5 \
            --subject "${subj}" \
            --fill-ribbon \
            --hemi ${h}
    done

    # Restrict BA9 to middle frontal gyrus
    mri_binarize \
        --i ${h}_BA9.mgz \
        --min 0.5 \
        --o ${h}_BA9_bin.mgz

    mri_binarize \
        --i ${h}_DK_dlpfc.mgz \
        --min 0.5 \
        --o ${h}_DK_bin.mgz

    mri_and \
        ${h}_BA9_bin.mgz \
        ${h}_DK_bin.mgz \
        ${h}_BA9_in_MFG.mgz

done


# Combine all ROIs and make label file. Mask other regions out of hippocampus
# (hippocampus was resampled from hires space)
mri_binarize --i lh_BA46.mgz       --min 0.5 --binval 21                 --o tmp.mgz
mri_binarize --i rh_BA46.mgz       --min 0.5 --binval 22 --merge tmp.mgz --o tmp.mgz
mri_binarize --i lh_BA9_in_MFG.mgz --min 0.5 --binval 23 --merge tmp.mgz --o tmp.mgz
mri_binarize --i rh_BA9_in_MFG.mgz --min 0.5 --binval 24 --merge tmp.mgz --o tmp.mgz
mris_calc --output tmp.mgz tmp.mgz add acc.mgz
mris_calc --output tmp.mgz tmp.mgz add csf.mgz
mri_binarize \
    --i tmp.mgz \
    --min 0.5 \
    --binval 0 \
    --binvalnot 1 \
    --o tmpmask.mgz
mris_calc --output lh-hipp-MM-headbodytail-masked.mgz lh-hipp-MM-headbodytail.mgz mul tmpmask.mgz
mris_calc --output rh-hipp-MM-headbodytail-masked.mgz rh-hipp-MM-headbodytail.mgz mul tmpmask.mgz
mris_calc --output tmp.mgz tmp.mgz add lh-hipp-MM-headbodytail-masked.mgz
mris_calc --output tmp.mgz tmp.mgz add rh-hipp-MM-headbodytail-masked.mgz
mri_convert tmp.mgz rois.nii.gz


# Find fmriprep subject and session labels
subhtml=$(ls -d "${fmriprep_dir}"/sub-*.html)
sub=$(basename "${subhtml%.html}")
sesdir=$(ls -d "${fmriprep_dir}"/"${sub}"/ses-*)
ses=$(basename "${sesdir}")

# Find transform - subject T1 to MNI space
xfm=$(ls "${fmriprep_dir}/${sub}/${ses}/anat/${sub}_${ses}_from-T1w_to-MNI152NLin2009cAsym_mode-image_xfm.h5")

# Apply transform
antsApplyTransforms \
    -i rois.nii.gz \
    -r ${roi_dir}/atlas-TMSset_space-MNI152NLin6Asym_dseg.nii.gz \
    -t "${xfm}" \
    -n NearestNeighbor \
    -o roisMNI.nii.gz

# Combine subject FS and TMSset
fslmaths roisMNI -binv mask
fslmaths ${roi_dir}/atlas-TMSset_space-MNI152NLin6Asym_dseg.nii.gz -mul mask -add roisMNI roisMNIplusTMS_orig

# ROI labels - assuming specific known values in TMSset
cat << EOF > roisMNIplusTMS-labels.tsv
index	label
1	L_DLPFC
2	R_DLPFC
3	L_Parietal
4	R_Parietal
5	R_craving1
6	L_AI_Deen
11	lh_hipp_head
12	rh_hipp_head
13	lh_hipp_body
14	rh_hipp_body
15	lh_hipp_tail
16	rh_hipp_tail
17	lh_ant_cing
18	rh_ant_cing
19	lh_lat_vent
20	rh_lat_vent
21	lh_BA46
22	rh_BA46
23	lh_BA9_in_MFG
24	rh_BA9_in_MFG
EOF

# Resample ROIs to Hurst geom
mri_convert \
    roisMNIplusTMS_orig.nii.gz \
    roisMNIplusTMS.nii.gz \
    --reslice_like "${hurst_niigz}" \
    --resample_type nearest

# Extract ROI means
extract-rois.py \
    --tgt_niigz "${hurst_niigz}" \
    --roi_niigz "${out_dir}"/roisMNIplusTMS.nii.gz \
    --roilabels_csv "${out_dir}"/roisMNIplusTMS-labels.tsv \
    --output_csv rois-values.csv \
    --value_label Hurst
