PRO MOVE_PARASOL

case strupcase(!version.os_family) of
'WINDOWS':begin
          IFOLDER = 'Z:\1_Data_Archive\data_uyuni\parasol\'
          dl = '\'
          end
'UNIX':   begin
          IFOLDER = '/mnt/Demitri/1_Data_Archive/data_uyuni/parasol/'
          dl = '/'
          end
endcase

STR = 'P*KD*'
CD,IFOLDER
FILES = FILE_SEARCH(STR)

FOR I=0,N_ELEMENTS(FILES)-1 DO BEGIN

FILE = FILES[I]

RES = GET_PARASOL_L1B_HEADER(FILE)
YEAR = STRMID(STRING(RES.DATE),0,4)
print, 'file found for year: ',year
FILE_COPY,FILE,IFOLDER+YEAR+dl,/OVERWRITE
STRPUT,FILE,'L',15
FILE_COPY,FILE,IFOLDER+YEAR+dl,/OVERWRITE

ENDFOR


END