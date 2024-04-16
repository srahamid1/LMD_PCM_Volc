c     -------------------------------------------------------------
c     MIE CODE designed for the LMD/GCM
c     This code generates the look-up tables used by to GCM to
c     compute the cloud scattering parameters in each grid box.
c     
c     Mie code: Bohren and Huffman (1983), modified by B.T.Draine
c     Interface and integration: F. Montmessin
c     Implementation into the LMD/GCM: J.-B. Madeleine 08W38
c     -------------------------------------------------------------

      PROGRAM optpropgen

      IMPLICIT NONE

c     -------------------------------------------------------------
c     PARAMETERS USED BY THE MIE CODE BEFORE CONVOLUTION          |
c     param_mie                                                   |
c     -------------------------------------------------------------
      INTEGER nsize,nsun ! Number of integration subintervals
                         !   Useful when activice is true.
c     Parameters for water ice:
c      PARAMETER (nsize=1E4,nsun=106) ! 127 VIS 81 IR
c      REAL rmin,rmax
c      DATA rmin /1.e-10/   ! Min. and max radius of the
c      DATA rmax /1.e-4/ !   interval in METERS

c      Parameters for volcanic ash:
      PARAMETER (nsize=1E4, nsun=24) ! 24 VIS 38 IR 
      REAL rmin,rmax
      DATA rmin /1.e-6/   ! Min. and max radius of the
      DATA rmax /13.e-5/ !   interval in METERS


c     Parameters for sulfuric acid:
c
c      REAL rmin,rmax
c      DATA rmin /1.e-10/   ! Min. and max radius of the
c      DATA rmax /1.e-4/ !   interval in METERS
      
c     Parameters for elemental sulfur:
c      PARAMETER (nsize=1E4, nsun=105) ! 105 VIS 172 IR 
c      PARAMETER (nsize=1E4, nsun=172) ! 105 VIS 172 IR 
c      REAL rmin,rmax
c      DATA rmin /1.e-10/   ! Min. and max radius of the
c      DATA rmax /1.e-4/ !   interval in METERS


c     Parameters for co2 ice:
!      PARAMETER (nsize=2E3,nsun=158) ! 200 VIS 158 IR
!      REAL rmin,rmax
!      DATA rmin /1.e-6/   ! Min. and max radius of the
!      DATA rmax /1000.e-6/ !   interval in METERS

c     -------------------------------------------------------------

      REAL  QextMono(nsize,nsun),
     &      QscatMono(nsize,nsun),gMono(nsize,nsun)
      REAL  CextMono(nsize,nsun),CscatMono(nsize,nsun)
      DOUBLE PRECISION radiustab(nsize)

c     VARIABLES USED BY THE BHMIE CODE 

      REAL  x(nsun)
      REAL  ni(nsun)
      REAL  nr(nsun)
      REAL  xf
      DOUBLE PRECISION pi
      COMPLEX refrel
      INTEGER MXNANG,NANG
      PARAMETER(MXNANG=1000)
      REAL  S1(2*MXNANG-1),S2(2*MXNANG-1)
     
      REAL  QBACK

c     VARIABLES USED FOR THE OUTPUT FILES

      CHARACTER(LEN=132) file_id
      CHARACTER(LEN=5) radius_id

c     -------------------------------------------------------------
c     PARAMETERS USED BY THE CONVOLUTION                          |
c     param_conv                                                  |
c     -------------------------------------------------------------
      INTEGER nreff
      PARAMETER (nreff=50)
c     -------------------------------------------------------------
      REAL reff(nreff),nueff
      REAL logvratreff
      DOUBLE PRECISION vratreff
      REAL r_g,sigma_g
      DOUBLE PRECISION dfi
      DOUBLE PRECISION dfi_tmp(nsize+1)
      REAL radiusint(nsize+1)
      REAL  Qext_tmp(nsun),omeg_tmp(nsun),g_tmp(nsun),pirr_tmp(nsun)
      REAL  Qscat_tmp(nsun)
      REAL  Cext_tmp(nsun),Cscat_tmp(nsun)

      DOUBLE PRECISION derf
      INTRINSIC derf

      REAL :: Qextint(nsun,nreff)
      REAL :: Qscatint(nsun,nreff)
      REAL :: omegint(nsun,nreff)
      REAL :: gint(nsun,nreff)

