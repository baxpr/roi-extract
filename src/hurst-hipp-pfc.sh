#!/usr/bin/env bash
#
# Study specific ROI extraction

# Inputs
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in      
        --fs_subj_dir)    export fs_subj_dir="$2";    shift; shift ;;
        --fmriprep_dir)   export fmriprep_dir="$2";   shift; shift ;;
        --img_niigz)      export img_niigz="$2";      shift; shift ;;
        --out_dir)        export out_dir="$2";        shift; shift ;;
        --label_info)     export label_info="$2";     shift; shift ;;
        *) echo "Input ${1} not recognized"; shift ;;
    esac
done

# Work in output dir
cd "${out_dir}"

# ROIs in FS native geom, stored at 
#    ${out_dir}/rois.nii.gz
#    ${out_dir}/rois-labels.csv
#
# Hippocampus (6):
#   Head - Maureen anterior combination
#   Body - Maureen's less the tail
#   Tail - directly the freesurfer tail
# 
# DLPFC from script (4):
#   lh_BA46.mgz
#   lh_BA9_in_MFG.mgz
#   rh
#   rh
# 
# ACC (2):
#   Rostral anterior cingulate from DK (aparc) 1026, 2026
# 
# CSF (2):
#   lateral ventricles 4, 43




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
    -i "${img_niigz}" \
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

