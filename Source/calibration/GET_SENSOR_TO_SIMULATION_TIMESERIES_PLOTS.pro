;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      GET_SENSOR_TO_SIMULATION_TIMESERIES_PLOTS
;*
;* PURPOSE:
;*      CREATE STATISTICAL OUTPUT FIGURES OF VICARIOUS CALIBRATION PROCESS
;*      1 - RTOA_RATIO / RTOA_RATIO_ESTIM + 1:1 TREND LINE AND REGRESSION RESULTS (RMSE/R2/...)
;       2 - AK_VALUES vs. PIX NUMBER
;*
;* CALLING SEQUENCE:
;*      RES = GET_SENSOR_TO_SIMULATION_TIMESERIES_PLOTS(METHOD, OUT_FILEPATH, OUT_FILENAME, BAND_NAME, BAND_REF_TO_SIM_RATIO_MEAN, DECIMAL_YEARS)
;*
;* INPUTS:
;*    METHOD          - CALIBRATION METHOD (DESERT, SUNGLINT OR RAYLEIGH)
;*		OUT_FILEPATH	  - PATH OF THE FIGURE IMAGE FILE
;*		OUT_FILENAME	  - FIGURE IMAGE FILE NAME (*.JPG)
;*		BAND_NAME		    - NAME OF THE STUDY BAND (BLUE/NIR/SWIR)
;*		BAND_REF_TO_SIM_RATIO_MEAN  - AK VALUES VALUES
;*		DECIMAL_YEARS - DECIMAL YEAR TIME BASE
;*
;* KEYWORDS:
;*      VERBOSE           - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      STATUS            - 1: NO ERRORS REPORTED, (-1) OR 0: ERRORS DURING INGESTION
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      12 JAN 2015 - NCG / MAGELLIUM - CREATION
;*
;* VALIDATION HISTORY:
;*      20 JAN 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL 
;*      30 MAR 2015 - NCG / MAGELLIUM      - WINDOWS 64BIT MACHINE IDL 8.0: COMPILATION AND OPERATION SUCCESSFUL (DIMITRI V4.0) 
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION GET_SENSOR_TO_SIMULATION_TIMESERIES_PLOTS, METHOD, OUT_FILENAME_FIG, DECIMAL_YEARS, BAND_REF_TO_SIM_RATIO_MEAN, BAND_RHO_SIM_UNCERT_MEAN, VERBOSE=VERBOSE

	FCT_NAME = 'GET_SENSOR_TO_SIMULATION_TIMESERIES_PLOTS'
	
	STATUS_OK = GET_DIMITRI_LOCATION('STATUS_OK')
	STATUS_ERROR = GET_DIMITRI_LOCATION('STATUS_ERROR')
  STATUS_NODATA = GET_DIMITRI_LOCATION('STATUS_NODATA')

	IF N_ELEMENTS(DECIMAL_YEARS) EQ 1 THEN BEGIN
		PRINT, FCT_NAME + ': ONLY ONE PRODUCT AVAILABLE, NO TIME SERIES GRAPHS CREATED'
		RETURN, STATUS_NODATA
	ENDIF

	METHOD = STRUPCASE(METHOD)

	IF KEYWORD_SET(VERBOSE) THEN PRINT, FCT_NAME + ': ' + METHOD 

  ; RETRIEVE INFORMATION FROM FIGURE NAME
  FIG_BASENAME = FILE_BASENAME( OUT_FILENAME_FIG, '.jpg' ) 
  FIG_BASENAME_ELTS = STRSPLIT(FIG_BASENAME, '_', /EXTRACT, COUNT=NB_ELTS)
  WAVELENGTH = FIG_BASENAME_ELTS[NB_ELTS-3]
  BAND_ID = FIG_BASENAME_ELTS[NB_ELTS-4]
  FIG_BASENAME_CPLMT = STRSPLIT(FIG_BASENAME, '_'+FIG_BASENAME_ELTS[NB_ELTS-4], /REGEX, /EXTRACT)
  FIG_BASENAME_CPLMT = FIG_BASENAME_CPLMT[0]

	; CHECK IF FILENAME EXISTS
	; IF YES DELETE IT
	JPEG_FILENAME_INFO = FILE_INFO(OUT_FILENAME_FIG)
	IF JPEG_FILENAME_INFO.EXISTS EQ 1 THEN BEGIN
		IF KEYWORD_SET(VERBOSE) THEN PRINT, FCT_NAME + ': JPEG FILE ' + OUT_FILENAME_FIG + ' EXIST > OVERWRITE'
		FILE_DELETE, OUT_FILENAME_FIG
	ENDIF

	MACHINE_WINDOW = !D.NAME
	SET_PLOT, 'Z'
	DEVICE, SET_RESOLUTION=[1000,720], SET_PIXEL_DEPTH=24
	DEVICE, SET_FONT='Times', /TT_FONT 
	;DEVICE, SET_RESOLUTION=[CFIG_DATA.(1)[0],CFIG_DATA.(1)[1]],SET_PIXEL_DEPTH=24
	DEVICE, DECOMPOSED = 0
	ERASE
	LOADCT, 14, /SILENT

	; INITIALISATION OF THE COLOR INDEX
	RED_INDEX=1
	GREEN_INDEX=2
	BLUE_INDEX=3
	TVLCT, 255, 0, 0, 1  ; RED COLOR
	TVLCT, 0, 255, 0, 2  ; GREEN COLOR
	TVLCT, 0, 0, 255, 3  ; BLUE COLOR

	; SELECT MULTI PLOT ON 2 AXES
	!P.MULTI = [0, 1, 1]

  ;------------------------
  ; GET X/Y RANGE OF THE PLOT
	RANGE_DATE = [ FIX(MIN(DECIMAL_YEARS)), FIX(MAX(DECIMAL_YEARS))+1 ]
