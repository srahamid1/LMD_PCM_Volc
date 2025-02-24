      subroutine stelang(kgrid,psilon,pcolon,psilat,pcolat,
     &                ptim1,ptim2,ptim3,pmu0,pfract, pflat)
      IMPLICIT NONE

C
C**** *LW*   - ORGANIZES THE LONGWAVE CALCULATIONS
C
C     PURPOSE.
C     --------
C          CALCULATES THE STELLAR ANGLE FOR ALL THE POINTS OF THE GRID
C
C**   INTERFACE.
C     ----------
C      SUBROUTINE STELANG ( KGRID )
C
C        EXPLICIT ARGUMENTS :
C        --------------------
C     ==== INPUTS  ===
C
C PSILON(KGRID)   : SINUS OF THE LONGITUDE
C PCOLON(KGRID)   : COSINUS OF THE LONGITUDE
C PSILAT(KGRID)   : SINUS OF THE LATITUDE
C PCOLAT(KGRID)   : COSINUS OF THE LATITUDE
C PTIM1           : SIN(DECLI)
C PTIM2           : COS(DECLI)*COS(TIME)
C PTIM3           : SIN(DECLI)*SIN(TIME)
C
C     ==== OUTPUTS ===
C
C PMU0 (KGRID)    : SOLAR ANGLE
C PFRACT(KGRID)   : DAY FRACTION OF THE TIME INTERVAL
C
C        IMPLICIT ARGUMENTS :   NONE
C        --------------------
C
C     METHOD.
C     -------
C
C     EXTERNALS.
C     ----------
C
C         NONE
C
C     REFERENCE.
C     ----------
C
C         RADIATIVE PROCESSES IN METEOROLOGIE AND CLIMATOLOGIE
C         PALTRIDGE AND PLATT
C
C     AUTHOR.
C     -------
C        FREDERIC HOURDIN
C
C     MODIFICATIONS.
C     --------------
C        ORIGINAL :90-01-14
C                  92-02-14 CALCULATIONS DONE THE ENTIER GRID (J.Polcher)
C-----------------------------------------------------------------------
C
C     ------------------------------------------------------------------

C-----------------------------------------------------------------------
C
C*      0.1   ARGUMENTS
C             ---------
C
      INTEGER,INTENT(IN) :: kgrid
      REAL,INTENT(IN) :: ptim1,ptim2,ptim3, pflat
      REAL,INTENT(IN) :: psilon(kgrid),pcolon(kgrid)
      REAL,INTENT(IN) :: psilat(kgrid), pcolat(kgrid)
      REAL,INTENT(OUT) :: pmu0(kgrid),pfract(kgrid)
C
      INTEGER jl
      REAL ztim1,ztim2,ztim3, rap
C------------------------------------------------------------------------
C------------------------------------------------------------------------
C------------------------------------------------------------------------
C
C------------------------------------------------------------------------
C
C*     1.     INITIALISATION
C             --------------
C
c----- SG: geometry adapted to a flattened planet (Feb2014)

      rap = 1./((1.-pflat)**2)

 100  CONTINUE
C
      DO jl=1,kgrid
        pmu0(jl)=0.
        pfract(jl)=0.
      ENDDO
C
C*     1.1     COMPUTATION OF THE SOLAR ANGLE
C              ------------------------------
C
      DO jl=1,kgrid
        ztim1=psilat(jl)*ptim1*rap
        ztim2=pcolat(jl)*ptim2
        ztim3=pcolat(jl)*ptim3
        pmu0(jl)=ztim1+ztim2*pcolon(jl)+ztim3*psilon(jl)
	pmu0(jl)=pmu0(jl)/SQRT(pcolat(jl)**2+(rap**2)*(psilat(jl)**2))

      ENDDO
C
C*     1.2      DISTINCTION BETWEEN DAY AND NIGHT
C               ---------------------------------
C
      DO jl=1,kgrid
        IF (pmu0(jl).gt.0.) THEN
          pfract(jl)=1.
c       pmu0(jl)=sqrt(1224.*pmu0(jl)*pmu0(jl)+1.)/35.
      ELSE
c       pmu0(jl)=0.
        pfract(jl)=0.
        ENDIF
      ENDDO
C
      RETURN
      END

