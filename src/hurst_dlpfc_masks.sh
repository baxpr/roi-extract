# Define template volume
temp=$SUBJECTS_DIR/$subj/mri/T1.mgz
[ -f "$temp" ] || temp=$SUBJECTS_DIR/$subj/mri/orig.mgz
echo "Using template: $temp"

#CREATE DK DLPFC LABELS
#Extact DK labels
mkdir -p /tmp/aparc_lh /tmp/aparc_rh

mri_annotation2label --subject $subj --hemi lh --annotation aparc --outdir /tmp/aparc_lh
mri_annotation2label --subject $subj --hemi rh --annotation aparc --outdir /tmp/aparc_rh

# Convert rostral + caudal MFG to volume and combine
for hemi in lh rh; do
for roi in rostralmiddlefrontal caudalmiddlefrontal; do
mri_label2vol \
--label /tmp/aparc_${hemi}/${hemi}.${roi}.label \
--temp  $temp \
--regheader $temp \
--o $SUBJECTS_DIR/$subj/mri/${hemi}_${roi}.mgz \
--fillthresh 0.5
done

mri_binarize \
--i $SUBJECTS_DIR/$subj/mri/${hemi}_rostralmiddlefrontal.mgz \
--merge $SUBJECTS_DIR/$subj/mri/${hemi}_caudalmiddlefrontal.mgz \
--min 0.5 \
--o $SUBJECTS_DIR/$subj/mri/${hemi}_DK_dlpfc.mgz
done

#CREATE BA9 AND BA46 LABELS
#Project Brodmann annotation from fsaverage
for hemi in lh rh; do
mri_surf2surf \
--srcsubject fsaverage \
--trgsubject $subj \
--hemi $hemi \
--sval-annot $SUBJECTS_DIR/fsaverage/label/${hemi}.PALS_B12_Brodmann.annot \
--tval $SUBJECTS_DIR/$subj/label/${hemi}.PALS_B12_Brodmann.annot
done

#Extract BA9 and BA46 labels
mkdir -p /tmp/brod_lh /tmp/brod_rh

mri_annotation2label --subject $subj --hemi lh --annotation PALS_B12_Brodmann --outdir /tmp/brod_lh
mri_annotation2label --subject $subj --hemi rh --annotation PALS_B12_Brodmann --outdir /tmp/brod_rh

#Convert BA9 and BA46 to volume
for hemi in lh rh; do
for ba in 9 46; do
mri_label2vol \
--label /tmp/brod_${hemi}/${hemi}.Brodmann.${ba}.label \
--temp  $temp \
--regheader $temp \
--o $SUBJECTS_DIR/$subj/mri/${hemi}_BA${ba}.mgz \
--fillthresh 0.5
done
done

#Restrict BA9 to middle frontal gyrus
for hemi in lh rh; do
mri_binarize --i $SUBJECTS_DIR/$subj/mri/${hemi}_BA9.mgz \
--min 0.5 \
--o /tmp/${hemi}_BA9_bin.mgz

mri_binarize --i $SUBJECTS_DIR/$subj/mri/${hemi}_DK_dlpfc.mgz \
--min 0.5 \
--o /tmp/${hemi}_DK_bin.mgz

mri_and \
/tmp/${hemi}_BA9_bin.mgz \
/tmp/${hemi}_DK_bin.mgz \
$SUBJECTS_DIR/$subj/mri/${hemi}_BA9_in_MFG.mgz
done

#VIEW IN FREEVIEW
freeview \
-v $temp \
-v $SUBJECTS_DIR/$subj/mri/lh_DK_dlpfc.mgz:opacity=0.25 \
-v $SUBJECTS_DIR/$subj/mri/lh_BA46.mgz:opacity=0.25 \
-v $SUBJECTS_DIR/$subj/mri/lh_BA9.mgz:opacity=0.6 \
-v $SUBJECTS_DIR/$subj/mri/lh_BA9_in_MFG.mgz:opacity=0.6


