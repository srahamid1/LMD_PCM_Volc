PROGRAM testhist2
!-
!$Id: testhist2.f90 807 2009-11-23 12:11:55Z bellier $
!-
! This software is governed by the CeCILL license
! See IOIPSL/IOIPSL_License_CeCILL.txt
!---------------------------------------------------------------------
!- This program provide a an example of the basic usage of HIST.
!- Here the test the time sampling and averaging. Thus a long
!- time-series is produced and sampled in different ways.
!---------------------------------------------------------------------
  USE ioipsl
!
  IMPLICIT NONE
!
  INTEGER,PARAMETER :: iim=12,jjm=10,llm=2
!
  REAL :: champ1(iim,jjm), champ(iim,jjm), champ2(iim,jjm)
  REAL :: lon(iim,jjm),lat(iim,jjm), lev(llm)
  REAL :: x
!
  INTEGER :: i, j, l, id, id2, sig_id, hori_id, it
  INTEGER :: day=1, month=1, year=1997
  INTEGER :: itau=0, start, index(1)
!
  REAL :: julday, un_mois, un_an
  REAL :: deltat=86400, dt_wrt, dt_op, dt_wrt2, dt_op2
  CHARACTER(LEN=20) :: histname
!
  REAL :: pi=3.1415
!---------------------------------------------------------------------
!-
! 0.0 Choose a 360 days calendar
!-
  CALL ioconf_calendar('gregorian')
!-
! 1.0 Define a few variables we will need.
!     These are the coordinates the file name and the date.
!-
  DO i=1,iim
    DO j=1,jjm
      lon(i,j) = ((float(iim/2)+0.5)-float(i))*pi/float(iim/2) &
 &              *(-1.)*180./pi
      lat(i,j) = 180./pi * ASIN(((float(jjm/2)+0.5)-float(j)) &
 &              /float(jjm/2))
    ENDDO
  ENDDO
!-
  DO l=1,llm
    lev(l) = float(l)/llm
  ENDDO
!-
  histname = 'testhist2.nc'
!-
! 1.1 The chosen date is 15 Feb. 1997 as stated above.
!     It has to be transformed into julian days using
!     the calendar provided by IOIPSL.
!-
  CALL ymds2ju(year, month, day, 0.,julday)
  CALL ioget_calendar(un_an)
  un_mois = un_an/12.
  dt_wrt = un_mois*deltat
  dt_op = deltat
  dt_wrt2 = -1.
  dt_op2 = deltat
!-
! 2.0 Do all the declarations for hist. That is define the file,
!     the vertical coordinate and the variables in the file.
!     Monthly means are written to test this feature
!-
  CALL ioconf_modname ('testhist2 produced this file')
!-
  CALL histbeg (histname,iim,lon,jjm,lat, &
 &       1,iim,1,jjm,itau,julday,deltat,hori_id,id)
!-
  CALL histvert (id,"sigma","Sigma levels"," ",llm,lev,sig_id,pdirect="up")
!-
  CALL histdef (id,"champ1","Some field","m",iim,jjm,hori_id, &
 &  1,1,1,-99,32,"t_sum",dt_op,dt_wrt,standard_name='thickness')
!-
  CALL histdef (id,"champ2","summed field","m",iim,jjm,hori_id, &
 &  1,1,1,-99,32,"t_sum",dt_op,dt_wrt,standard_name='thickness')
!-
  CALL histend (id)
!-
! Open a second file which will do monthly means using the -1 notation.
!-
  histname = 'testhist2_bis.nc'
  CALL histbeg (histname,iim,lon,jjm,lat, &
 &       1,iim,1,jjm,itau,julday,deltat,hori_id,id2)
!-
  CALL histvert (id2,"sigma","Sigma levels"," ",llm,lev,sig_id,pdirect="up")
!-
  CALL histdef (id2,"champ1","Some field","m",iim,jjm,hori_id, &
 &  1,1,1,-99,32,"t_sum",dt_op2,dt_wrt2,standard_name='thickness')
!-
  CALL histdef (id2,"champ2","summed field","m",iim,jjm,hori_id, &
 &  1,1,1,-99,32,"t_sum",dt_op2,dt_wrt2,standard_name='thickness')
!-
  CALL histend (id2)
!-
! 2.1 The filed we are going to write are computes
!-
  CALL RANDOM_NUMBER(HARVEST=x)
  CALL RANDOM_NUMBER(champ)
  champ = champ*2*pi
  champ1 = sin(champ)
  champ2(:,:) = 1.
!-
! 3.0 Start the time steping and write the data as we go along.
!-
  start = 1
!-
  DO it=1,730
!---
!   3.1 In the 2D filed we will have a set of random numbers
!       which move through the map.
!---
    itau = itau+1
!---
!   3.2 Pass the data to HIST for operation and writing.
!---
    CALL histwrite (id, "champ1",itau,champ1,iim*jjm,index)
    CALL histwrite (id2,"champ1",itau,champ1,iim*jjm,index)
    CALL histwrite (id, "champ2",itau,champ2,iim*jjm,index)
    CALL histwrite (id2,"champ2",itau,champ2,iim*jjm,index)
!---
    champ1 = sin((it+1)*champ)
  ENDDO
!-
! 4.0 The HIST routines are ended and netCDF is closed
!-
  CALL histclo ()
!--------------------
END PROGRAM testhist2
