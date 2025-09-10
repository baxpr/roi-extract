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
import shutil
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

# Copy ROIs to outdir
os.makedirs(os.path.join(args.out_dir, 'ROIS'), exist_ok=True)
shutil.copy(args.roi_niigz, os.path.join(args.out_dir, 'ROIS'))
shutil.copy(label_file, os.path.join(args.out_dir, 'ROIS'))

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
    # Note:  use  vals.tolist()[0]  for numpy 1.26.4
    #        use  vals.tolist()     for numpy 2.1.3
    vals = vals.tolist()
    labs = [int(x) for x in masker.labels_ if x!=0]
    vals = pandas.DataFrame({
        'tgt_niigz': os.path.basename(tgt_niigz),
        'index': labs,
        'value': vals,
        }, index=labs)

    # Add ROI labels and merge
    labels = pandas.read_csv(label_file, delimiter='\t')
    vals = vals.merge(labels, on='index', how='outer')
    vals['index0'] = [f'{x:05d}' for x in vals['index'].tolist()]
    vals['ilabel'] = vals['index0'] + '_' + vals['label']

    # Reorganize with region as column name and add cope name column
    vals = vals.pivot(index=['tgt_niigz'], columns='ilabel', values='value')
    if not isinstance(allvals, pandas.DataFrame):
        allvals = vals
    else:
        allvals = pandas.concat([allvals, vals])
    
allvals = allvals.sort_values('tgt_niigz')

allvals.to_csv(os.path.join(args.out_dir, 'roidata.csv'))

