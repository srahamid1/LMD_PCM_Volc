PROGRAM testconfig
!-
!$Id: testconfig.f90 386 2008-09-04 08:38:48Z bellier $
!-
! This software is governed by the CeCILL license
! See IOIPSL/IOIPSL_License_CeCILL.txt
  !
  USE getincom
  !
  !
  !      This program will do some basic tests on the getin module
  !
  !
  IMPLICIT NONE
  !
  LOGICAL           :: debug
  CHARACTER(LEN=80) :: filename
  CHARACTER(LEN=10), DIMENSION(3) :: strvec
  INTEGER           :: split
  REAL              :: g
  REAL, DIMENSION(3) :: realvec
  !
  !-
  !- set debug to have more information
  !-
  !Config  Key  = DEBUG_INFO
  !Config  Desc = Flag for debug information
  !Config  Def  = n
  !Config  Help = This option allows to switch on the output of debug
  !Config         information without recompiling the code.
  !-
  debug = .FALSE.
  CALL getin('DEBUG_INFO',debug) 
  !
  !Config  Key  = FORCING_FILE
  !Config  Desc = Name of file containing the forcing data
  !Config  Def  = islscp_for.nc
  !Config  Help = This is the name of the file which should be opened
  !Config         for reading the forcing data of the dim0 model.
  !Config         The format of the file has to be netCDF and COADS
  !Config         compliant.
  !-
  filename='islscp_for.nc'
  CALL getin('FORCING_FILE',filename)
  !
  !
  !Config  Key  = SPLIT_DT
  !Config  Desc = splits the timestep imposed by the forcing
  !Config  Def  = 12
  !Config  Help = With this value the time step of the forcing
  !Config         will be devided. In principle this can be run
  !Config         in explicit mode but it is strongly suggested
  !Config         to use the implicit method so that the
  !Config         atmospheric forcing has a smooth evolution.
  !-
  split = 12
  CALL getin('SPLIT_DT', split)
  !
  !
  !Config  Key  = GRAVIT
  !Config  Desc = Gravitation constant
  !Config  Def  = 9.98
  !Config  Help = In theory these parameters could also be defined through
  !Config         this mechanisme to ensure that the same value is used by
  !Config         all components of the model.
  !-
  g = 9.98
  CALL getin('GRAVIT', g)
  !
  !Config  Key  = WORDS
  !Config  Desc = A vector of words
  !Config  Def  = here there anywhere
  !Config  Help = An example for a vector of strings
  !-
  strvec(1) = "here"
  strvec(2) = "there"
  strvec(3) = "anywhere"
  CALL getin('WORDS', strvec)
  !
  !Config  Key  = VECTOR
  !Config  Desc = A vector of reals
  !Config  Def  = 1, 2, 3
  !Config  Help = An example for a vector of REALs
  !-
  realvec=(/1,2,3/)
  CALL getin('VECTOR', realvec)
  !
  WRITE(*,*) 'From the run.def we have extracted the following information :'
  WRITE(*,*) 'DEBUG : ', debug
  WRITE(*,*) 'FILENAME : ', filename(1:len_trim(filename))
  WRITE(*,*) 'SPLIT : ', split
  WRITE(*,*) 'G : ', g
  WRITE(*,*) 'WORDS : ', strvec
  WRITE(*,*) 'VECTOR : ', realvec
  !
  CALL getin_dump()
  !
END PROGRAM testconfig
