#!/usr/bin/env bash
#
# Generic ROI extraction

# Inputs:
#   roi filename from ../rois dir (generate roi label filename from this)
#   target image to extract data from (or list of target images and store tags from their filenames)
#   background image for registration overlay
#   show overlay/rois on standard image yes/no
#   mask to show on standard image (if given)


# Inputs
tgts_niigz=
show_std=TRUE
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in      
        --roi_niigz)        export roi_niigz="$2";        shift; shift ;;
        --out_dir)          export out_dir="$2";          shift; shift ;;
        --underlay_niigz)   export underlay_niigz="$2";   shift; shift ;;
        --mask_niigz)       export mask_niigz="$2";       shift; shift ;;
        --dont_show_std)    export show_std=FALSE;        shift ;;
        --tgts_niigz)
            next="$2"
            while ! [[ "$next" =~ ^-.* ]] && [[ $# > 1 ]]; do
                tgts_niigz+=("$next")
                shift
                next="$2"
            done
            shift ;;
        *) echo "Input ${1} not recognized"; shift ;;
    esac
done

# Find ROI image
roi_dir=$(dirname "${BASH_SOURCE[0]}")/../rois
roi_niigz="${roi_dir}"/"${roi_niigz}"

# Extract ROI means
generic-extract.py \
    --roi_niigz "${roi_niigz}" \
    --mask_niigz "${mask_niigz}" \
    --tgts_niigz ${tgts_niigz[@]} \
    --out_dir "${out_dir}"


# Get ROI locations
IFS=$'\n' coms=($(fslstats -K "${roi_niigz}" "${roi_niigz}" -c))

# Show on underlay
# fsl 6.0.7.16 needed for -ss 0.05 option
cd "${out_dir}"
fslmaths "${underlay_niigz}" -nan underlay
fsleyes render -of underlay.png \
    --scene lightbox --displaySpace world --size 1200 600 \
    --hideCursor -ss 0.04 -zr 0.05 0.95 \
    underlay \
    "${roi_niigz}" -ot label -l random_big -w 0 \
    "${mask_niigz}" -ot mask -o

std_file=""
if [[ "${show_std}" = "TRUE" ]]; then
    fsleyes render -of standard.png \
        --scene lightbox --displaySpace world --size 1200 600 \
        --hideCursor -ss 0.04 -zr 0.05 0.95 \
        "${FSLDIR}"/data/standard/MNI152_T1_1mm \
        "${roi_niigz}" -ot label -l random_big -w 0 \
        "${mask_niigz}" -ot mask -o
    std_file="standard.png"
fi

convert underlay.png "${std_file}" roi-extract.pdf
