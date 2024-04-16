### MIE Scattering Code

To generate the tables of param. of diffusion used by the PCM
-------------------------------------------------------------------

From the attached code, named optpropgen.f. It generates
the diffusion parameter table used by the PCM.
To generate this table:

- Once the archive has been unzipped (tar -xvzf MIE_BH_v2.tar.gz),
    compile the model with "./comp_optprop.sh"
- Then, launch "./optpropgen.e", and after calculation, a file
    named "optprop_tmp.dat" has normally been generated; it is
    this file that the GCM uses for radiative transfer
    (entered by the variable "file_id" in suaer.F90)

The code is set to generate the broadcast parameters of the
dust for different sizes.
To change aerosols, look for the "param_" flag in
optpropgen.f, which contains:

- param_mie: to adjust the number of subintervals on which we
    integrated to obtain the final effective radii, the number
    wavelengths in the input file, and the limits of
    the integration interval;
- 2 flags param_conv: to set the number of effective departments
    final, the variance used for the convolution, and the bounds
    the interval of the effective radii;
- param_file: to set the name of the input file, containing
    the complex refractive index;
- param_output: to set the name of the output file, which will be
    used in the GCM and declared in the file_id variable of
    suaer.F90;

Enjoy!

