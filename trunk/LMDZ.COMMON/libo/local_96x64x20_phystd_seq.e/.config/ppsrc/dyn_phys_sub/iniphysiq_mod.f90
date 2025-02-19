












MODULE iniphysiq_mod

CONTAINS

subroutine iniphysiq(ii,jj,nlayer, &
                     nbp, communicator, &
                     punjours, pdayref,ptimestep, &
                     rlatudyn,rlatvdyn,rlonudyn,rlonvdyn, &
                     airedyn,cudyn,cvdyn, &
                     prad,pg,pr,pcpp,iflag_phys)

use control_mod, only: nday 
use surf_heat_transp_mod, only: ini_surf_heat_transp
use infotrac, only : nqtot ! number of advected tracers
use planete_mod, only: ini_planete_mod
USE comvert_mod, ONLY: ap,bp,preff
use inifis_mod, only: inifis
use ioipsl_getin_p_mod, only: getin_p

use inigeomphy_mod, only: inigeomphy
use geometry_mod, only: cell_area, & ! physics grid area (m2)
                        longitude, & ! longitudes (rad)
                        latitude ! latitudes (rad)
! necessary to get klon_omp
USE mod_phys_lmdz_para, ONLY: klon_omp ! number of columns (on local omp grid)
USE dimphy, ONLY: init_dimphy

implicit none
include "dimensions.h"
include "paramet.h"
include "comgeom.h"
include "iniprint.h"

real,intent(in) :: prad ! radius of the planet (m)
real,intent(in) :: pg ! gravitational acceleration (m/s2)
real,intent(in) :: pr ! ! reduced gas constant R/mu
real,intent(in) :: pcpp ! specific heat Cp
real,intent(in) :: punjours ! length (in s) of a standard day
integer,intent(in) :: nlayer ! number of atmospheric layers
integer,intent(in) :: ii ! number of atmospheric coulumns along longitudes
integer,intent(in) :: jj  ! number of atompsheric columns along latitudes
integer,intent(in) :: nbp ! number of physics columns for this MPI process
integer,intent(in) :: communicator ! MPI communicator
real,intent(in) :: rlatudyn(jj+1) ! latitudes of the physics grid
real,intent(in) :: rlatvdyn(jj) ! latitude boundaries of the physics grid
real,intent(in) :: rlonvdyn(ii+1) ! longitudes of the physics grid
real,intent(in) :: rlonudyn(ii+1) ! longitude boundaries of the physics grid
real,intent(in) :: airedyn(ii+1,jj+1) ! area of the dynamics grid (m2)
real,intent(in) :: cudyn((ii+1)*(jj+1)) ! cu coeff. (u_covariant = cu * u)
real,intent(in) :: cvdyn((ii+1)*jj) ! cv coeff. (v_covariant = cv * v)
integer,intent(in) :: pdayref ! reference day of for the simulation
real,intent(in) :: ptimestep !physics time step (s)
integer,intent(in) :: iflag_phys ! type of physics to be called

logical :: ok_slab_ocean

  ! the common part for all planetary physics
  !------------------------------------------
  ! --> initialize physics distribution, global fields and geometry
  ! (i.e. things in phy_common or dynphy_lonlat)
  CALL inigeomphy(ii,jj,nlayer, &
               nbp, communicator, &
               rlatudyn,rlatvdyn, &
               rlonudyn,rlonvdyn, &
               airedyn,cudyn,cvdyn)

  ! the distinct part for all planetary physics (ie. things in phystd)
  !------------------------------------------

!$OMP PARALLEL

! copy some fundamental parameters to physics
! and do some initializations

! Initialize dimphy module => Now done in physics_distribution_mod
! call init_dimphy(klon_omp,nlayer)

! copy over preff , ap() and bp() 
call ini_planete_mod(nlayer,preff,ap,bp)

! for slab ocean, copy over some arrays
ok_slab_ocean=.false. ! default value
call getin_p("ok_slab_ocean",ok_slab_ocean)
if (ok_slab_ocean) then
  call ini_surf_heat_transp(ip1jm,ip1jmp1,unsairez,fext,unsaire, &
                            cu,cuvsurcv,cv,cvusurcu,aire,apoln,apols, &
                            aireu,airev)
endif

call inifis(klon_omp,nlayer,nqtot,pdayref,punjours,nday,ptimestep, &
            latitude,longitude,cell_area,prad,pg,pr,pcpp)


!$OMP END PARALLEL

end subroutine iniphysiq


END MODULE iniphysiq_mod
