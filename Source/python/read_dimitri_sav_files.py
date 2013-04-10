__author__ = 'marrabld'
"""
!!! Under construction !!!
"""

import scipy.io
import pylab


class DimitriObject:
    def __init__(self):

        self.decimal_year = None
        self.sensor_zenith = None
        self.sensor_azimuth = None
        self.sun_zenith = None
        self.sun_azimuth = None
        self.ozone = None
        self.pressure = None
        self.relative_humidity = None
        self.wind_zonal = None
        self.wind_merid = None
        self.wvap = None
        self.bands = {'PARASOL': ['443', '490', '565', '670', '754', '760', '865', '910', '1020']} ## !!! these are the same as DIMITRI FOR NOW!! CHECK
        self.bands['MERIS'] = ['412', '443', '490', '510', '560', '620', '665', '681', '708', '753', '761', '778', '865', '885', '900']
        self.sensor_name = 'PARASOL'

    def read_dimitri_file(self, file='/home/marrabld/projects/DIMITRI_2.0/Input/Site_DomeC/PARASOL/Proc_Calibration_1/PARASOL_TOA_REF.dat',
                          sensor_name='PARASOL'):  # lint:ok

        self.sensor_name = sensor_name
        self.num_bands = 9
        tmp = scipy.io.readsav(file, python_dict=True)
        tmp_dict = tmp['sensor_l1b_ref']

        self.decimal_year = tmp_dict[:, 0]
        self.sensor_zenith = tmp_dict[:, 1]
        self.sensor_azimuth = tmp_dict[:, 2]
        self.sun_zenith = tmp_dict[:, 3]
        self.sun_azimuth = tmp_dict[:, 4]
        self.ozone = tmp_dict[:, 5]
        self.pressure = tmp_dict[:, 6]
        self.relative_humidity = tmp_dict[:, 7]
        self.wind_zonal = tmp_dict[:, 8]
        self.wind_merid = tmp_dict[:, 9]
        self.wvap = tmp_dict[:, 10]

        self.reflectance = tmp_dict[:, 17:17 + len(self.bands[self.sensor_name])]
        self.reflectance_std = tmp_dict[:, 17 + len(self.bands[self.sensor_name]):, ]

        # WORKARROUND swap bands 5 & 6 - indicies 4 & 5
        tmp = 0
        if self.sensor_name == 'PARASOL':
            tmp = scipy.copy(self.reflectance[:,4])
            self.reflectance[:,4] = self.reflectance[:,5]
            self.reflectance[:,5] = tmp


    def plot_toa_reflectance(self, roi=[400], hold='off', show=True):

        xdata = scipy.linspace(0, self.num_bands, self.num_bands)

        for i in range(len(roi)):
            pylab.errorbar(self.bands[self.sensor_name], self.reflectance[roi[i], :],
                           yerr=self.reflectance_std[roi[i], :])
            #pylab.scatter(self.bands[self.sensor_name], self.reflectance[roi[i], :])
            pylab.minorticks_on()
            pylab.xlabel('Wavelength (nm)')
            pylab.ylabel('TOA Reflectance (sr^{-1})')
            pylab.ylim([0, 1])
            pylab.title(self.sensor_name)
            if hold == 'off' and show:
                pylab.show()

        if show:
            pylab.show()


if __name__ == "__main__":
    FOI = '/home/marrabld/projects/DIMITRI_2.0/Input/Site_DomeC/MERIS/Proc_3rd_Reprocessing/MERIS_TOA_REF.dat'
    dim_obj = DimitriObject()
    dim_obj.read_dimitri_file(FOI, sensor_name='MERIS')
    dim_obj.plot_toa_reflectance([1000], hold='on', show=False)

    dim_obj.read_dimitri_file(file='/home/marrabld/projects/DIMITRI_2.0/Input/Site_DomeC/PARASOL/Proc_Calibration_1/PARASOL_TOA_REF.dat',
                          sensor_name='PARASOL')
    dim_obj.plot_toa_reflectance([1000], hold='on')








