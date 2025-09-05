#!/usr/bin/env python

import argparse
import glob
import nibabel
import nilearn.image
import nilearn.maskers
import numpy
import os
import pandas
import re
import sys

# Function to get a clean tag from image filename
def sanitize_tag(img_niigz):
    tag = os.path.basename(img_niigz).removesuffix('.nii.gz')
    tag = re.sub('[ -]', '_', tag)
    
# Parse arguments
parser = argparse.ArgumentParser()
parser.add_argument('--roi_niigz', required=True)
parser.add_argument('--mask_niigz', required=True)
parser.add_argument('--tgts_niigz', required=True, nargs='*')
parser.add_argument('--out_dir', required=True)
args = parser.parse_args()

# Find and load index/label (strong assumptions about the filename)
label_file = os.path.dirname(args.roi_niigz)
atlas_str = os.path.basename(args.roi_niigz).split('_')[0]
label_file = os.path.join(label_file, atlas_str + '_dseg.tsv')

# Load images
roi_img = nibabel.load(args.roi_niigz)
mask_img = nibabel.load(args.mask_niigz)

# Create masker
masker = nilearn.maskers.NiftiLabelsMasker(
    labels_img=roi_img,
    mask_img=mask_img,
    resampling_target='labels',
    )

# Extract values
allvals = []
for tgt_niigz in args.tgts_niigz:
    
    tag = sanitize_tag(tgt_niigz)
    
    vals = masker.fit_transform(tgt_niigz)
    
    # Assume 1D array of extracted ROI values
    vals = vals.tolist()[0]
    vals = pandas.DataFrame({
        'tgt_niigz': os.path.basename(tgt_niigz),
        'index': masker.labels_,
        'value': vals,
        })

    # Add ROI labels and merge
    labels = pandas.read_csv(label_file, delimiter='\t')
    vals = vals.merge(labels, on='index', how='outer')
        
    # Reorganize with region as column name and add cope name column
    vals = vals.pivot(index=['tgt_niigz'], columns='label', values='value')
    if not isinstance(allvals, pandas.DataFrame):
        allvals = vals
    else:
        allvals = pandas.concat([allvals, vals])
    
allvals = allvals.sort_values('tgt_niigz')

allvals.to_csv(os.path.join(args.out_dir, 'roidata.csv'))

