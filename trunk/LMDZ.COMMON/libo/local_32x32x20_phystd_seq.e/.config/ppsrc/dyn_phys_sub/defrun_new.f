












      SUBROUTINE defrun_new( tapedef, etatinit )
c
c-----------------------------------------------------------------------
c     Auteurs :   L. Fairhead , P. Le Van  .
c      Modif C. Hourdin F. Forget VERSION MARTIENNE
c
c
c  -------------------------------------------------------------------
c
c                    MODIF JUIN 2000 (zoom)
c       .........     Version  du 29/04/97       ..........
c
c   Nouveaux parametres nitergdiv,nitergrot,niterh,tetagdiv,tetagrot,
c   tetatemp   ajoutes  pour la dissipation   .
c
c   Autre parametre ajoute en fin de liste : ** fxyhypb ** 
c
c   Si fxyhypb = .TRUE. , choix de la fonction a derivee tangente hyperb.
c   Sinon , choix de fxynew  , a derivee sinusoidale  ..
c
c   ......  etatinit = . TRUE. si defrun_new  est appele dans NEWSTART
c   ETAT0_LMD  ou  LIMIT_LMD  pour l'initialisation de start.dat (dic) et
c   de limit.dat (dic)  ...........
c   Sinon  etatinit = . FALSE .
c
c   Donc etatinit = .F.  si on veut comparer les valeurs de  alphax ,
c   alphay,clon,clat, fxyhypb  lues sur  le fichier  start  avec
c   celles passees  par run.def ,  au debut du gcm, apres l'appel a 
c   lectba .  
c   Ces parametres definissant entre autres la grille et doivent etre
c   pareils et coherents , sinon il y aura  divergence du gcm .
c
c
c-----------------------------------------------------------------------
c   Declarations :
c   --------------
! to use  'getin'
      USE ioipsl_getincom
      use sponge_mod,only: callsponge,nsponge,mode_sponge,tetasponge
      use control_mod,only: nday, day_step, iperiod, anneeref,
     &                      iconser, dissip_period, iphysiq
      USE logic_mod, ONLY: hybrid,purmats,fxyhypb,ysinus,iflag_phys
      USE serre_mod, ONLY: clon,clat,grossismx,grossismy,dzoomx,dzoomy,
     .			alphax,alphay,taux,tauy
      IMPLICIT NONE

!-----------------------------------------------------------------------
!   INCLUDE 'dimensions.h'
!
!   dimensions.h contient les dimensions du modele
!   ndm est tel que iim=2**ndm
!-----------------------------------------------------------------------

      INTEGER iim,jjm,llm,ndm

      PARAMETER (iim= 32,jjm=32,llm=20,ndm=1)

!-----------------------------------------------------------------------
!
! $Header$
!
!
!  ATTENTION!!!!: ce fichier include est compatible format fixe/format libre
!                 veillez  n'utiliser que des ! pour les commentaires
!                 et  bien positionner les & des lignes de continuation
!                 (les placer en colonne 6 et en colonne 73)
!
!
!-----------------------------------------------------------------------
!   INCLUDE 'paramet.h'

      INTEGER  iip1,iip2,iip3,jjp1,llmp1,llmp2,llmm1
      INTEGER  kftd,ip1jm,ip1jmp1,ip1jmi1,ijp1llm
      INTEGER  ijmllm,mvar
      INTEGER jcfil,jcfllm

      PARAMETER( iip1= iim+1,iip2=iim+2,iip3=iim+3                       &
     &    ,jjp1=jjm+1-1/jjm)
      PARAMETER( llmp1 = llm+1,  llmp2 = llm+2, llmm1 = llm-1 )
      PARAMETER( kftd  = iim/2 -ndm )
      PARAMETER( ip1jm  = iip1*jjm,  ip1jmp1= iip1*jjp1 )
      PARAMETER( ip1jmi1= ip1jm - iip1 )
      PARAMETER( ijp1llm= ip1jmp1 * llm, ijmllm= ip1jm * llm )
      PARAMETER( mvar= ip1jmp1*( 2*llm+1) + ijmllm )
      PARAMETER( jcfil=jjm/2+5, jcfllm=jcfil*llm )

