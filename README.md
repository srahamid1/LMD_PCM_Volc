# LMD Generic PCM Code Modified to Erupt Volcanoes on Mars

Modified version of the Generic LMD PCM used in Hamid et al. 2024. Based on the Generic LMD SVN revision: 2289.

Intructions on how to download other versions of the LMD PCM can be found here https://lmdz-forge.lmd.jussieu.fr/mediawiki/Planets/index.php/Quick_Install_and_Run

## Added Codes
trunk/LMDZ.COMMON/libf/phystd/volcano.F - Dispersal of volcanic products by the LMD/PCM

## Modified Codes
trunk/LMDZ.COMMON/libf/phystd/aeropacity.F90 -  Added option to compute aerosol optical depth in each gridbox for volcanic ash and sulfuric acid (h2so4).

trunk/LMDZ.COMMON/libf/phystd/aerosol_mod.F90 - Added volcanic ash and h2so4 aerosols to common file, which creates aerosol tags and initializes them to zero

trunk/LMDZ.COMMON/libf/phystd/callkeys_mod.F90 - Added variables to be read in from callphys.def including volcano tracer density (rho_volc), h2so4 aerosol optical depth (h2so4tau), latitude and longitude of volcano (lat_volc, lon_volc), mass flux of ash, water, and h2so4 (mmsource, wsource, h2so4source), height of dust and h2so4 layer in cases of a fixed aerosol optical depth (topdust, top_h2so4), radiatively active h2so4 and ash aerosol tied to tracer (aeroh2so4, aeroash), fixed ash aerosol distribution (aerofixash), and release height of volcanic products (dropheight).

(trunk/LMDZ.COMMON/libf/phystd/iniaerosol.F) - Added initialization of volcanic ash and h2so4 aerosols 

trunk/LMDZ.COMMON/libf/phystd/inifis_mod.F90 - Read in variables defined in callkeys_mod.F90

trunk/LMDZ.COMMON/libf/phystd/initracer.F - Added volcanic ash and h2so4 tracer qualities (density, radius, etc.)

trunk/LMDZ.COMMON/libf/phystd/physiq_mod.F90 - Call volcano.F. 

trunk/LMDZ.COMMON/libf/phystd/radii_mod.F90 - Added volcanic ash and h2so4 radii to compute effective radii of particles

trunk/LMDZ.COMMON/libf/phystd/suaer_corrk.F90 - Added names of volcanic ash and h2so4 optical property data files to be used by PCM 

trunk/LMDZ.COMMON/libf/phystd/tracer_h.F90 - Added volcanic ash and h2so4 tracer variables

trunk/LMDZ.COMMON/libf/phystd/turbdiff.F90 - Added options to turn off sublimation of water (1) when volcano is degassing, (2) in volcano grid point, or (3) depending on ash thickness
