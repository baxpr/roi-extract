% ROIs for GF working memory task fmri
%
% Taghia J, Cai W, Ryali S, Kochalka J, Nicholas J, Chen T, Menon V. 
% Uncovering hidden brain state dynamics that regulate performance 
% and decision-making during cognition. Nat Commun. 2018 Jun 27;9(1):2505. 
% doi: 10.1038/s41467-018-04723-6. PMID: 29950686; PMCID: PMC6021386.
% https://pmc.ncbi.nlm.nih.gov/articles/PMC6021386/
%
% Cai W, Ryali S, Pasumarthy R, Talasila V, Menon V. Dynamic causal brain 
% circuits during working memory and their functional controllability. 
% Nat Commun. 2021 Jun 29;12(1):3314. doi: 10.1038/s41467-021-23509-x. 
% PMID: 34188024; PMCID: PMC8241851.
% https://pmc.ncbi.nlm.nih.gov/articles/PMC8241851/

% ROI center coordinates
info = [ ...
    {1},  {'lAI'},   {[-32  24   2]}; ...
    {2},  {'rAI'},   {[ 36  22   0]}; ...
    {3},  {'lMFG'},  {[-42  24  30]}; ...
    {4},  {'rMFG'},  {[ 40  36  34]}; ...
    {5},  {'lFEF'},  {[-26   2  58]}; ...
    {6},  {'rFEF'},  {[ 30  10  56]}; ...
    {7},  {'lIPL'},  {[-46 -44  44]}; ...
    {8},  {'rIPL'},  {[ 52 -40  50]}; ...
    {9},  {'PCC'},   {[-12 -56  16]}; ...
    {10}, {'VMPFC'}, {[ -2  48  -8]}; ...
    {11}, {'DMPFC'}, {[  4  16  50]} ...
    ];
info = cell2table(info,'VariableNames',{'index','label','xyzmm'});

% Reference image and empty ROI image
V = spm_vol('/usr/local/fsl/data/standard/MNI152_T1_1mm.nii.gz');
[Y,XYZ] = spm_read_vols(V);
roi = zeros(size(Y));

% Generate spheres
for r = 1:height(info)
    dsq = ...
        (XYZ(1,:)-info(r,'xyzmm').xyzmm(1)).^2 + ...
        (XYZ(2,:)-info(r,'xyzmm').xyzmm(2)).^2 + ...
        (XYZ(3,:)-info(r,'xyzmm').xyzmm(3)).^2;
    inds = dsq < 6^2;
    roi(inds) = r;
end

% Save to file
Vout = V;
Vout.dt(1) = spm_type('int16');
Vout.pinfo(1:2) = [1; 0];
Vout.fname = 'atlas-GFWM11_space-MNI152NLin6Asym_res-01_dseg.nii';
spm_write_vol(Vout, roi);
gzip(Vout.fname);
delete(Vout.fname)

% Save labels
writetable(info(:,{'index','label'}),'atlas-GFWM11_dseg.tsv', ...
    'FileType','text','Delimiter','tab');


