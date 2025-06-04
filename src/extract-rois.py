#!/usr/bin/env python

import argparse
import nibabel
import nilearn
from nilearn import masking, maskers
import numpy
import os
import pandas

parser = argparse.ArgumentParser()
parser.add_argument('--tgt_niigz', required=True)
parser.add_argument('--roi_niigz', required=True)
parser.add_argument('--roilabels_csv', required=True)
parser.add_argument('--output_csv', required=True)
parser.add_argument('--value_label', default='value')
args = parser.parse_args()

roi_info = pandas.read_csv(args.roilabels_csv)

masker = nilearn.maskers.NiftiLabelsMasker(args.roi_niigz)

img = nibabel.load(args.tgt_niigz)

vals = masker.fit_transform(img)

roi_info[args.value_label] = [x[0] for x in numpy.transpose(vals).tolist()]

roi_info.to_csv(args.output_csv, index=False)