;	RANGE_Y = [ MIN([MIN(BAND_REF_TO_SIM_RATIO_MEAN),1.0]), MAX([MAX(BAND_REF_TO_SIM_RATIO_MEAN),1.0]) ]
  RANGE_Y = [ MIN([MIN(BAND_REF_TO_SIM_RATIO_MEAN),0.9]), MAX([MAX(BAND_REF_TO_SIM_RATIO_MEAN),1.1]) ]
	MARGE_RANGE_Y = 0.1*(RANGE_Y[1] - RANGE_Y[0])
	RANGE_Y = [ RANGE_Y[0]-MARGE_RANGE_Y, RANGE_Y[1]+MARGE_RANGE_Y ]

	YEAR_RANGE = [ FIX(RANGE_DATE[0]), FIX(RANGE_DATE[1]) ]

  ;------------------------
  ; ADAPT RANGE MARGE TO THE NUMBER OF STATISTICAL LINE TO PRINT ON FIGURE
	NB_LINE_STAT = 5
	ADD_RANGE_FACTOR = (NB_LINE_STAT+0.5) * 0.04 + 0.02
	RANGE_Y_GRAPH=[RANGE_Y(0), (RANGE_Y(1)-RANGE_Y(0))/(1-ADD_RANGE_FACTOR) + RANGE_Y(0) ]

  ;------------------------
  ; INITIALISE PLOT
  
	PLOT,DECIMAL_YEARS,BAND_REF_TO_SIM_RATIO_MEAN,/NODATA,$
	COLOR = 0, BACKGROUND = 255,$
	CHARSIZE = 1.0, $
	POSITION = [0.1, 0.1, 0.9, 0.9], $
	YMARGIN = [25, 2], $  ; [4,2] BY DEFAULT
	TITLE  = METHOD + ' - RTOA Sensor vs RTOA Simulation Temporal Variability - PERIOD [' $
	                + STRTRIM(STRING(YEAR_RANGE[0]),1) + '-' + STRTRIM(STRING(YEAR_RANGE[1]),1) + ']' $
	                + '!C--!C' + FIG_BASENAME_CPLMT + ' ('+BAND_ID+' - '+WAVELENGTH+'nm)', $  ; ADD 2 NEW LINES
	XRANGE = RANGE_DATE, $
	YRANGE = RANGE_Y_GRAPH, $
	XSTYLE = 1, YSTYLE = 1, $  ; FORCE AXES TO CORRESPOND EXACTLY TO SPECIFIED AXIS RANGE
	XTITLE = 'Decimal Year',$
	YTITLE = 'RTOA Sensor / RTOA Simulation',$
	XTICKFORMAT='((F8.2))',$
	YTICKFORMAT='((F8.2))'

  ;------------------------
  ; COMPUTE LINE FIT
  
	DYEAR_TIME_RANGE = LINSPACE(RANGE_DATE[0],RANGE_DATE[1],STEPNB=25)
	LINFIT_COEFFS = LINFIT(DECIMAL_YEARS-RANGE_DATE[0], BAND_REF_TO_SIM_RATIO_MEAN)
	AK_FIT_VALUES = LINFIT_COEFFS[0] + LINFIT_COEFFS[1]*(DYEAR_TIME_RANGE-RANGE_DATE[0])

	RESIDUALS = BAND_REF_TO_SIM_RATIO_MEAN - AK_FIT_VALUES
	SSE = TOTAL(RESIDUALS * RESIDUALS)
	RMSE = SQRT(SSE/N_ELEMENTS(RESIDUALS))
	R_COEFF = CORRELATE(AK_FIT_VALUES, BAND_REF_TO_SIM_RATIO_MEAN)
	R2_COEFF = R_COEFF^2
	NB_PTS=N_ELEMENTS(DECIMAL_YEARS)

  ;------------------------
  ; PLOTS
  
