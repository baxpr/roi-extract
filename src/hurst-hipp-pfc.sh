#!/usr/bin/env bash
#
# Study specific ROI extraction

# Inputs
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in      
        --fs_subj_dir)    export fs_subj_dir="$2";    shift; shift ;;
        --fmriprep_dir)   export fmriprep_dir="$2";   shift; shift ;;
        --hurst_niigz)    export hurst_niigz="$2";    shift; shift ;;
        --out_dir)        export out_dir="$2";        shift; shift ;;
        --label_info)     export label_info="$2";     shift; shift ;;
        *) echo "Input ${1} not recognized"; shift ;;
    esac
done

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
    --binval 1
mri_binarize \
    --i "${fs_subj_dir}"/mri/lh.hippoAmygLabels.mgz \
    --o lh-hipp-MM-headbody.mgz \
    --match 234 236 238 240 242 244 246 \
    --binval 3 \
    --merge lh-hipp-MM-head.mgz
mri_binarize \
    --i "${fs_subj_dir}"/mri/lh.hippoAmygLabels.mgz \
    --o lh-hipp-MM-headbodytail-hires.mgz \
    --match 226 \
    --binval 5 \
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
    --binval 2
mri_binarize \
    --i "${fs_subj_dir}"/mri/rh.hippoAmygLabels.mgz \
    --o rh-hipp-MM-headbody.mgz \
    --match 234 236 238 240 242 244 246 \
    --binval 4 \
    --merge rh-hipp-MM-head.mgz
mri_binarize \
    --i "${fs_subj_dir}"/mri/rh.hippoAmygLabels.mgz \
    --o rh-hipp-MM-headbodytail-hires.mgz \
    --match 226 \
    --binval 6 \
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
    --binval 7
mri_binarize \
    --i "${fs_subj_dir}"/mri/aparc+aseg.mgz \
    --o acc.mgz \
    --match 2026 \
    --binval 8 \
    --merge acc1.mgz


# CSF (2):
#   Lateral ventricles 4, 43
mri_binarize \
    --i "${fs_subj_dir}"/mri/aparc+aseg.mgz \
    --o csf1.mgz \
    --match 4 \
    --binval 9
mri_binarize \
    --i "${fs_subj_dir}"/mri/aparc+aseg.mgz \
    --o csf.mgz \
    --match 43 \
    --binval 10 \
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


# Combine all ROIs and make label file
mri_binarize --i lh_BA46.mgz       --min 0.5 --binval 11                 --o tmp.mgz
mri_binarize --i rh_BA46.mgz       --min 0.5 --binval 12 --merge tmp.mgz --o tmp.mgz
mri_binarize --i lh_BA9_in_MFG.mgz --min 0.5 --binval 13 --merge tmp.mgz --o tmp.mgz
mri_binarize --i rh_BA9_in_MFG.mgz --min 0.5 --binval 14 --merge tmp.mgz --o tmp.mgz
mris_calc --output tmp.mgz tmp.mgz add acc.mgz
mris_calc --output tmp.mgz tmp.mgz add csf.mgz
mris_calc --output tmp.mgz tmp.mgz add rh-hipp-MM-headbodytail.mgz
mris_calc --output rois.mgz tmp.mgz add lh-hipp-MM-headbodytail.mgz
mri_convert rois.mgz rois.nii.gz

cat << EOF > rois-labels.csv
Label,Region
1,lh_hipp_head
2,rh_hipp_head
3,lh_hipp_body
4,rh_hipp_body
5,lh_hipp_tail
6,rh_hipp_tail
7,lh_ant_cing
8,rh_ant_cing
9,lh_lat_vent
10,rh_lat_vent
11,lh_BA46
12,rh_BA46
13,lh_BA9_in_MFG
14,rh_BA9_in_MFG
EOF


# Find fmriprep subject and session labels
subhtml=$(ls -d "${fmriprep_dir}"/sub-*.html)
sub=$(basename "${subhtml%.html}")
sesdir=$(ls -d "${fmriprep_dir}"/"${sub}"/ses-*)
ses=$(basename "${sesdir}")

# Find native space T1 (ROIs should be aligned with it)
t1=$(ls "${fmriprep_dir}/${sub}/${ses}/anat/${sub}_${ses}_desc-preproc_T1w.nii.gz")

# Find transform - image to ROI geom
xfm=$(ls "${fmriprep_dir}/${sub}/${ses}/anat/${sub}_${ses}_from-MNI152NLin2009cAsym_to-T1w_mode-image_xfm.h5")

# Apply transform
antsApplyTransforms \
    -i "${hurst_niigz}" \
    -r "${out_dir}/rois.nii.gz" \
    -t "${xfm}" \
    -n Linear \
    -o "${out_dir}"/resampled-hurst.nii.gz

# Extract ROI means
extract-rois.py \
    --tgt_niigz resampled-hurst.nii.gz \
    --roi_niigz rois.nii.gz \
    --roilabels_csv rois-labels.csv \
    --output_csv rois-values.csv \
    --value_label Hurst


# PDF showing T1, ROIs, and image in register
IFS=$'\n' coms=($(fslstats -K rois rois -c))

IFS=' ' loc=(${coms[0]})
fsleyes render -of t1_1.png \
    --scene ortho --worldLoc ${loc[@]} --hidey --hidez \
    --displaySpace world --size 600 600 \
    --hideCursor \
    "${t1}" -dr 0 99% \
    rois -ot label -l harvard-oxford-cortical -w 0

fsleyes render -of hurst_1.png \
    --scene ortho --worldLoc ${loc[@]} --hidey --hidez \
    --displaySpace world --size 600 600 \
    --hideCursor \
    "${t1}" -dr 0 99% \
    resampled-hurst -dr 0 99% \
    rois -ot label -l harvard-oxford-cortical -w 0

IFS=' ' loc=(${coms[1]})
fsleyes render -of t1_2.png \
    --scene ortho --worldLoc ${loc[@]} --hidey --hidez \
    --displaySpace world --size 600 600 \
    --hideCursor \
    "${t1}" -dr 0 99% \
    rois -ot label -l harvard-oxford-cortical -w 0

fsleyes render -of hurst_2.png \
    --scene ortho --worldLoc ${loc[@]} --hidey --hidez \
    --displaySpace world --size 600 600 \
    --hideCursor \
    "${t1}" -dr 0 99% \
    resampled-hurst -dr 0 99% \
    rois -ot label -l harvard-oxford-cortical -w 0

montage \
    -mode concatenate t1_1.png hurst_1.png t1_2.png hurst_2.png \
    -tile 2x2 -quality 100 -background black -gravity center \
    -border 0 -bordercolor black reg.png

convert -size 2600x3365 xc:white \
    -gravity center \( reg.png -resize 2400x2800 \) -composite \
    -gravity North -pointsize 40 -font "Nimbus-Sans" -annotate +0+100 \
        "${label_info}" \
    -gravity SouthEast -pointsize 40 -font "Nimbus-Sans" -annotate +100+100 "$(date)" \
    hurst-extract.pdf

