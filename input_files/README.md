This directory contains a set of necessary input data needed to run the model. 

`callphys.def`, `gases.def`, `start.nc`, `startfi.nc`, `traceur.def`, `run.def`, and `z2sig.def` are needed to run the model.

`z2sig_v1.def` is version used in Hamid et al. 2024. Rename to `z2sig.def` upon use. 

`gcmify` is a script used to compile the model. Once compiled, copy or move `gcm_32x32x15_phystd_seq.e` from `trunk/LMDZ.COMMON/bin/` to the directory containing the initial conditions and parameter files. Note the 32x32x15 in the executable represents the model resolution and can be changed in `gcmify`. 

`newstartify` is a script used to compile the newstart program and allows the user to change the intial state. Once compiled, copy or move `newstart_32x32x15_phystd_seq.e`, from `trunk/LMDZ.COMMON/bin/` to the directory containing the initial conditions and parameter files. User can modify initial state from `start.nc` and `startfi.nc` or `start_archive.nc` file. 

`diagfi.def` contains a list of variables to be written to the diagfi.nc output file

`ns` is a handy file that renames restart files to start files

See this link for more information on model compilation and creating and modifying initial states: https://lmdz-forge.lmd.jussieu.fr/mediawiki/Planets/index.php/Quick_Install_and_Run#Running_the_GCM 