!-----------------------------------------------------------------------
!#include "control.h"
!
! $Id: comdissnew.h 1319 2010-02-23 21:29:54Z fairhead $
!
!
!  ATTENTION!!!!: ce fichier include est compatible format fixe/format libre
!                 veillez � n'utiliser que des ! pour les commentaires
!                 et � bien positionner les & des lignes de continuation 
!                 (les placer en colonne 6 et en colonne 73)
!
!-----------------------------------------------------------------------
! INCLUDE 'comdissnew.h'

      COMMON/comdissnew/ lstardis,nitergdiv,nitergrot,niterh,tetagdiv,  &
     &                   tetagrot,tetatemp,coefdis, vert_prof_dissip

      LOGICAL lstardis
      INTEGER nitergdiv, nitergrot, niterh

! For the Earth model:
      integer vert_prof_dissip ! vertical profile of horizontal dissipation
!     Allowed values:
!     0: rational fraction, function of pressure
!     1: tanh of altitude

      REAL     tetagdiv, tetagrot,  tetatemp, coefdis

!
! ... Les parametres de ce common comdissnew sont  lues par defrun_new 
!              sur le fichier  run.def    ....
!
!-----------------------------------------------------------------------
!
! $Header$
!
!
! gestion des impressions de sorties et de d�bogage
! lunout:    unit� du fichier dans lequel se font les sorties 
!                           (par defaut 6, la sortie standard)
! prt_level: niveau d'impression souhait� (0 = minimum)
!
      INTEGER lunout, prt_level
      COMMON /comprint/ lunout, prt_level
c
c   arguments:
c   ---------
      LOGICAL  etatinit ! should be .false. for a call from gcm.F
                        ! and .true. for a call from newstart.F
      INTEGER  tapedef  ! unit number to assign to 'run.def' file
c
c   local variables:
c   ---------------

      CHARACTER ch1*72,ch2*72,ch3*72,ch4*8 ! to store various strings
      integer tapeerr ! unit number for error message
      parameter (tapeerr=0)

c     REAL clonn,clatt,alphaxx,alphayy
c     LOGICAL  fxyhypbb
      INTEGER ierr
      REAL clonn,clatt,grossismxx,grossismyy
      REAL dzoomxx,dzoomyy,tauxx,tauyy,temp
      LOGICAL  fxyhypbb, ysinuss


c   initialisations:
c   ----------------
 
!      lunout=6

c-----------------------------------------------------------------------
c  Parametres de controle du run:
c-----------------------------------------------------------------------


!Initialisation des parametres "terrestres", qui ne concernent pas
!le modele martien et ne sont donc plus lues dans "run.def"

        anneeref=0
        ! Note: anneref is a common in 'control.h'

      OPEN(tapedef,file='run.def',status='old',form='formatted'
     .     ,iostat=ierr)
      CLOSE(tapedef) ! first call to getin will open the file

      !lunout: default unit for the text outputs
      lunout=6
      CALL getin('lunout', lunout)
      IF (lunout /= 5 .and. lunout /= 6) THEN
        OPEN(UNIT=lunout,FILE='lmdz.out',ACTION='write',
     &       STATUS='unknown',FORM='formatted')
      ENDIF

      IF(ierr.EQ.0) THEN ! if file run.def is found
        WRITE(lunout,*) "DEFRUN_NEW: reading file run.def"
        
        WRITE(lunout,*) ""
        WRITE(lunout,*) "Number of days to run:"
        nday=1 ! default value
        call getin("nday",nday)
        WRITE(lunout,*)" nday = ",nday

        WRITE(lunout,*) ""
        WRITE(lunout,*) "Number of dynamical steps per day:",
     & "(should be a multiple of iperiod)"
        day_step=960 ! default value
        call getin("day_step",day_step)
        WRITE(lunout,*)" day_step = ",day_step

        WRITE(lunout,*) ""
        WRITE(lunout,*) "periode pour le pas Matsuno (en pas)"
        iperiod=5 ! default value
        call getin("iperiod",iperiod)
        WRITE(lunout,*)" iperiod = ",iperiod

        WRITE(lunout,*) ""
        WRITE(lunout,*) "periode de sortie des variables de ",
     &  "controle (en pas)"
        iconser=120 ! default value
        call getin("iconser",iconser)
        WRITE(lunout,*)" iconser = ",iconser

        WRITE(lunout,*) ""
        WRITE(lunout,*) "periode de la dissipation (en pas)"
        dissip_period=5 ! default value
        call getin("idissip",dissip_period)
        ! if there is a "dissip_period" in run.def, it overrides "idissip"
        call getin("dissip_period",dissip_period)
        WRITE(lunout,*)" dissip_period = ",dissip_period