c     Local variables

      REAL  Qext_mono(nsun,nsize),
     &      Omeg_mono(nsun,nsize),
     &      g_mono(nsun,nsize)
      DOUBLE PRECISION vrat

      INTEGER i,j,l

      radiustab(1)    = rmin
      radiustab(nsize) = rmax

      vrat = log(rmax/rmin)/float(nsize-1)*3.
      vrat = exp(vrat)

      do i = 2, nsize-1
        radiustab(i) = radiustab(i-1)*vrat**(1./3.)
      enddo
      do i = 1, nsize
        WRITE(*,*) i,radiustab(i)
      enddo

c     Number of angles between 0 and 90 degrees
      NANG = 10
      pi = 2. * asin(1.d0)

c     -------------------------------------------------------------
c     OPTICAL INDICES: FILENAME                                   |
c     param_file                                                  |
c     -------------------------------------------------------------
c      OPEN(1,file='optind_h2so4_vis.dat') 
c      OPEN(1,file='optind_h2so4_ir.dat') 
       OPEN(1,file='optind_ash_grimsvotn_vis.dat')
c       OPEN(1,file='optind_ash_grimsvotn_ir.dat')
c     -------------------------------------------------------------
      do l = 1, nsun
        read(1,*) x(l),nr(l),ni(l)
        x(l)=x(l)*1.e-6 ! don't forget this line if necessary !
      enddo
      close(1)

      DO i = 1, nsize
        do l = 1, nsun
          refrel = cmplx(nr(l),ni(l))
          xf = 2. * pi * radiustab(i) / x(l)
          call bhmie(xf,refrel,NANG,S1,S2,
     &               QextMono(i,l),QscatMono(i,l),QBACK,gMono(i,l))
          CextMono(i,l)=QextMono(i,l)*pi*radiustab(i)*radiustab(i)
          CscatMono(i,l)=QscatMono(i,l)*pi*radiustab(i)*radiustab(i)
          Qext_mono(l,i) = QextMono(i,l)
          Omeg_mono(l,i) = QscatMono(i,l) / QextMono(i,l)
          g_mono(l,i) = gMono(i,l)
        enddo
      ENDDO

c     -------------------------------------------------------------
c     PARAMETERS USED BY THE CONVOLUTION                          |
c     param_conv                                                  |
c     -------------------------------------------------------------
      nueff = 0.04 ! Effective variance of the log-normal distr. !!
      reff(1) = 1E-6     ! Minimum effective radius
      IF (nreff.GT.1) THEN
        reff(nreff) = 13.e-5 ! Maximum effective radius
c     -------------------------------------------------------------
        logvratreff = log(reff(nreff)/reff(1))/float(nreff-1)*3.
        vratreff = exp(logvratreff)
        do i = 2, nreff-1
          reff(i) = reff(i-1)*vratreff**(1./3.)
        enddo
        do i = 1, nreff
          print*,i,reff(i)
        enddo
      ENDIF

c     Integration radius and effective variance

      radiusint(1) = 1.e-9
      DO i = 2,nsize
          radiusint(i) = ( (2.*vrat) / (vrat+1.) )**(1./3.) *
     &               radiustab(i-1)
      ENDDO
      radiusint(nsize+1) = 1.e-2
      WRITE(*,*) 'radiusint: ',radiusint

