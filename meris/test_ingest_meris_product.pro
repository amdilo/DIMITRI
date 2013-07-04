pro test_ingest_meris_product

;; Unit tests for ingesting meris product

;; Add required path variavles
;!PATH=!PATH + ':'+Expand_Path('+/home/marrabld/projects/mosaec/Source', /ALL_DIRS)

print, !PATH

;; Test Meris file to open
dir = '/home/marrabld/projects/DIMITRI_2.0/Input/Site_DomeC/MERIS/Proc_3rd_Reprocessing/2006'
file = 'MER_RR__1PNMAP20060924_005309_000000542051_00274_23875_0001.N1'

test_output = ingest_meris_product(dir + '/' + file)

help, test_output

end
