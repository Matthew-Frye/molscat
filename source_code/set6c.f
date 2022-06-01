      SUBROUTINE SET6C(JSTATE,ATAU,NSTATE,EIN,IPRINT)
C  Copyright (C) 2022 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
      USE basis_data, ONLY: ELEVEL, EMAX, ISYM, JLEVEL, JMAX, JMIN,
     b                      JSTEP, NLEVEL, ROTI
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
C
C  CALCULATE ASYMMETRIC ROTOR ENERGY LEVELS AND WAVEFUNCTIONS
C  FROM ROTATIONAL CONSTANTS. WRITTEN BY JM Hutson, MARCH 1989.
C  MODIFIED TO HANDLE SPHERICAL TOP SYMMETRY, APRIL 1991.
C  MODIFIED TO USE WORKSPACE PROPERLY FOR VERSION 12, NOV 1993.
C  MODIFIED TO HANDLE 3-FOLD SYMMETRY, JAN 2021.
C
      LOGICAL EIN
      DIMENSION JSTATE(1),ATAU(1)
      COMMON /MEMORY/ MX,IXNEXT,NIPR,IDUMMY,X(1)
C  MODS 11 JUL 94 FOR V14 CMBASE
C  N.B IPAR WAS EQUIVALENCED TO J2MAX, NOW TO ISYM(1)
C  AUG 18 CMBASE REPLACED BY MODULE basis_data
C
      DATA TOL/1.D-8/

      IF (EIN .AND. IPRINT.GE.1) WRITE(6,601)
  601 FORMAT(/'  ASYMMETRIC TOP ENERGY LEVELS TAKEN FROM ELEVEL'/
     1       '  WILL OVERRIDE THOSE CALCULATED FROM ROTATIONAL ',
     2       'CONSTANTS')
      IF (ROTI(1).EQ.ROTI(3) .AND. ROTI(3).EQ.ROTI(5)) THEN
        IF (IPRINT.GE.1) WRITE(6,602) ROTI(1),ROTI(7),ROTI(10)
  602   FORMAT(/'  SPHERICAL ROTOR LEVELS CALCULATED FROM'/
     1         '  A = B = C =',F11.5/'  DJ',8X,'=',E11.3/
     2         '  DT',8X,'=',E11.3)
        IF (ABS(ROTI(10)).LT.1.D-8 .AND. IPRINT.GE.1) WRITE(6,603)
  603   FORMAT('  *** WARNING: IF ABS(DT) IS LESS THAN ABOUT 1.D-8,',
     1         ' THE PROGRAM MAY FAIL TO DISTINGUISH LEVELS OF',
     2         ' DIFFERENT SYMMETRY')
      ELSEIF (IPRINT.GE.1) THEN
        WRITE(6,604) ROTI(1),ROTI(3),ROTI(5),ROTI(7),ROTI(8),ROTI(9)
  604   FORMAT(/'  ASYMMETRIC ROTOR LEVELS CALCULATED FROM'/
     1          '  A   =',F10.5,8X,'B   =',F10.5,8X,'C   =',F10.5/
     2          '  DJ  =',E10.3,8X,'DJK =',E10.3,8X,'DK  =',E10.3//
     3          '  A, B AND C MUST CORRESPOND TO THE X, Y AND Z',
     4          ' COORDINATES USED TO DEFINE THE INTERACTION POTENTIAL')
      ENDIF
      IF (IPRINT.GE.1) WRITE(6,605) ISYM(1)
  605 FORMAT(/'  INPUT ENERGY LEVELS WILL BE INCLUDED ONLY IF THEY',
     1       ' MEET SELECTION CRITERIA SPECIFIED BITWISE BY ISYM =',I4)
C
C  NTAU IS SAFELY ABOVE ANYTHING WE MAY NEED FOR JSTATE
C
      NLVL=0
      ESAVE=-999.D0
      NSTATE=0
      NTAU=6*(JMAX+1)**2
      NORIG=NTAU
      IXSAVE=IXNEXT
      DO 450 J=JMIN,JMAX,JSTEP
        NVEC=NTAU
        NK=J+J+1