c     Integration

      DO j=1,nreff

      sigma_g = log(1.+nueff) ! r_g and sigma_g are defined in
      r_g = exp(2.5*sigma_g)  ! [hansen_1974], "Light scattering in
      sigma_g = sqrt(sigma_g) ! planetary atmospheres",
      r_g = reff(j) / r_g     ! Space Science Reviews 16 527-610.

      Qext_tmp(:) = 0.
      Qscat_tmp(:) = 0.
      omeg_tmp(:) = 0.
      g_tmp(:) = 0.
      pirr_tmp(:) = 0.
      Cext_tmp(:) = 0.
      Cscat_tmp(:) = 0.

      dfi_tmp(:) = log(radiusint(:)/r_g)/sqrt(2.)/sigma_g
      DO i = 1,nsize
        dfi = 0.5*( derf(dfi_tmp(i+1))-derf(dfi_tmp(i)) )
        DO l = 1,nsun
          Cext_tmp(l) = Cext_tmp(l) + CextMono(i,l) * dfi
          Cscat_tmp(l) = Cscat_tmp(l) +
     &                   CscatMono(i,l) * dfi
          Qext_tmp(l) = Qext_tmp(l) +
     &      QextMono(i,l)*pi*radiustab(i)*radiustab(i)*dfi
          Qscat_tmp(l) = Qscat_tmp(l) +
     &      QscatMono(i,l)*pi*radiustab(i)*radiustab(i)*dfi
          g_tmp(l) = g_tmp(l) +
     &      gMono(i,l)*pi*radiustab(i)*radiustab(i)*
     &      QscatMono(i,l)*dfi
          pirr_tmp(l) = pirr_tmp(l) +
     &                pi*radiustab(i)*radiustab(i)*dfi
        ENDDO
      ENDDO

      DO l=1,nsun
        Qextint(l,j) = Qext_tmp(l)/pirr_tmp(l)
        Qscatint(l,j) = Qscat_tmp(l)/pirr_tmp(l)
        omegint(l,j) = Qscat_tmp(l)/Qext_tmp(l)
        gint(l,j) = g_tmp(l)/Qscatint(l,j)/pirr_tmp(l)
      ENDDO

      ENDDO

c     Writing the LMD/GCM output file
c     -------------------------------

c     -------------------------------------------------------------
c     OUTPUT: FILENAME                                            |
c     param_output                                                |
c     -------------------------------------------------------------
      OPEN(FILE='optprop_tmp.dat',UNIT=60,
     &  FORM='formatted', STATUS='replace')
c     -------------------------------------------------------------

      WRITE(UNIT=60,FMT='(a31)') '# Number of wavelengths (nwvl):'
      WRITE(UNIT=60, FMT='(i4)') nsun

      WRITE(UNIT=60,FMT='(a27)') '# Number of radius (nsize):'
      WRITE(UNIT=60, FMT='(i5)') nreff

      WRITE(UNIT=60,FMT='(a24)') '# Wavelength axis (wvl):'
      WRITE(UNIT=60, FMT='(5(1x,e12.6))') x

      WRITE(UNIT=60,FMT='(a30)') '# Particle size axis (radius):'
      WRITE(UNIT=60, FMT='(5(1x,e12.6))') reff

      WRITE(UNIT=60,FMT='(a29)') '# Extinction coef. Qext (ep):'
      DO j=1,nreff
        WRITE(UNIT=radius_id, FMT='(I5)') j
        WRITE(UNIT=60,FMT='(a21)') '# Radius number '//radius_id
        WRITE(UNIT=60, FMT='(5(1x,e12.6))') Qextint(:,j)
      ENDDO

      WRITE(UNIT=60,FMT='(a28)') '# Single Scat Albedo (omeg):'
      DO j=1,nreff
        WRITE(UNIT=radius_id, FMT='(I5)') j
        WRITE(UNIT=60,FMT='(a21)') '# Radius number '//radius_id
        WRITE(UNIT=60, FMT='(5(1x,e12.6))') omegint(:,j)
      ENDDO

      WRITE(UNIT=60,FMT='(a29)') '# Assymetry Factor (gfactor):'
      DO j=1,nreff
        WRITE(UNIT=radius_id, FMT='(I5)') j
        WRITE(UNIT=60,FMT='(a21)') '# Radius number '//radius_id
        WRITE(UNIT=60, FMT='(5(1x,e12.6))') gint(:,j)
      ENDDO

      CLOSE(60)

      OPEN(FILE='SSA.dat',UNIT=61,
     &  STATUS='replace')
!      OPEN(FILE='Assym.dat',UNIT=62,
!     &  STATUS='replace')
!      OPEN(FILE='ExtCoef.dat',UNIT=63,
!     &  STATUS='replace')
      DO j = 1,nreff
      DO l=1,nsun
      WRITE(61,*) x(l),omegint(l,j)
!      WRITE(62,*) x(l),gint(l,1)
!      WRITE(63,*) x,(l),Qextint(l,1)
      ENDDO
      WRITE(61,*) ' ' 
!      WRITE(62,*) ' '
!      WRITE(63,*) ' '
      ENDDO


c     -------------------------------------------------------------
      END
