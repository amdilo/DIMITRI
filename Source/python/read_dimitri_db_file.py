__author__ = 'marrabld'

import csv
import os
import cPickle as pickle
import copy

class DimitriDb():
    def __init__(self):
        self.db = {}

    def read_dimitri_db_file(self,
                             csv_file=os.path.join(os.path.join(os.pardir, os.pardir), 'Bin/DIMITRI_DATABASE.CSV')):
        """
        Read DIMITRI database .csv file as a python dictionary

        :param csv_file: The DIMITRI database file
        """

        tmp = [1]

        print(csv_file)

        f = open(csv_file, "rt")
        try:
            reader = csv.DictReader(f, delimiter=";")
            self.db = dict.fromkeys(reader.fieldnames)
            for rows in reader:
                for i in range(0, len(reader.fieldnames)):
                    if self.db[reader.fieldnames[i]] is None:
                        tmp[0] = copy.deepcopy(rows[reader.fieldnames[i]])
                        self.db[reader.fieldnames[i]] = copy.deepcopy(tmp) # strip any whitespace
                    else:
                        self.db[reader.fieldnames[i]].append(rows[reader.fieldnames[i]].strip())

        except:
            print('cannot open file')
            raise

        finally:
            f.close()

    def pickle_db(self, file="db.p", protocol=2):
        """


        :param file:
        :param protocol:
        """
        pickle.dump(self.db, open(file, "wb"), protocol)

    def unpickle_db(self, file="db.p"):

        """


        :param file:
        """
        self.db = pickle.load(open(file, "rb"))


if __name__ == "__main__":
    dimitri_db = DimitriDb()
    #dimitri_db.read_dimitri_db_file()
    #dimitri_db.pickle_db()
    dimitri_db.unpickle_db()

