












MODULE nrtype

  implicit none

  integer, parameter:: k8 = selected_real_kind(13)

  ! Frequently used mathematical constants (with precision to spare):

  REAL, PARAMETER :: PI=3.141592653589793238462643383279502884197
  REAL, PARAMETER :: PIO2=1.57079632679489661923132169163975144209858
  REAL, PARAMETER :: TWOPI=6.283185307179586476925286766559005768394
  REAL, PARAMETER :: SQRT2=1.41421356237309504880168872420969807856967
  REAL, PARAMETER :: EULER=0.5772156649015328606065120900824024310422

  REAL(K8), PARAMETER:: &
       PI_D = 3.141592653589793238462643383279502884197_k8
  REAL(K8), PARAMETER:: &
       PIO2_D=1.57079632679489661923132169163975144209858_k8
  REAL(K8), PARAMETER:: &
       TWOPI_D=6.283185307179586476925286766559005768394_k8

END MODULE nrtype
