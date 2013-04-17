import cPickle as pickle
import csv
import re
import scipy

import pylab


__author__ = 'marrabld'

import pidly # Use this to call one of DIMITRI's IDL functions and pass back the data structure

##!! This is required to prevent unwanted linefeeds in the csv file
scipy.set_printoptions(linewidth=2000)


class DimitriSatelliteObject():
    def __init__(self, gdl_path='/usr/bin/gdl'):

        self.idl = pidly.IDL(gdl_path, idl_prompt='GDL> ')
        self.l1b_data = None
        self.bands = {
            'PARASOL': ['443', '490p', '490u', '490q', '565', '670p', '670u', '670q', '763', '765', '865p', '865u',
                        '865q', '910', '1020'],
            'MERIS': ['412', '443', '490', '510', '560', '620', '665', '681', '708', '753', '761', '778',
                      '865', '885', '900']} ## !!! these are the same as DIMITRI FOR NOW!! CHECK
        self.sensor_name = 'PARASOL'
        self.num_bands = 16


    def read_satellite_file(self,
                            file='/home/marrabld/projects/DIMITRI_2.0/Input/Site_DomeC/PARASOL/Proc_Calibration_1/2006/P3L1TBG1042150KD_s74_00_S77_00_e118_00_E130_00',
                            sensor_name='PARASOL'):

        """

        :param file:
        :return lib_data: list of dictionaries
        """
        self.sensor_name = sensor_name
        self.num_bands = len(self.bands[sensor_name])

        self.idl("!PATH=!PATH + ':'+Expand_Path('+/home/marrabld/projects/DIMITRI_2.0/Source', /ALL_DIRS)")
        if sensor_name == 'PARASOL':
            self.l1b_data = self.idl.ev("get_parasol_l1b_data('" + file + "')")

        return self.l1b_data

    def pickle_reflectance_file(self, file="l1b.p", protocol=2):
        """


        :param file:
        :param protocol:
        """
        pickle.dump(self.reflectance, open(file, "wb"), protocol)

    def unpickle_reflectance_file(self, file="l1b.p"):
        """


        :param file:
        """
        self.reflectance = pickle.load(open(file, "rb"))

    def write_dictionary_to_csv(self, file="toa.csv"):
        """


        :rtype : object
        :param file:
        """
        ##
        # Open file
        ##

        f = open(file, 'wb')
        header_list = []
        num_directions = 16 # This may only be try for parasol

        ##
        # Write header info
        ##

        for i in range(0, len(self.l1b_data[0].keys())):
            if str(self.l1b_data[0].keys()[i])[0:3] == 'ref' or \
                            str(self.l1b_data[0].keys()[i])[0:3] == 'raa' or \
                            str(self.l1b_data[0].keys()[i])[0:3] == 'sza' or \
                            str(self.l1b_data[0].keys()[i])[0:3] == 'del' or \
                            str(self.l1b_data[0].keys()[i])[0:3] == 'vza' or \
                            str(self.l1b_data[0].keys()[i])[0:3] == 'seq':
                for l in range(num_directions):
                    f.write(self.l1b_data[0].keys()[i])
                    if l < num_directions - 1:
                        f.write(',')
            else:
                f.write(self.l1b_data[0].keys()[i])

            header_list.append(self.l1b_data[0].keys()[i]) #  keep track of the order

            if i < len(self.l1b_data[0].keys()) - 1:
                f.write(',')
            else:
                f.write('\n')

        ##
        # loop through data
        ##

        for i in range(len(self.l1b_data)):
            for j in range(len(header_list)):
                tmp = self.l1b_data[i][header_list[j]]

                ##
                # Remove multiple whitespace and replace with a single comma
                #replace "[,"  with ""  and ".]"
                ##

                tmp = str(tmp)
                tmp = re.sub(" +", ",", tmp)
                tmp = re.sub('\[,', '', tmp)  # !!!!! for testing!!!!!!
                tmp = re.sub(',\]', '', tmp)
                tmp = re.sub('\]', '', tmp)
                tmp = re.sub('\[', '', tmp)

                ##
                # If the tmp starts with ref_ then we need to write the header field 16 times; one for each direction
                # this will give each wave a header.
                ##

                f.write(tmp)

                if j < len(header_list) - 1:
                    f.write(',')
                else:
                    f.write('\n')

        f.close()

    def extract_toa_from_dict(self, toa_dict_list, direction=0):
        list_length = len(toa_dict_list)
        self.reflectance = scipy.empty([list_length, 15])
        for i in range(len(toa_dict_list)):
            self.reflectance[i, 0] = toa_dict_list[i]['ref_443np'][direction]
            self.reflectance[i, 1] = toa_dict_list[i]['ref_490p'][direction]
            self.reflectance[i, 2] = toa_dict_list[i]['ref_490p_u'][direction]
            self.reflectance[i, 3] = toa_dict_list[i]['ref_490p_q'][direction]
            self.reflectance[i, 4] = toa_dict_list[i]['ref_565np'][direction]
            self.reflectance[i, 5] = toa_dict_list[i]['ref_670p'][direction]
            self.reflectance[i, 6] = toa_dict_list[i]['ref_670p_u'][direction]
            self.reflectance[i, 7] = toa_dict_list[i]['ref_670p_q'][direction]
            self.reflectance[i, 8] = toa_dict_list[i]['ref_763np'][direction]
            self.reflectance[i, 9] = toa_dict_list[i]['ref_765np'][direction]
            self.reflectance[i, 10] = toa_dict_list[i]['ref_865p'][direction]
            self.reflectance[i, 11] = toa_dict_list[i]['ref_865p_u'][direction]
            self.reflectance[i, 12] = toa_dict_list[i]['ref_865p_q'][direction]
            self.reflectance[i, 13] = toa_dict_list[i]['ref_910np'][direction]
            self.reflectance[i, 14] = toa_dict_list[i]['ref_1020np'][direction]


    def plot_toa_reflectance(self, roi=[2000], hold='off', show=True):
        xdata = scipy.linspace(0, self.num_bands, self.num_bands)

        for i in range(len(roi)):
            #pylab.errorbar(self.bands[self.sensor_name], self.reflectance[roi[i], :],
            #              yerr=self.reflectance_std[roi[i], :])

            xdata = self.bands[self.sensor_name]

            for j in range(0, len(self.bands[self.sensor_name])):
                xdata[j] = str(xdata[j]).strip('abcdefghijklmnopqrstuvwxyz')

            pylab.plot(xdata, self.reflectance[roi[i], :], 'o')
            pylab.minorticks_on()
            pylab.xlabel('Wavelength (nm)')
            pylab.ylabel('TOA Reflectance (sr^{-1})')
            pylab.ylim([0, 1])
            pylab.title(self.sensor_name)
            if hold == 'off' and show:
                pylab.show()

        if show:
            pylab.show()


def read_hdf_file(self,
                  file='/home/marrabld/projects/DIMITRI_2.0/Input/Site_DomeC/PARASOL/Proc_Calibration_1/DomeC_PARASOL_Proc_Calibration_1.nc'):
    f = netcdf.netcdf_file(file, 'r')

    print(f.variables.keys())

    f.close()


if __name__ == "__main__":
    sat_obj = DimitriSatelliteObject()
    l1b_data = sat_obj.read_satellite_file()
    #sat_obj.idl.close()
    #sat_obj.extract_toa_from_dict(l1b_data)
    #sat_obj.pickle_reflectance_file()

    #sat_obj.unpickle_reflectance_file()
    #sat_obj.plot_toa_reflectance()

    sat_obj.write_dictionary_to_csv()
