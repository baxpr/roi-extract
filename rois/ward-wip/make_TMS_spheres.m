% Spheres for TMS study
radius = 10;

rois = table({},[],[],[],'VariableNames',{'label','x','y','z'});

% Inter-effectors (M1)
rois(end+1,:) = table({'L_DLPFC'},  -41,+16,+54);
rois(end+1,:) = table({'R_DLPFC'},  +41,+16,+54);

rois(end+1,:) = table({'L_Parietal'},  -46,-66,+30);
rois(end+1,:) = table({'R_Parietal'},  +46,-66,+30);


rois.index = (1:height(rois))';

V = spm_vol(fullfile(spm('dir'),'canonical','avg152T1.nii'));
[Y,XYZ] = spm_read_vols(V);
Yroi = zeros(size(Y));

for r = 1:height(rois)
    
    dsq = ...
        (XYZ(1,:)-rois.x(r)).^2 + ...
        (XYZ(2,:)-rois.y(r)).^2 + ...
        (XYZ(3,:)-rois.z(r)).^2;
    keeps = dsq <= radius^2;
    Yroi(keeps) = r;
    
end

Vroi = rmfield(V,'private');
Vroi.pinfo(1:2) = [1 0];
Vroi.dt(1) = spm_type('uint16');
Vroi.fname = 'TMS.nii';
spm_write_vol(Vroi,Yroi);
system('gzip -f TMS.nii');

info = rois(:,{'index','label'});
writetable(info,'TMS-labels.tsv','Delimiter','tab','FileType','text')