ccc  ....   P. Le Van , modif le 29/04/97 .pour la dissipation  ...
ccc
        WRITE(lunout,*) ""
        WRITE(lunout,*) "choix de l'operateur de dissipation ",
     & "(star ou  non star )"
        lstardis=.true. ! default value
        call getin("lstardis",lstardis)
        WRITE(lunout,*)" lstardis = ",lstardis

        WRITE(lunout,*) ""
        WRITE(lunout,*) "avec ou sans coordonnee hybrides"
        hybrid=.true. ! default value
        call getin("hybrid",hybrid)
        WRITE(lunout,*)" hybrid = ",hybrid

        WRITE(lunout,*) ""
        WRITE(lunout,*) "nombre d'iterations de l'operateur de ",
     & "dissipation   gradiv "
        nitergdiv=1 ! default value
        call getin("nitergdiv",nitergdiv)
        WRITE(lunout,*)" nitergdiv = ",nitergdiv

        WRITE(lunout,*) ""
        WRITE(lunout,*) "nombre d'iterations de l'operateur de ",
     & "dissipation  nxgradrot"
        nitergrot=2 ! default value
        call getin("nitergrot",nitergrot)
        WRITE(lunout,*)" nitergrot = ",nitergrot

        WRITE(lunout,*) ""
        WRITE(lunout,*) "nombre d'iterations de l'operateur de ",
     & "dissipation  divgrad"
        niterh=2 ! default value
        call getin("niterh",niterh)
        WRITE(lunout,*)" niterh = ",niterh

        WRITE(lunout,*) ""
        WRITE(lunout,*) "temps de dissipation des plus petites ",
     & "long.d ondes pour u,v (gradiv)"
        tetagdiv=4000. ! default value
        call getin("tetagdiv",tetagdiv)
        WRITE(lunout,*)" tetagdiv = ",tetagdiv

        WRITE(lunout,*) ""
        WRITE(lunout,*) "temps de dissipation des plus petites ",
     & "long.d ondes pour u,v(nxgradrot)"
        tetagrot=5000. ! default value
        call getin("tetagrot",tetagrot)
        WRITE(lunout,*)" tetagrot = ",tetagrot

        WRITE(lunout,*) ""
        WRITE(lunout,*) "temps de dissipation des plus petites ",
     & "long.d ondes pour  h ( divgrad)"
        tetatemp=5000. ! default value
        call getin("tetatemp",tetatemp)
        WRITE(lunout,*)" tetatemp = ",tetatemp

        WRITE(lunout,*) ""
        WRITE(lunout,*) "coefficient pour gamdissip"
        coefdis=0. ! default value
        call getin("coefdis",coefdis)
        WRITE(lunout,*)" coefdis = ",coefdis
c
c    ...............................................................

        WRITE(lunout,*) ""
        WRITE(lunout,*) "choix du shema d'integration temporelle ",
     & "(true==Matsuno ou false==Matsuno-leapfrog)"
        purmats=.false. ! default value
        call getin("purmats",purmats)
        WRITE(lunout,*)" purmats = ",purmats

        WRITE(lunout,*) ""
        WRITE(lunout,*) "avec ou sans physique"
