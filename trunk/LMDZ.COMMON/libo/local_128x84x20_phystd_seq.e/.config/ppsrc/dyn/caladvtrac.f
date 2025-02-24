












!
! $Id: caladvtrac.F 1446 2010-10-22 09:27:25Z emillour $
!
c
c
            SUBROUTINE caladvtrac(q,pbaru,pbarv ,
     *                   p ,masse, dq ,  teta,
     *                   flxw, pk)
c
      USE infotrac, ONLY : nqtot
      USE control_mod, ONLY : iapp_tracvl,planet_type,
     &                        force_conserv_tracer
      USE comconst_mod, ONLY: dtvr
      USE planetary_operations, ONLY: planetary_tracer_amount_from_mass
      IMPLICIT NONE
c
c     Auteurs:   F.Hourdin , P.Le Van, F.Forget, F.Codron  
c
c     F.Codron (10/99) : ajout humidite specifique pour eau vapeur
c=======================================================================
c
c       Shema de  Van Leer
c
c=======================================================================


!-----------------------------------------------------------------------
!   INCLUDE 'dimensions.h'
!
!   dimensions.h contient les dimensions du modele
!   ndm est tel que iim=2**ndm
!-----------------------------------------------------------------------

      INTEGER iim,jjm,llm,ndm

      PARAMETER (iim= 128,jjm=84,llm=20,ndm=1)

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

c   Arguments:
c   ----------
      REAL pbaru( ip1jmp1,llm ),pbarv( ip1jm,llm),masse(ip1jmp1,llm)
      REAL p( ip1jmp1,llmp1),q( ip1jmp1,llm,nqtot)
      real :: dq(ip1jmp1,llm,nqtot)
      REAL teta( ip1jmp1,llm),pk( ip1jmp1,llm)
      REAL               :: flxw(ip1jmp1,llm)

c  ..................................................................
c
c  .. dq n'est utilise et dimensionne que pour l'eau  vapeur et liqu.
c
c  ..................................................................
c
c   Local:
c   ------

      EXTERNAL  advtrac,minmaxq, qminimum
      INTEGER ij,l, iq, iapptrac
      REAL finmasse(ip1jmp1,llm), dtvrtrac
      REAL :: totaltracer_old(nqtot),totaltracer_new(nqtot)
      REAL :: ratio

! Ehouarn : try to fix tracer conservation issues:
      if (force_conserv_tracer) then
        do iq=1,nqtot
          call planetary_tracer_amount_from_mass(masse,q(:,:,iq),
     &                                totaltracer_old(iq))
        enddo
      endif
cc
c
! Earth-specific stuff for the first 2 tracers (water)
      if (planet_type.eq."earth") then
C initialisation
! CRisi: il faut gérer tous les traceurs si on veut pouvoir faire des
! isotopes
!        dq(:,:,1:2)=q(:,:,1:2)
        dq(:,:,1:nqtot)=q(:,:,1:nqtot)
       
c  test des valeurs minmax
cc        CALL minmaxq(q(1,1,1),1.e33,-1.e33,'Eau vapeur (a) ')
cc        CALL minmaxq(q(1,1,2),1.e33,-1.e33,'Eau liquide(a) ')
      endif ! of if (planet_type.eq."earth")
c   advection

        CALL advtrac( pbaru,pbarv, 
     *       p,  masse,q,iapptrac, teta,
     .       flxw, pk)

c

      IF( iapptrac.EQ.iapp_tracvl ) THEN
        if (planet_type.eq."earth") then
! Earth-specific treatment for the first 2 tracers (water)
c
cc          CALL minmaxq(q(1,1,1),1.e33,-1.e33,'Eau vapeur     ')
cc          CALL minmaxq(q(1,1,2),1.e33,-1.e33,'Eau liquide    ')

cc     ....  Calcul  de deltap  qu'on stocke dans finmasse   ...
c
          DO l = 1, llm
           DO ij = 1, ip1jmp1
             finmasse(ij,l) =  p(ij,l) - p(ij,l+1) 
           ENDDO
          ENDDO
          
          !write(*,*) 'caladvtrac 87'
          CALL qminimum( q, nqtot, finmasse )
          !write(*,*) 'caladvtrac 89'

          CALL SCOPY   ( ip1jmp1*llm, masse, 1, finmasse,       1 )
          CALL filtreg ( finmasse ,  jjp1,  llm, -2, 2, .TRUE., 1 )
c
c   *****  Calcul de dq pour l'eau , pour le passer a la physique ******
c   ********************************************************************
c
          dtvrtrac = iapp_tracvl * dtvr
c
           DO iq = 1 , nqtot
            DO l = 1 , llm
             DO ij = 1,ip1jmp1
             dq(ij,l,iq) = ( q(ij,l,iq) - dq(ij,l,iq) ) * finmasse(ij,l)
     *                               /  dtvrtrac
             ENDDO
            ENDDO
           ENDDO
c
        endif ! of if (planet_type.eq."earth")
        
        ! Ehouarn : try to fix tracer conservation after tracer advection
        if (force_conserv_tracer) then
          do iq=1,nqtot
            call planetary_tracer_amount_from_mass(masse,q(:,:,iq),
     &                                  totaltracer_new(iq))
            ratio=totaltracer_old(iq)/totaltracer_new(iq)
            q(:,:,iq)=q(:,:,iq)*ratio
          enddo
        endif !of if (force_conserv_tracer)
        
      ELSE ! i.e. iapptrac.NE.iapp_tracvl
        if (planet_type.eq."earth") then
! Earth-specific treatment for the first 2 tracers (water)
          dq(:,:,1:nqtot)=0.
        endif ! of if (planet_type.eq."earth")
      ENDIF ! of IF( iapptrac.EQ.iapp_tracvl )

      END


