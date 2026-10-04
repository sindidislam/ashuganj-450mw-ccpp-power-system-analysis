function T=phase5b_export_applicability(T)
% Heterogeneous device/result rows contain non-applicable columns. Explicit
% text replaces only structural NaN; required model fields are checked first.
for j=1:width(T)
 name=T.Properties.VariableNames{j}; x=T.(name);
 if isnumeric(x)&&any(isnan(x),'all')
  c=cell(size(x));
  for i=1:numel(x)
   if isnan(x(i))
    if strcmp(name,'physical_CT_ratio'), c{i}='INSTALLED_VALUE_NOT_VERIFIED';
    else, c{i}='NOT_APPLICABLE_TO_ROW'; end
   else, c{i}=sprintf('%.15g',x(i)); end
  end
  T.(name)=c;
 elseif iscell(x)
  for i=1:numel(x), if isempty(x{i}), x{i}='NONE'; end, end
  T.(name)=x;
 end
end
end
