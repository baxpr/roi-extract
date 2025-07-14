#!/usr/bin/env bash
#
# ROIs for GF working memory task fmri
#
# Taghia J, Cai W, Ryali S, Kochalka J, Nicholas J, Chen T, Menon V. 
# Uncovering hidden brain state dynamics that regulate performance 
# and decision-making during cognition. Nat Commun. 2018 Jun 27;9(1):2505. 
# doi: 10.1038/s41467-018-04723-6. PMID: 29950686; PMCID: PMC6021386.
# https://pmc.ncbi.nlm.nih.gov/articles/PMC6021386/
#
# Cai W, Ryali S, Pasumarthy R, Talasila V, Menon V. Dynamic causal brain 
# circuits during working memory and their functional controllability. 
# Nat Commun. 2021 Jun 29;12(1):3314. doi: 10.1038/s41467-021-23509-x. 
# PMID: 34188024; PMCID: PMC8241851.
# https://pmc.ncbi.nlm.nih.gov/articles/PMC8241851/

# lAI   -32  24   2
# rAI    36  22   0
# lMFG  -42  24  30
# rMFG   40  36  34
# lFEF  -26   2  58
# rFEF   30  10  56
# lIPL  -46 -44  44
# rIPL   52 -40  50
# PCC   -12 -56  16
# VMPFC  -2  48  -8
# DMPFC   4  16  50

# atlas-GFWM11_dseg.tsv
# atlas-GFWM11_space-MNI152NLin6Asym_res-02_dseg.nii.gz

# Convert mm coords to voxel indices for the 1mm standard brain 
#   ${FSLDIR}/data/standard/MNI152_T1_1mm.nii.gz
# https://jiscmail.ac.uk/cgi-bin/webadmin?A2=FSL;ac19295e.0710

fslmaths ${FSLDIR}/data/standard/MNI152_T1_1mm.nii.gz \
    -mul 0 -add 1 -roi 131 1 142 1 126 1 0 1 \
    -kernel sphere 6 -dilM \
    sphere6mm_MNI_-41_+16_+54

# Label file
cat 