;	OPLOT, DYEAR_TIME_RANGE, AK_FIT_VALUES, COLOR = 12, THICK=2
  OPLOT, DYEAR_TIME_RANGE, AK_FIT_VALUES, COLOR = GREEN_INDEX, THICK=2
	OPLOT, RANGE_DATE, [1, 1], COLOR = BLUE_INDEX, LINESTYLE=2, THICK=2
	OPLOT, DECIMAL_YEARS, BAND_REF_TO_SIM_RATIO_MEAN, COLOR = 70, PSYM = 1, SYMSIZE = 0.75, THICK=3
;    OPLOT,DECIMAL_YEARS,BAND_REF_TO_SIM_RATIO_MEAN,COLOR = RED_INDEX, PSYM = 1, SYMSIZE = 8

  ;------------------------
  ; ERROR BARS 
  ERRPLOT, DECIMAL_YEARS, BAND_REF_TO_SIM_RATIO_MEAN-BAND_RHO_SIM_UNCERT_MEAN, $
                          BAND_REF_TO_SIM_RATIO_MEAN+BAND_RHO_SIM_UNCERT_MEAN, $
                          COLOR = RED_INDEX

  ;------------------------
  ; WRITE STATISTICAL INFOS ON FIGURE

  FIT_STRINGS=STRARR(NB_LINE_STAT)
  FIT_STRINGS(0)='NB OF POINTS = ' + STRTRIM(STRING(NB_PTS),1)
  FIT_STRINGS(1)='COEFF. A(0) (intercept) = ' + STRTRIM(STRING(LINFIT_COEFFS(0),FORMAT='(%"%0.4f")'),1)
  FIT_STRINGS(2)='COEFF. A(1) (slope)     = ' + STRTRIM(STRING(LINFIT_COEFFS(1),FORMAT='(%"%0.4f")'),1)
  FIT_STRINGS(3)='Correlation coeff. : R = ' + STRTRIM(STRING(R_COEFF,FORMAT='(%"%0.4f")'),1)
  FIT_STRINGS(4)='Residuals RMSE = ' + STRTRIM(STRING(RMSE,FORMAT='(%"%0.4f")'),1)
	FOR I_INFOS=0, NB_LINE_STAT-1 DO BEGIN
		XYOUTS, RANGE_DATE[0]+0.03*(RANGE_DATE(1)-RANGE_DATE(0)), RANGE_Y_GRAPH(1)-(I_INFOS+1.5)*0.04*(RANGE_Y_GRAPH(1)-RANGE_Y_GRAPH(0)), FIT_STRINGS(I_INFOS), /DATA, COLOR = 70
	END
		
	; CAPTURE Z BUFFER IMAGE
	FIG_CAPTURE = TVRD(TRUE=1)

  ;------------------------
	; WRITE CAPTURE IMAGE TO OUTPUT JPEG FILE	
	WRITE_JPEG, OUT_FILENAME_FIG, FIG_CAPTURE, TRUE=1, QUALITY=100
	
	; RESTORE MULTI MODE TO SINGLE
	ERASE
	; RESTORE PLOT MODE TO MACHINE
	SET_PLOT, MACHINE_WINDOW

	IF KEYWORD_SET(VERBOSE) THEN PRINT, FCT_NAME + ': JPG FILE ' + OUT_FILENAME_FIG + ' WRITTEN'  

	RETURN, STATUS_OK

END