C
C  ASROT NEEDS SOMEWHERE TO PUT THE EIGENVALUES AND EIGENVECTORS
C  AND SOME WORKSPACE. USE THE TOP OF THE ATAU ARRAY.
C  ARGUMENTS OF ASROT ARE J,EVEC,HAM,EVAL,NK
C
        IC2=NVEC+1+NK*NK
        IC3=IC2+NK*NK
        IXNEXT=IC3+NK
        NUSED=0
        CALL CHKSTR(NUSED)
        CALL ASROT(J,ATAU(NVEC+1),ATAU(IC2),ATAU(IC3),NK)
        DO 440 IK=1,NK
C
C  CHECK LEVEL ENERGY AND PARITY TO SEE WHETHER WE REALLY WANT IT
C
          ELEV=ATAU(IC3+IK-1)
          IF (EMAX.GT.0.D0 .AND. ELEV.GT.EMAX) GOTO 430
          IPLEV=IPASYM(J,NK,ATAU(NVEC+1))
C
C  ISYM(1) IS INTERPRETED BITWISE: THE BITS ARE FLAGS AS FOLLOWS
C       0 - ODD  K EXCLUDED
C       1 - EVEN K EXCLUDED
C       2 - ODD  +/-K * (-1)**J EXCLUDED
C       3 - EVEN +/-K * (-1)**J EXCLUDED
C       4 - DEGENERACY = 1 EXCLUDED
C       5 - DEGENERACY = 2 EXCLUDED
C       6 - DEGENERACY = 3 EXCLUDED
C       7 - DEGENERACY > 3 EXCLUDED
C       8 - FUNCTIONS INCLUDING K.EQ.3N EXCLUDED
C       9 - FUNCTIONS INCLUDING K.NE.3N EXCLUDED
C
C  NOTE THAT THIS LOGIC WAS CHANGED IN AUGUST 1992,
C  IN A WAY THAT ALTERS THE INPUT VALUE OF ISYM REQUIRED,
C  FOLLOWING BETA TESTING OF VERSION 11
C
          IF (ISYM(1).LE.0) GOTO 410
C
C  FIND DEGENERACY
C
          IDEG=0
          DO 400 KK=1,NK
            IF (ABS(ATAU(IC3+KK-1)-ELEV).LT.TOL) IDEG=IDEG+1
  400     CONTINUE
C
          JPAR=ISYM(1)
C
          IP=MOD(JPAR,2)
          JPAR=JPAR/2
          IF (IP.EQ.1 .AND. IPLEV.GE.2) GOTO 430
C
          IP=MOD(JPAR,2)
          JPAR=JPAR/2
          IF (IP.EQ.1 .AND. IPLEV.LE.1) GOTO 430
C
          IP=MOD(JPAR,2)
          JPAR=JPAR/2
          IF (IP.EQ.1 .AND. MOD(IPLEV+J,2).EQ.1) GOTO 430
C
          IP=MOD(JPAR,2)
          JPAR=JPAR/2
          IF (IP.EQ.1 .AND. MOD(IPLEV+J,2).EQ.0) GOTO 430
C
          IP=MOD(JPAR,2)
          JPAR=JPAR/2
          IF (IP.EQ.1 .AND. IDEG.EQ.1) GOTO 430
C
          IP=MOD(JPAR,2)
          JPAR=JPAR/2
          IF (IP.EQ.1 .AND. IDEG.EQ.2) GOTO 430
C
          IP=MOD(JPAR,2)
          JPAR=JPAR/2
          IF (IP.EQ.1 .AND. IDEG.EQ.3) GOTO 430
C
          IP=MOD(JPAR,2)
          JPAR=JPAR/2
          IF (IP.EQ.1 .AND. IDEG.GT.3) GOTO 430
C
C         CAPABILITY ADDED BY JMH, JAN 2021 TO HANDLE 3-FOLD SYMMETRY
C         BIT 8, ADD 256: EXCLUDE FUNCTIONS WITH K A MULTIPLE OF 3
C         BIT 9, ADD 512: EXCLUDE FUNCTIONS WITH K NOT A MULTIPLE OF 3
C
          IP=MOD(JPAR,2)
          JPAR=JPAR/2
