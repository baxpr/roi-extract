#!/usr/bin/env bash

$(pwd)/generic-extract.py \
	--roi_niigz ../rois/atlas-BAISins_space-MNI152NLin6Asym_res-02_dseg.nii.gz \
	--mask_niigz ../INPUTS/hct-fmri/spm_hct/mask.nii.gz \
	--tgts_niigz ../INPUTS/hct-fmri/spm_hct/con_0001.nii.gz ../INPUTS/hct-fmri/spm_hct/con_0002.nii.gz \
	--out_dir ../OUTPUTS
