DIMITRI
=======

Database for Imaging Multi-spectral Instruments and Tools for Radiometric Intercomparison

Overview
--------

The DIMITRI software package contains a suite of IDL routines for the intercomparison of Top Of
Atmosphere (TOA) radiance and reflectance values within the 400nm - 4μm wavelength range; this
is generally known as Level 1b Earth Observation (EO) satellite data. The package includes product
reader and data extraction routines, and allows comparison of satellite data based on User defined
cloud screening parameters as well as temporal, spatial and geometric matching. DIMITRI is a
database containing the so-called remote sensing TOA reflectance values from 2002 until the
present day for ATSR2 (ESA), AATSR (ESA), MERIS (ESA), MODIS-Aqua (NASA), PARASOL POLDER-3
(CNES), and VEGETATION (CNES) over eight predetermined validation sites (see Table 1).
DIMITRI is supplied with all L1b data pre-loaded, giving instant access to time series of data which
totals more than 5 terabytes. Additional data for other validation sites, or more recent acquisitions,
can be ingested into DIMITRI to allow even greater temporal and spatial analysis.

System Requirements
-------------------

A full IDL license is NOT required for DIMITRI V2.0; the freely available IDL Virtual Machine
(available at http://www.ittvis.com/ProductsServices/IDL/IDLModules/IDLVirtualMachine.aspx) will
allow use of the pre-compiled DIMITRI package and use of the full functionalities accessible from the
HMI.

DIMITRI has been developed to be compatible on both Linux and Windows based systems; however,
MAC compatibility cannot be guaranteed. DIMITRI has been developed for use with IDL 7.1 or
higher; the minimum requirements required for IDL 7.1 are therefore the minimum requirements for
running DIMITRI.

A full IDL license (http://www.ittvis.com) will allow command line usage, modification of routines
and recompilation of the software package.

How to use DIMITRI
------------------

Linux:
To clone the master branch from GitHub:

git clone https://github.com/dimitri-argans/DIMITRI

<strong>NOTE: DIMITRI insists on a version number appended to the directory you are running it in.</strong>

<strong>The following step is critical</strong>

    # rename the DIMITRI folder to DIMITRI_2.0
    cd ..
    mv DIMITRI DIMITRI_2.0
    cd DIMITRI_2.0
    idl –vm=DIMITRI_V2.0.sav		# 2.0 for master

For the same reason, if you checkout other (development) versions, e.g. dev3.1, change the version number appropriately (e.g. DIMITRI_3.1) before running DIMITRI:

    git checkout 3.1
    cd ..
    mv DIMITRI_2.0 DIMITRI_3.1


For further information on DIMITRI, please go to the website:

http://www.argans.co.uk/dimitri



DIMITRI Team
------------------
- Kathryn Barker (ARGANS)
- Marc Bouvet (ESA)
- Constant Mazeran (Solvo)
- Manuel Arias Ballesteros (ARGANS)
- Bahjat Alhammoud (ARGANS)
- Kelvin Hunter (ARGANS)
- John Hedley (ECS)
