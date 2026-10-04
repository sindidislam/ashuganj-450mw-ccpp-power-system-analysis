for k=[1:12,numel(err.stack)-12:numel(err.stack)]
 fprintf('STACK %s:%d %s\n',err.stack(k).name,err.stack(k).line,err.stack(k).file);
end
