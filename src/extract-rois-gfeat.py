#!/usr/bin/env python
#
# Input: a higher level (gfeat) dir from FSL FEAT with multiple cope.feat
# subdirs, e.g. fixed effects analysis to combine multiple runs for a 
# single participant/session.
#
# Assumes design.lev in each first level cope dir contains a single contrast name.
#
# Assumes one higher level cope per first level cope dir.
#
# Output: CSV with extracted ROI means for all copes.
#
# We also assume how the roi labels filename can be generated from the ROI
# image filename.

import argparse
import glob
import nibabel
import nilearn.image
import nilearn.maskers
import numpy
import os
import pandas
import sys

parser = argparse.ArgumentParser()
parser.add_argument('--gfeat_dir', required=True)
parser.add_argument('--roi_niigz', required=True)
#parser.add_argument('--roilabels_tsv', required=True)
#parser.add_argument('--output_csv', required=True)
args = parser.parse_args()

# Load ROI image
roi_img = nibabel.load(args.roi_niigz)

# Find and load index/label
label_file = os.path.dirname(args.roi_niigz)
atlas_str = os.path.basename(args.roi_niigz).split('_')[0]
label_file = os.path.join(label_file, atlas_str + '_dseg.tsv')

# Find cope dirs in gfeat dir
cope_dirs = glob.glob(os.path.join(args.gfeat_dir, 'cope*.feat'))

# Process each cope
allvals = ''
for cope_dir in cope_dirs:

    # Get contrast number
    con_num = int(os.path.basename(cope_dir).split('cope')[1].split('.feat')[0])

    # Get contrast name
    lev_file = os.path.join(cope_dir, 'design.lev')
    with open(lev_file, 'rt') as lev:
        con_name = lev.read().strip()

    # Extract values
    masker = nilearn.maskers.NiftiLabelsMasker(
        labels_img=roi_img, 
        resampling_target='labels',
        )
    #masker.fit(os.path.join(cope_dir, 'stats', 'cope1.nii.gz'))
    vals = masker.fit_transform(os.path.join(cope_dir, 'stats', 'cope1.nii.gz'))
    
    # Assume 1D array of extracted ROI values
    vals = vals.tolist()[0]
    vals = pandas.DataFrame({
        'copenum': con_num,
        'copename': con_name,
        'index': masker.labels_,
        'value': vals,
        })

    # Add ROI labels and merge
    labels = pandas.read_csv(label_file, delimiter='\t')
    vals = vals.merge(labels, on='index', how='outer')
        
    # Reorganize with region as column name and add cope name column
    vals = vals.pivot(index=['connum','conname'], columns='label', values='value')
    if not isinstance(allvals, pandas.DataFrame):
        allvals = vals
    else:
        allvals = pandas.concat([allvals, vals])

allvals = allvals.sort_values('connum')

print(allvals)
