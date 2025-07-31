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
        --label_info)     export label_info="$2";     shift; shift ;;
        *) echo "Input ${1} not recognized"; shift ;;
    esac
done

# Find ROI file
src_dir=$(dirname "${BASH_SOURCE[0]}")
roi_niigz="${src_dir}"/../rois/"${roi_fname}"

# Work in output dir
cd "${out_dir}"

# Extract ROI means
"${src_dir}"/extract-rois-gfeat.py \
    --gfeat_dir "${gfeat_dir}" \
    --roi_niigz "${roi_niigz}" \
    --out_dir "${out_dir}"


# PDF showing T1, ROIs, and image in register

# Location of first ROI
IFS=$'\n' coms=($(fslstats -K "${roi_niigz}" "${roi_niigz}" -c))

IFS=' ' loc=(${coms[0]})

# On standard T1
fsleyes render -of t1_1.png \
    --scene ortho --worldLoc ${loc[0]} ${loc[1]} ${loc[2]} -xc 0 0 -yc 0 0 -zc 0 0 \
    --displaySpace world --size 1800 600 \
    --hideCursor \
    "${FSLDIR}"/data/standard/MNI152_T1_1mm -dr 0 99% \
    "${roi_niigz}" -ot label -l harvard-oxford-cortical -o \
    "${gfeat_dir}"/mask -ot mask -o 

# On mean func
fsleyes render -of func_1.png \
    --scene ortho --worldLoc ${loc[0]} ${loc[1]} ${loc[2]} -xc 0 0 -yc 0 0 -zc 0 0 \
    --displaySpace world --size 1800 600 \
    --hideCursor \
    "${gfeat_dir}"/mean_func -dr 0 99% \
    "${roi_niigz}" -ot label -l harvard-oxford-cortical -o \
    "${gfeat_dir}"/mask -ot mask -o 


# Show second ROI
IFS=' ' loc=(${coms[1]})
fsleyes render -of t1_2.png \
    --scene ortho --worldLoc ${loc[0]} ${loc[1]} ${loc[2]} -xc 0 0 -yc 0 0 -zc 0 0 \
    --displaySpace world --size 1800 600 \
    --hideCursor \
    "${FSLDIR}"/data/standard/MNI152_T1_1mm -dr 0 99% \
    "${roi_niigz}" -ot label -l harvard-oxford-cortical -o \
    "${gfeat_dir}"/mask -ot mask -o 

fsleyes render -of func_2.png \
    --scene ortho --worldLoc ${loc[0]} ${loc[1]} ${loc[2]} -xc 0 0 -yc 0 0 -zc 0 0 \
    --displaySpace world --size 1800 600 \
    --hideCursor \
    "${gfeat_dir}"/mean_func -dr 0 99% \
    "${roi_niigz}" -ot label -l harvard-oxford-cortical -o \
    "${gfeat_dir}"/mask -ot mask -o 

montage \
    -mode concatenate t1_1.png func_1.png t1_2.png func_2.png \
    -tile 1x4 -quality 100 -background black -gravity center \
    -border 0 -bordercolor black reg.png

convert -size 2600x3365 xc:white \
    -gravity center \( reg.png -resize 2400x2800 \) -composite \
    -gravity North -pointsize 40 -annotate +0+100 \
        "${label_info}" \
    -gravity SouthEast -pointsize 40 -annotate +100+100 "$(date)" \
    roi-extract.pdf

#convert -size 2600x3365 xc:white \
#    -gravity center \( reg.png -resize 2400x2800 \) -composite \
#    -gravity North -pointsize 40 -font "Nimbus-Sans" -annotate +0+100 \
#        "${label_info}" \
#    -gravity SouthEast -pointsize 40 -font "Nimbus-Sans" -annotate +100+100 "$(date)" \
#    roi-extract.pdf