!        physic=.true. ! default value
!        call getin("physic",physic)
!        WRITE(lunout,*)" physic = ",physic
        iflag_phys=1 ! default value
        call getin("iflag_phys",iflag_phys)
        WRITE(lunout,*)" iflag_phys = ",iflag_phys

        WRITE(lunout,*) ""
        WRITE(lunout,*) "periode de la physique (en pas)"
        iphysiq=20 ! default value
        call getin("iphysiq",iphysiq)
        WRITE(lunout,*)" iphysiq = ",iphysiq

!        WRITE(lunout,*) ""
!        WRITE(lunout,*) "choix d'une grille reguliere"
!        grireg=.true.
!        call getin("grireg",grireg)
!        WRITE(lunout,*)" grireg = ",grireg

ccc   .... P.Le Van, ajout le 03/01/96 pour l'ecriture phys ...
c
!        WRITE(lunout,*) ""
!        WRITE(lunout,*) "frequence (en pas) de l'ecriture ",
!     & "du fichier diagfi.nc"
!        ecritphy=240
!        call getin("ecritphy",ecritphy)
!        WRITE(lunout,*)" ecritphy = ",ecritphy

ccc  ....   P. Le Van , ajout  le 7/03/95 .pour le zoom ...
c     .........   (  modif  le 17/04/96 )   .........
c
        if (.not.etatinit ) then 

           clonn=63.
           call getin("clon",clonn)
           
           IF( ABS(clon - clonn).GE. 0.001 )  THEN
             PRINT *,' La valeur de clon passee par run.def est '
     *       ,'differente de celle lue sur le fichier start '
             STOP
           ENDIF
c
c
           clatt=0.
           call getin("clat",clatt)
  
           IF( ABS(clat - clatt).GE. 0.001 )  THEN
             PRINT *,' La valeur de clat passee par run.def est '
     *       ,'differente de celle lue sur le fichier start '
             STOP
           ENDIF

           grossismxx=1.0
           call getin("grossismx",grossismxx)

           if(grossismxx.eq.0) then  
             write(*,*)
             write(*,*)'ERREUR : dans run.def, grossismx =0'
             write(*,*)'Attention a ne pas utiliser une version de'
             write(*,*)'run.def avant le nouveau zoom LMDZ2.3 (06/2000)'
             write(*,*)'(Il faut ajouter grossismx,dzoomx,etc... a la'
             write(*,*)'place de alphax, alphay. cf. dyn3d). '
             write(*,*)
             stop
           end if

           IF( ABS(grossismx - grossismxx).GE. 0.001 )  THEN
             PRINT *,' La valeur de grossismx passee par run.def est '
     *       ,'differente de celle lue sur le fichier  start =',
     *        grossismx
             if (grossismx.eq.0) then
                  write(*,*) 'OK,Normal : c est un vieux start'
     *             , 'd avant le nouveau zoom LMDZ2.3 (06/2000)'
                 grossismx=grossismxx
             else
                   STOP
             endif
           ENDIF

           grossismyy=1.0
           call getin("grossismy",grossismyy)

           IF( ABS(grossismy - grossismyy).GE. 0.001 )  THEN
             PRINT *,' La valeur de grossismy passee par run.def est '
     *       ,'differente de celle lue sur le fichier  start =',
     *        grossismy
             if (grossismy.eq.0) then
                  write(*,*) 'OK,Normal : c est un vieux start'
     *             , 'd avant le nouveau zoom LMDZ2.3 (06/2000)'
                 grossismy=grossismyy
             else
                   STOP
             endif
           ENDIF


           IF( grossismx.LT.1. )  THEN
             PRINT *,' ***  ATTENTION !! grossismx < 1 .   *** '
             STOP
           ELSE
             alphax = 1. - 1./ grossismx
           ENDIF

           IF( grossismy.LT.1. )  THEN
             PRINT *,' ***  ATTENTION !! grossismy < 1 .   *** '
             STOP
           ELSE
             alphay = 1. - 1./ grossismy
           ENDIF

           PRINT *,' '
           PRINT *,' --> In defrun: alphax alphay  ',alphax,alphay
           PRINT *,' '
