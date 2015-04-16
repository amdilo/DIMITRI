;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*     COMPUTE_MUD
;* 
;* PURPOSE:
;*      COMPUTE MUD (AVERAGED COSINE FOR DOWNWELLING IRRADIANCE) OF MOREL AND MARITORENA 2001
;*      AS A FUNCTION OF WAVELENGTH, CHLOROPHYLL AND SUN ZENITH ANGLE
;* 
;* CALLING SEQUENCE:
;*      RES = COMPUTE_MUD(WAV, CHL, SZA)
;* 
;* INPUTS:
;*      WAV  - THE WAVELENGTH E.G. 443 NM
;*      CHL  - THE CHL CONCENTRATION IN MG/M3
;*      SZA  - THE SOLAR ZENITH ANGLES IN DEGREES
;*
;* KEYWORDS:
;*      VERBOSE          - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      MUD              - AVERAGED COSINE FOR DOWNWELLING IRRADIANCE
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*        01 NOV 2013 - C MAZERAN - FIRST IMPLEMENTATION
;*
;* VALIDATION HISTORY:
;*        01 NOV 2013 - C MAZERAN - LINUX 64-BIT MACHINE IDL 8.2, NOMINAL COMPILATION AND OPERATION. 
;*
;**************************************************************************************
;**************************************************************************************
FUNCTION COMPUTE_MUD, WAV, CHL, SZA, VERBOSE=VERBOSE

;-----------------------------------------
; DEFINE NAME OF FUNCTION

 FCT_NAME='COMPUTE_MUD'

;---------------------------
; GET AUX FILENAME

 MUD_FILE = GET_DIMITRI_LOCATION('MOREL_MUD',VERBOSE=VERBOSE)

 RES = FILE_INFO(MUD_FILE)
 IF RES.EXISTS EQ 0 THEN BEGIN
   IF KEYWORD_SET(VERBOSE) THEN PRINT, FCT_NAME+': ERROR, MOREL MUD FILE NOT FOUND'
   RETURN,-1
 ENDIF

 ;-----------------------------------------
 ; OPEN MOREL MUD AUX FILE

 IF KEYWORD_SET(VERBOSE) THEN PRINT,FCT_NAME+': OPEN MUD AUX FILE'
 RES = READ_ASCII(MUD_FILE, DATA_START=1, HEADER=HEADER)
 DATA=RES.FIELD1

 ;-----------------------------------------
 ; REMOVE POSSIBLE DATA FOR CARDIOIDAL SKY

 TMP_SZA = DATA[0,*]
 INDEX = WHERE(TMP_SZA GE 0.)
 
 ;-----------------------------------------
 ; READ AND REFORMAT MUD DATA

 TMP_SZA = REFORM(DATA[0,INDEX])
 MUD_SZA = TMP_SZA[UNIQ(TMP_SZA,SORT(TMP_SZA))]
 NSZA    = N_ELEMENTS(MUD_SZA)
 
 TMP_WAV = REFORM(DATA[1,INDEX])
 MUD_WAV = TMP_WAV[UNIQ(TMP_WAV,SORT(TMP_WAV))]
 NWAV    = N_ELEMENTS(MUD_WAV)

 TMP     = STRSPLIT(HEADER,"chl=", /REGEX, /EXTRACT)
 NCHL    = N_ELEMENTS(TMP)-1
 MUD_CHL = FLOAT(TMP[1:NCHL])

 MUD_DATA = DATA[2:NCHL+2-1,INDEX]
 MUD_DATA = REFORM(MUD_DATA, NCHL,  NWAV, NSZA)
 
;-----------------------------------------
; COPY INPUT ARRAY IN GENERIC NAME 

 N = N_ELEMENTS(SZA)
 X = DBLARR([3,N])
 X[0,*] = CHL
 X[1,*] = MAKE_ARRAY(N, /FLOAT, VALUE=WAV)
 X[2,*] = SZA

;-----------------------------------------
; COMPUTE INDICES AND WEIGHTS OF THE
; DOWNWARD TRANSMITTANCE INTERPOLATION

 INDEX  = INTARR(3,N)
 WEIGHT = DBLARR(3,N)

 FOR I=0, 2 DO BEGIN

    CASE I OF
       0: XREF = MUD_CHL
       1: XREF = MUD_WAV
       2: XREF = MUD_SZA
    ENDCASE

    INDEX[I,*]  = VALUE_LOCATE(XREF, X[I,*])

    ID=WHERE(INDEX[I,*] GE 0 AND INDEX[I,*] LT N_ELEMENTS(XREF)-1, COUNT, NCOMPLEMENT=NCOUNT)
    IF COUNT NE 0 THEN WEIGHT[I,ID]=(X[I,ID]-XREF[INDEX[I,ID]])/(XREF[INDEX[I,ID]+1]-XREF[INDEX[I,ID]])
    IF NCOUNT NE 0 THEN BEGIN
      ID=WHERE(INDEX[I,*] EQ -1 )
      IF ID[0] NE -1 THEN BEGIN
        INDEX[I,ID]   = 0
        WEIGHT[I,ID]  = 0.
      ENDIF
      ID=WHERE(INDEX[I,*] EQ N_ELEMENTS(XREF)-1 )
      IF ID[0] NE -1 THEN BEGIN
        INDEX[I,ID]   = N_ELEMENTS(XREF)-2
        WEIGHT[I,ID]  = 1.
      ENDIF
    ENDIF

 ENDFOR

;-----------------------------------------
; INTERPOLATE IN THE MUD LUT

 MUD = MAKE_ARRAY(N,/FLOAT,VALUE=0.)

 FOR I0 = 0, 1 DO BEGIN
 FOR I1 = 0, 1 DO BEGIN
 FOR I2 = 0, 1 DO BEGIN
    MUD[*] += (I0?WEIGHT[0,*]:(1.-WEIGHT[0,*]))*$
              (I1?WEIGHT[1,*]:(1.-WEIGHT[1,*]))*$
              (I2?WEIGHT[2,*]:(1.-WEIGHT[2,*]))*MUD_DATA[INDEX[0,*]+I0,INDEX[1,*]+I1,INDEX[2,*]+I2]
 ENDFOR
 ENDFOR
 ENDFOR

 RETURN, MUD

END
