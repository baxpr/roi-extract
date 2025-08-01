#!/usr/bin/env bash
#
# Generic ROI extraction

# First target: ALFFs for NegVal

# Inputs:
#   roi filename from ../rois dir (generate roi label filename from this)
#   target image to extract data from (or list of target images and store tags from their filenames)
#   background image for registration overlay
#   show overlay/rois on standard image yes/no
#   mask to show on standard image (if given)

# Follow nilearn procedures in extract-rois-gfeat.py


# Inputs
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in      
        --roi_niigz)        export roi_niigz="$2";        shift; shift ;;
        --out_dir)          export out_dir="$2";          shift; shift ;;
        --underlay_niigz)   export underlay_niigz="$2";   shift; shift ;;
        --mask_niigz)       export mask_niigz="$2";       shift; shift ;;
        --show_std)         export show_std="$2";         shift; shift ;;
        --tgts_niigz)
            next="$2"
            while ! [[ "$next" =~ -.* ]] && [[ $# > 1 ]]; do
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

