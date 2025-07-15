#!/usr/bin/env bash
#
# Study specific ROI extraction - GF WM task mid level (participant) gfeat
# 
# Assumes images already in MNI/standard space

# Inputs
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in      
        --roi_fname)      export roi_fname="$2";      shift; shift ;;
        --gfeat_dir)      export gfeat_dir="$2";      shift; shift ;;
        --out_dir)        export out_dir="$2";        shift; shift ;;
        *) echo "Input ${1} not recognized"; shift ;;
    esac
done

# FIXME Find some files
meanfmri_niigz=


# Work in output dir
cd "${out_dir}"

# Extract ROI means
src_dir=$(dirname "${BASH_SOURCE[0]}")
extract-rois-gfeat.py \
    --gfeat_dir "${gfeat_dir}" \
    --roi_niigz "${src_dir}"/../rois/atlas-GFWM11_space-MNI152NLin6Asym_res-01_dseg.nii.gz \
    --out_dir "${out_dir}"

# PDF showing T1, ROIs, and image in register
IFS=$'\n' coms=($(fslstats -K rois rois -c))

IFS=' ' loc=(${coms[0]})
# FIXME Get a standard T1 here
fsleyes render -of t1_1.png \
    --scene ortho --worldLoc ${loc[@]} --hidey --hidez \
    --displaySpace world --size 600 600 \
    --hideCursor \
    "${t1}" -dr 0 99% \
    rois -ot label -l harvard-oxford-cortical -w 0

# FIXME meanfmri not hurst
fsleyes render -of hurst_1.png \
    --scene ortho --worldLoc ${loc[@]} --hidey --hidez \
    --displaySpace world --size 600 600 \
    --hideCursor \
    "${t1}" -dr 0 99% \
    resampled-hurst -dr 0 99% \
    rois -ot label -l harvard-oxford-cortical -w 0

# FIXME add fmri mask over std T1

# FIXME show more than 1 roi?
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

