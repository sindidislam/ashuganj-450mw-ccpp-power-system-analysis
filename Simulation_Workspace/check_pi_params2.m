addpath('matlab/build');
B = sps_blocks();
disp(B.pisection);
new_system('test_sys'); load_system('sps_lib'); 
add_block(B.pisection, 'test_sys/L1');
disp(get_param('test_sys/L1', 'DialogParameters'));