C         EXCLUDE IF THERE ARE COMPONENTS WITH K A MULTIPLE OF 3
          DO 406 KBAS=1,NK
          IF (IP.EQ.1 .AND. MOD(KBAS-1-J,3).EQ.0
     1         .AND. ABS(ATAU(NVEC+KBAS)).GT.1.D-8) GOTO 430
  406     CONTINUE

          IP=MOD(JPAR,2)
          JPAR=JPAR/2
C         EXCLUDE IF THERE ARE COMPONENTS WITH K NOT A MULTIPLE OF 3
          DO 408 KBAS=1,NK
          IF (IP.EQ.1 .AND. MOD(KBAS-1-J,3).NE.0
     1        .AND. ABS(ATAU(NVEC+KBAS)).GT.1.D-8) GOTO 430
  408     CONTINUE

  410     NSTATE=NSTATE+1
          IF (NLEVEL.GT.0 .AND. NSTATE.GT.NLEVEL) GOTO 430
C
C  ARRIVE HERE IF WE DO: STORE JSTATE AND TAU IN TEMPORARY LOCATIONS
C
          PREV=ESAVE
          ESAVE=ELEV
C  IF TWO LEVELS OF THE SAME J ARE DEGENERATE, WE NEED TO CHOOSE WHETHER
C  TO TREAT THEM AS ONE LEVEL OR TWO. THE CHOICE MADE HERE IS TO TREAT
C  THEM AS ONE LEVEL FOR A SPHERICAL TOP WITH A (ROTI(1)) = C (ROTI(5))
C  BUT AS TWO IF THE Z AXIS IS DISTINCT (SYMMETRIC OR NEAR-SYMMETRIC
C  TOP, OR A NEAR-DEGENERACY FOR HIGH K FOR A LESS SYMMETRIC TOP.
C  JMH CHANGED ROTI(3) TO ROTI(5) TO DO THIS, JANUARY 2021
          IF (ABS(ESAVE-PREV).GT.TOL .OR. ROTI(1).NE.ROTI(5)) THEN
            NLVL=NLVL+1
            JLEVEL(2*NLVL-1)=J
            JLEVEL(2*NLVL)=IK-1-J
            IF (.NOT.EIN) ELEVEL(NLVL)=ELEV
          ENDIF
C
          JSTATE(6*NSTATE-5)=J
          JSTATE(6*NSTATE-4)=IK-1-J
          JSTATE(6*NSTATE-3)=IPLEV
          JSTATE(6*NSTATE-2)=NTAU
          JSTATE(6*NSTATE-1)=NK
          JSTATE(6*NSTATE  )=NLVL
C
C  NTAU KEEPS TRACK OF WHERE WE ARE PUTTING THE COEFFICIENTS,
C  AND NVEC KEEPS TRACK OF WHERE THEY ARE COMING FROM.
C  NTAU IS NEVER LESS THAN NVEC.
C
          DO 420 I=1,NK
            ATAU(NTAU+I)=ATAU(NVEC+I)
  420     CONTINUE
          NTAU=NTAU+NK
  430     NVEC=NVEC+NK
  440   CONTINUE
  450 CONTINUE
C
C  COPY ATAU INTO THE RIGHT PLACE
C
      IF (NLEVEL.GT.0) NSTATE=MIN(NSTATE,NLEVEL)
      IF (NLEVEL.EQ.0) NLEVEL=NLVL
      NBASE=6*NSTATE
      NSHIFT=NORIG-NBASE
      DO 460 I=NORIG+1,NTAU
  460   ATAU(I-NSHIFT)=ATAU(I)
      NTAU=NTAU-NSHIFT
C
C  COPY JSTATE INTO WORKSPACE ABOVE ATAU AND REARRANGE IT,
C  REMEMBERING TO MODIFY THE POINTER TO ATAU.
C
      NBASE=2*NTAU
      I=0
      DO 470 NL=1,NSTATE
      DO 470 IQ=1,6
        I=I+1
        IF (IQ.EQ.4) JSTATE(I)=JSTATE(I)-NSHIFT
        JSTATE(NBASE+NL+NSTATE*(IQ-1))=JSTATE(I)
  470 CONTINUE
C
C  THEN COPY IT BACK TO WHERE IT BELONGS
C
      DO 480 I=1,6*NSTATE
  480   JSTATE(I)=JSTATE(NBASE+I)
      IXNEXT=IXSAVE+NTAU
      RETURN
      END
