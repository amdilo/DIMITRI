import glob
from math import floor
from multiprocessing import Process
import os

__author__ = 'marrabld'

import read_dimitri_raw_data_file


class BatchObject():
    def __init__(self, ncpus=-1):
        self.ncpus = ncpus # use -1 to query computer and use all available

    def batch_process_satellite_file(self, directory, file_type='parasol', deep=True):
        """


        """
        file_list = []
        done = False

        if self.ncpus == -1:
            self.ncpus = os.sysconf("SC_NPROCESSORS_ONLN")
            print self.ncpus

        if deep:
            for root, dirs, files in os.walk(directory):
                for file in files:

                    jpg = '.jpg' in file

                    if not (not (file_type == 'parasol') or not (
                            'P3L1TBG' in file) or not (not jpg)):  # 'parasol file have no file extension

                        ##
                        # Good change we found a valid parasol file then add to list
                        ##
                        file_list.append(os.path.join(root, file))

        ##
        # figure out how many blocks to do. # break up the process in to 'blocks' == sub
        ##

        sub = floor(len(file_list) / self.ncpus)
        remainder = len(file_list) - (sub * self.ncpus)
        while not done:
            for l in range(0, int(sub)):
                for i in range(0, int(self.ncpus)):
                    file_num = int((i * sub) + l) #iterate within our block
                    print('Starting block :: ' + str(file_num))
                    print('Of file :: ' + file_list[file_num])

                    p = Process(target=self.__process, args=(file_list[file_num],))
                    p.start()

                p.join()

            self.ncpus = remainder
            remainder = 0
            sub = 1
            if remainder == 0:
                done = True


    def __process(self, file_name):
        """


        """
        try:
            sat_obj = read_dimitri_raw_data_file.DimitriSatelliteObject()
            l1b_data = sat_obj.read_satellite_file(file_name)
            sat_obj.write_dictionary_to_csv(file_name + '.csv')
        except:
            print('ERROR :: processing :: ' + file_name)
            f = open('error_list.txt', 'a')
            f.write('ERROR :: processing :: ' + file_name + '\n')
            f.close()


if __name__ == "__main__":
    batch_object = BatchObject()
    batch_object.batch_process_satellite_file('/home/marrabld/projects/DIMITRI_2.0/Input')
