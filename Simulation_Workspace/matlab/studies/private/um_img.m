function um_img(fid, outDir, name, caption)
%UM_IMG  Embed a figure that sits beside the HTML, or state that it is absent.
%
%   A missing figure is reported on the page. It is never silently skipped: a gap
%   the reader cannot see is a gap nobody fixes.
if exist(fullfile(outDir, name), 'file')
    fprintf(fid, ['<figure><img src="%s" alt="%s">' ...
        '<figcaption>%s</figcaption></figure>\n'], name, name, caption);
else
    fprintf(fid, ['<p class="warn">Figure <code>%s</code> is not in this folder ' ...
        'yet. Run <code>RUN_ME</code> (or <code>make_load_flow_plots</code> and ' ...
        '<code>make_annotated_diagrams</code>) and regenerate this page.</p>\n'], name);
end
end
