#!/usr/bin/env python

import argparse
import nibabel
import nilearn
from nilearn import masking, maskers
import numpy
import os
import pandas
import sys

parser = argparse.ArgumentParser()
parser.add_argument('--tgt_niigz', required=True)
parser.add_argument('--roi_niigz', required=True)
parser.add_argument('--roilabels_csv', required=True)
parser.add_argument('--output_csv', required=True)
parser.add_argument('--value_label', default='value')
args = parser.parse_args()

roi_info = pandas.read_csv(args.roilabels_csv)

tgt_img = nibabel.load(args.tgt_niigz)
roi_img = nibabel.load(args.roi_niigz)

# Verify 3D images with matching geometry
if len(tgt_img.header.get_data_shape()) != 3:
    raise Exception('Target image is not 3D')
if not numpy.all(tgt_img.header.get_data_shape()==roi_img.header.get_data_shape()):
    raise Exception('Image dimensions do not match')
affine_diff = numpy.max(numpy.abs(numpy.round(tgt_img.affine - roi_img.affine, 4)))
if affine_diff != 0:
    raise Exception('Image affines do not match')

tgt_data = tgt_img.get_fdata()
roi_data = roi_img.get_fdata()

# Find unique non-zero ROI labels and verify vs Label in ROI csv
roivals = sorted(numpy.int32(numpy.unique(numpy.round(roi_data))))
roivals.remove(0)
print(f'Found {len(roivals)} unique ROI labels in {args.roi_niigz} :')
print(roivals)

infovals = sorted(roi_info.Label.values)
if not roivals==infovals:
    raise Exception('Mismatch of ROI labels between image and info csv')


#for roival in roivals:
    # FIXME find voxels and get mean
    # https://numpy.org/devdocs//user/basics.indexing.html#boolean-array-indexing

# FIXME compute coverage for each ROI? Needs mask

# Previous method with nilearn
#masker = nilearn.maskers.NiftiLabelsMasker(args.roi_niigz)
#img = nibabel.load(args.tgt_niigz)
#vals = masker.fit_transform(img)
#roi_info[args.value_label] = [x[0] for x in numpy.transpose(vals).tolist()]
#roi_info.to_csv(args.output_csv, index=False)

