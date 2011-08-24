pro sort_unzipped_from_vito

case strupcase(!version.os_family) of
'WINDOWS':begin
base_folder = 'V:\MEREMSII\vgt_data\UNZIPPED_FROM_VITO\'
dl = '\'
site_file = 'Z:\DIMITRI_code\DIMITRI_2.0\Bin\DIMITRI_SITE_DATA.txt'
end
'UNIX':begin
base_folder = '/mnt/V_drive/MEREMSII/vgt_data/UNZIPPED_FROM_VITO/'
dl = '/'
site_file = '/mnt/Demitri/DIMITRI_code/DIMITRI_2.0/Bin/DIMITRI_SITE_DATA.txt'
end
endcase

sites = ['Uyuni','Libya','DomeC','TuzGolu','BOUSSOLE','Amazon','SPG','SIO']

;search for all folders
cd,base_folder
print,'searching for folders'
res = file_search('C00*')
res2 = file_search('S00*')
print,'found folders'

res = [res,res2]
;loop over each one

for i=0,N_elements(res)-1 do begin
print, 'computing for folder : ',res[i]

;read the log file
log_file = base_folder+res[i]+dl+'0001'+dl+'0001_LOG.TXT'

if file_test(log_file) eq 0 then goto,skip_product

log_data = string(read_binary(log_file))

;get the product coordinates
pos = strpos(log_data,'CARTO_UPPER_LEFT_X')
prd_west = float(strmid(log_data,pos+26,11))
pos = strpos(log_data,'CARTO_UPPER_RIGHT_X')
prd_east = float(strmid(log_data,pos+26,11))
pos = strpos(log_data,'CARTO_UPPER_LEFT_Y')
prd_north = float(strmid(log_data,pos+26,11))
pos = strpos(log_data,'CARTO_LOWER_LEFT_Y')
prd_south = float(strmid(log_data,pos+26,11))

;loop over each dimitri site
for j=0,n_elements(sites)-1 do begin
icoords = GET_SITE_COORDINATES(sites[j],site_file)

if icoords[0] lt prd_north and $
icoords[1] gt prd_south and $
icoords[2] lt prd_east and $
icoords[3] gt prd_west then begin

if file_test(base_folder+sites[j]+dl+res[i]) eq 0 then file_copy,base_folder+res[i]+dl,base_folder+sites[j]+dl,/recursive

endif
skip_product:
endfor

endfor

print,'end of movement of data'

end
