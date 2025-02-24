PROGRAM testopp
!-
!$Id: testopp.f90 846 2009-12-10 16:26:58Z bellier $
!-
! This software is governed by the CeCILL license
! See IOIPSL/IOIPSL_License_CeCILL.txt
!---------------------------------------------------------------------
!- This program allows to test the syntaxic analyzer.
!---------------------------------------------------------------------
   USE mathelp
!-
   IMPLICIT NONE
!-
   INTEGER,PARAMETER :: nbopp_max=10
   REAL,PARAMETER :: missing_val=1.e20
!- Please list here all the operation you wish to test.
!- Do not forget to change the value of nbtest.
   INTEGER,PARAMETER :: nbtest=3
   CHARACTER(LEN=30),DIMENSION(nbtest) :: test_opp = &
  &  (/ "t_max(gather(x*2))            ", &
  &     "(inst(sqrt(max(X,0)*2.0)))    ", &
  &     "(once)                        " /)
!-
   CHARACTER(LEN=80) :: opp
   CHARACTER(LEN=50) :: ex_topps = 'ave, inst, t_min, t_max, once'
   REAL,DIMENSION(nbopp_max) :: tmp_scal
   CHARACTER(LEN=7),DIMENSION(nbopp_max) :: tmp_sopp
   CHARACTER(LEN=7) :: tmp_topp
   INTEGER :: nbopp,i,io
!---------------------------------------------------------------------
   DO io=1,nbtest
     opp = test_opp(io)
     WRITE(*,*) '-------------------------'
     WRITE(*,*) ' '
     WRITE(*,*) 'String to be analyzed : ',TRIM(opp)
     CALL buildop (TRIM(opp),ex_topps,tmp_topp,missing_val, &
 &                 tmp_sopp,tmp_scal,nbopp)
!-
     WRITE(*,*) 'Time operation   : ',TRIM(tmp_topp)
     WRITE(*,*) 'Other operations : ',nbopp
     DO i=1,nbopp
       WRITE(*,*) ' ',i,' opp : ',tmp_sopp(i),' scalar : ',tmp_scal(i)
     ENDDO
   ENDDO
!------------------
END PROGRAM testopp
