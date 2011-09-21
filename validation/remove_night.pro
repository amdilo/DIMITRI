pro remove_night

cd,current=cdir
folder = 'Z:\DIMITRI_code\DIMITRI_2.0\Input\Site_Libya\AATSR\Proc_2nd_Reprocessing\2010'
cd,folder

res = file_search('*')
for i=0l,n_elements(res)-1 do begin

val = strmid(res[i],23,1)
if val eq '1' or val eq '2' then file_delete,res[i]
endfor
cd=cdir
end