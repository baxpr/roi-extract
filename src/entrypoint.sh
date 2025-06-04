#!/usr/bin/env bash

export out_dir=/OUTPUTS
export ants_transform=
export img_niigzs=()

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in      
        --roi_niigz)      export roi_niigz="$2";      shift; shift ;;
        --ants_transform) export ants_transform="$2"; shift; shift ;;
        --out_dir)        export out_dir="$2";        shift; shift ;;
        --img_niigzs)
            next="$2"
            while ! [[ "$next" =~ -.* ]] && [[ $# > 1 ]]; do
                img_niigzs+=("$next")
                shift
                next="$2"
            done
            shift ;;
        *) echo "Input ${1} not recognized"; shift ;;
    esac
done

# Apply ANTS transform to ROIs if given. We don't really need to save
# the resampled ROI images
if [[ -n "${ants_transform}" ]]; then
    antsApplyTransforms \
        -i "${roi_niigz}" \
        -r "${img_niigz}" \
        -t "${ants_transform}" \
        -n NearestNeighbor \
        -o "${out_dir}"/resampled_rois.nii.gz
else
    cp "${roi_niigz}" "${out_dir}"/resampled_rois.nii.gz
fi



# ?  ImageMath mean ConvertImageSetToMatrix LabelStats

# QC PDF: Show ROIs on each image

# tbss-enigma container has ANTS and FSL