c
           fxyhypbb=.false.
           call getin("fxyhypbb",fxyhypbb)
  
           IF( .NOT.fxyhypb )  THEN
             IF( fxyhypbb )     THEN
                PRINT *,' ********  PBS DANS  DEFRUN  ******** '
                PRINT *,' *** fxyhypb lu sur le fichier start est F ',
     *          'alors  qu il est  T  sur  run.def  ***'
                STOP
             ENDIF
           ELSE
             IF( .NOT.fxyhypbb )   THEN
                PRINT *,' ********  PBS DANS  DEFRUN  ******** '
                PRINT *,' ***  fxyhypb lu sur le fichier start est T ',
     *         'alors  qu il est  F  sur  run.def  ****  '
                STOP
             ENDIF
           ENDIF
           dzoomxx=0.0
           call getin("dzoomx",dzoomxx)

           IF( fxyhypb )  THEN
              IF( ABS(dzoomx - dzoomxx).GE. 0.001 )  THEN
                PRINT *,' La valeur de dzoomx passee par run.def est '
     *          ,'differente de celle lue sur le fichier  start '
                STOP
              ENDIF
           ENDIF

           dzoomyy=0.0
           call getin("dzoomy",dzoomyy)

           IF( fxyhypb )  THEN
              IF( ABS(dzoomy - dzoomyy).GE. 0.001 )  THEN
                PRINT *,' La valeur de dzoomy passee par run.def est '
     *          ,'differente de celle lue sur le fichier  start '
                STOP
              ENDIF
           ENDIF

           tauxx=2.0
           call getin("taux",tauxx)

           tauyy=2.0
           call getin("tauy",tauyy)

           IF( fxyhypb )  THEN
              IF( ABS(taux - tauxx).GE. 0.001 )  THEN
                WRITE(6,*)' La valeur de taux passee par run.def est', 
     *             'differente de celle lue sur le fichier  start '
                CALL ABORT
              ENDIF

              IF( ABS(tauy - tauyy).GE. 0.001 )  THEN
                WRITE(6,*)' La valeur de tauy passee par run.def est',
     *          'differente de celle lue sur le fichier  start '
                CALL ABORT
              ENDIF
           ENDIF
  
        ELSE    ! Below, case when etainit=.true.

           WRITE(lunout,*) ""
           WRITE(lunout,*) "longitude en degres du centre du zoom"
           clon=63. ! default value
           call getin("clon",clon)
           WRITE(lunout,*)" clon = ",clon
           
c
           WRITE(lunout,*) ""
           WRITE(lunout,*) "latitude en degres du centre du zoom "
           clat=0. ! default value
           call getin("clat",clat)
           WRITE(lunout,*)" clat = ",clat

           WRITE(lunout,*) ""
           WRITE(lunout,*) "facteur de grossissement du zoom,",
     & " selon longitude"
           grossismx=1.0 ! default value
           call getin("grossismx",grossismx)
           WRITE(lunout,*)" grossismx = ",grossismx

           WRITE(lunout,*) ""
           WRITE(lunout,*) "facteur de grossissement du zoom ,",
     & " selon latitude"
           grossismy=1.0 ! default value
           call getin("grossismy",grossismy)
           WRITE(lunout,*)" grossismy = ",grossismy

           IF( grossismx.LT.1. )  THEN
            PRINT *,' ***  ATTENTION !! grossismx < 1 .   *** '
            STOP
           ELSE
             alphax = 1. - 1./ grossismx
           ENDIF

           IF( grossismy.LT.1. )  THEN
             PRINT *,' ***  ATTENTION !! grossismy < 1 .   *** '
             STOP
           ELSE
             alphay = 1. - 1./ grossismy
           ENDIF

           PRINT *,' Defrun  alphax alphay  ',alphax,alphay
