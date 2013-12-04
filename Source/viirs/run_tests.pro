pro run_tests
CD, CURRENT=c
!PATH=!PATH+':'+Expand_Path('+' + c)
datafiles = FILE_SEARCH(c+'/Source/viirs/test/test_*', /FOLD_CASE)
print, datafiles

length_file_list = size(datafiles, /dimension)
for i_iter=0, length_file_list[0] - 1 do begin 
  print, 'Running Test :: ' + datafiles[i_iter]
  result = call_function(datafiles[i_iter])
  if result eq 1 then print, 'Test Passed' else print, 'Test Failed'
endfor

end