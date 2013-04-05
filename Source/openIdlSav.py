__author__ = 'marrabld'

import scipy.io
import pylab

tmp = scipy.io.readsav('/home/marrabld/projects/mosaec/Source/Input/Site_DomeC/PARASOL/Proc_Calibration_1/PARASOL_TOA_REF.dat', python_dict=False)

#print dir(tmp)

#for key, value in tmp.iteritems() :
#    print key, value

print(tmp.sensor_l1b_ref.shape)

pylab.plot(tmp.sensor_l1b_ref[20000,1:])
pylab.show()