c
           WRITE(lunout,*) ""
           WRITE(lunout,*) "Fonction  f(y)  hyperbolique  si = .true.",
     &  ", sinon  sinusoidale"
           fxyhypb=.false. ! default value
           call getin("fxyhypb",fxyhypb)
           WRITE(lunout,*)" fxyhypb = ",fxyhypb

           WRITE(lunout,*) ""
           WRITE(lunout,*) "extension en longitude de la zone du zoom", 
     & " (fraction de la zone totale)"
           dzoomx=0. ! default value
           call getin("dzoomx",dzoomx)
           WRITE(lunout,*)" dzoomx = ",dzoomx

           WRITE(lunout,*) ""
           WRITE(lunout,*) "extension en latitude de la zone du zoom", 
     & " (fraction de la zone totale)"
           dzoomy=0. ! default value
           call getin("dzoomy",dzoomy)
           WRITE(lunout,*)" dzoomy = ",dzoomy

           WRITE(lunout,*) ""
           WRITE(lunout,*) "raideur du zoom en  X"
           taux=2. ! default value
           call getin("taux",taux)
           WRITE(lunout,*)" taux = ",taux

           WRITE(lunout,*) ""
           WRITE(lunout,*) "raideur du zoom en  Y"
           tauy=2.0 ! default value
           call getin("tauy",tauy)
           WRITE(lunout,*)" tauy = ",tauy

        END IF ! of if (.not.etatinit )

        WRITE(lunout,*) ""
        WRITE(lunout,*) "Use a sponge layer?"
        callsponge=.true. ! default value
        call getin("callsponge",callsponge)
        WRITE(lunout,*)" callsponge = ",callsponge

        WRITE(lunout,*) ""
        WRITE(lunout,*) "Sponge: number of layers over which",
     &                    " sponge extends"
        nsponge=3 ! default value
        call getin("nsponge",nsponge)
        WRITE(lunout,*)" nsponge = ",nsponge

        WRITE(lunout,*)""
        WRITE(lunout,*)"Sponge mode: (forcing is towards ..."
        WRITE(lunout,*)"  over upper nsponge layers)"
        WRITE(lunout,*)"  0: (h=hmean,u=v=0)"
        WRITE(lunout,*)"  1: (h=hmean,u=umean,v=0)"
        WRITE(lunout,*)"  2: (h=hmean,u=umean,v=vmean)"
        mode_sponge=2 ! default value
        call getin("mode_sponge",mode_sponge)
        WRITE(lunout,*)" mode_sponge = ",mode_sponge

        WRITE(lunout,*) ""
        WRITE(lunout,*) "Sponge: characteristic time scale tetasponge"
        WRITE(lunout,*) "(seconds) at topmost layer (time scale then "
        WRITE(lunout,*) " doubles with decreasing layer index)."
        tetasponge=50000.0
        call getin("tetasponge",tetasponge)
        WRITE(lunout,*)" tetasponge = ",tetasponge


      WRITE(lunout,*) '-----------------------------------------------'
      WRITE(lunout,*) ' '
      WRITE(lunout,*) ' '
c

c       Unlike on Earth (cf LMDZ2.2) , always a regular grid on Mars :
        ysinus = .false. !Mars Mettre a jour


      WRITE(lunout,*) '-----------------------------------------------'
      WRITE(lunout,*) ' '
      WRITE(lunout,*) ' '
cc
      ELSE
        write(tapeerr,*) ' WHERE IS run.def ? WE NEED IT !!!!!!!!!!!!!!'
        stop
      ENDIF ! of IF(ierr.eq.0)

c     Test sur le zoom

      if((grossismx.eq.1).and.(grossismy.eq.1)) then  
c        Pas de zoom :
         write(lunout,*) 'No zoom ? -> fxyhypb set to False'
     &   ,'           (It runs better that way)'
         fxyhypb = .false.
      else     
c        Avec Zoom
         if (.not.fxyhypb) stop 'With zoom, fxyhypb should be set to T 
     &in run.def for this version... -> STOP ! '     
      end if
! of #ifndef CPP_PARA
      END
