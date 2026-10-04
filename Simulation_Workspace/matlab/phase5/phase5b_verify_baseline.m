function n=phase5b_verify_baseline()
root=ashuganj_root();
T=readtable(fullfile(root,'docs','PHASE5_PROTECTED_BASELINE.csv'),'TextType','string','Delimiter',',');
for i=1:height(T)
 p=fullfile(root,T.path(i));
 assert(isfile(p),'phase5b_baseline:missing','Protected file missing: %s',p);
 assert(strcmpi(phase5b_sha256(p),T.sha256(i)),'phase5b_baseline:changed','Protected upstream file changed: %s',p);
end
n=height(T);
end
