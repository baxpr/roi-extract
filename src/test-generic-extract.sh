#!/usr/bin/env bash

export PATH=$(pwd):$PATH

$(pwd)/generic-extract.sh \
	--roi_niigz ../rois/atlas-BAISins_space-MNI152NLin6Asym_res-02_dseg.nii.gz \
	--underlay_niigz ../INPUTS/hct-fmri/spm_hct/mask.nii.gz \
	--mask_niigz ../INPUTS/hct-fmri/spm_hct/mask.nii.gz \
	--tgts_niigz \
		../INPUTS/hct-fmri/spm_hct/con_0001.nii.gz \
		../INPUTS/hct-fmri/spm_hct/con_0002.nii.gz \
		../INPUTS/hct-fmri/spm_hct/con_0003.nii.gz \
		../INPUTS/hct-fmri/spm_hct/con_0004.nii.gz \
		../INPUTS/hct-fmri/spm_hct/con_0005.nii.gz \
		../INPUTS/hct-fmri/spm_hct/con_0006.nii.gz \
		../INPUTS/hct-fmri/spm_hct/con_0007.nii.gz \
		../INPUTS/hct-fmri/spm_hct/con_0008.nii.gz \
	--show_std \
	--out_dir ../OUTPUTS
