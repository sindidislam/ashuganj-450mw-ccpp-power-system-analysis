addpath('matlab/build');
B = sps_blocks();
new_system('test_sys'); load_system('sps_lib'); 
add_block(B.pisection, 'test_sys/L1');
p = get_param('test_sys/L1', 'DialogParameters');
fn = fieldnames(p);
for i=1:numel(fn), fprintf('%s\n', fn{i}); end
