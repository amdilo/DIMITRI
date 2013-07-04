FUNCTION GET_VIIRS_TIMESERIES_PLOTS, OUTPUT_SAV, NO_ZBUFF=NO_ZBUFF, COLOUR_TABLE=COLOUR_TABLE, PLOT_XSIZE=PLOT_XSIZE, PLOT_YSIZE=PLOT_YSIZE, VERBOSE=VERBOSE
;+
; :Name:
;      GET_MODISA_TIMESERIES_PLOTS
;
; :Description:
;      Generates plots from the supplied time series of dimitri modisa data.
;
; :Calling sequence:
;      RES = GET_MODISA_TIMESERIES_PLOTS(OUTPUT_SAV)
;
; :Params:
;      OUTPUT_SAV :
;         String of the sensor/processing output sav
;
; :Keywords:
;      COLOUR_TABLE :
;          User defined idl colour table index (default is 39)
;      PLOT_XSIZE :
;          Width of generated plots (default is 700px)
;      PLOT_YSIZE :
;          Height of generated plots (default is 400px)
;      NO_ZBUFF :
;           If set then plots are generated in windows and not within the z-buffer.
;      VERBOSE :
;           processing status outputs
;
; :Returns:
;      plots of toa reflectance, reflectance evolution, solar zenith angle and sensor
;      zenith angle automatically saved.
;
; :Common blocks:
;      NONE
;
; :History:
;      02 JUL 2013 - D MARRABLE    - DIMITRI-2 V1.0
;-
