function ctx = lr_cap(fid, ctx, txt)
%LR_CAP  Print the next table caption and advance the table counter.
%
%   Tables in this report are cited by number in the discussion and in the
%   answers to the report questions, so the numbering has to come from one
%   counter rather than from typed digits. Insert a table anywhere and everything
%   after it renumbers itself; nothing is left pointing at the wrong table.
%
%   The caption goes ABOVE the table, which is the convention the EEE 306
%   labsheets use for data tables (figures are captioned below).
ctx.tno = ctx.tno + 1;
fprintf(fid, '<p class="cl">Table %d &mdash; %s</p>\n', ctx.tno, txt);
end
