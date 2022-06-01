      DOUBLE PRECISION FUNCTION BRENT(XA,XB,XC,FA,FB,FC,ZFIRST,DTOL,
     1                                CONVGE,METHOD)
C  Copyright (C) 2022 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
C
C  WRITTEN 27-11-15 BY CR Le Sueur
C  THIS ROUTINE IMPLEMENTS THE VAN WIJNGAARDEN-DEKKER-BRENT METHOD OF
C  ROOT FINDING
C  IT IS A COMBINATION OF THE CODE WRITTEN IN NUMERICAL RECIPES (BUT
C  NOTE THE MISTAKE IN THE SPECIFICATION OF P IN THAT CODE), AND THE
C  ALGORITHM SET OUT IN THE WIKIPEDIA PAGE ON THE BRENT METHOD.
C
C  (XB,FB) IS THE CURRENT ITERATE, AND (XA,FA) IS THE CONTRAPOINT.
C  THESE POINTS ALWAYS BRACKET THE ROOT, WITH POINT B BEING CLOSER TO THE ROOT.
C  EITHER BISECTION OR SECANT IS USED TO OBTAIN THE NEXT ESTIMATE TO THE ROOT.
C
C  IF (XC,FC) IS DISTINCT FROM THE CURRENT ITERATE AND THE CONTRAPOINT,
C  INVERSE QUADRATIC INTERPOLATION IS USED INSTEAD OF THE SECANT METHOD.
C
      IMPLICIT NONE
      SAVE PREV_BIS,XD
      LOGICAL, INTENT(IN)::ZFIRST
      LOGICAL, INTENT(OUT)::CONVGE
      DOUBLE PRECISION, INTENT(IN)::DTOL
      DOUBLE PRECISION, INTENT(INOUT)::XA,XB,XC,FA,FB,FC
      DOUBLE PRECISION::XD,XE,P,Q,R,S,T,SM1,BMA,CMB,CME,DB,TEMP
      LOGICAL PREV_BIS
      CHARACTER(12),INTENT(OUT)::METHOD

C  ENSURE THAT (XB,FB) IS CLOSER TO X AXIS THAN (XA,FA)
      IF (ABS(FA).LT.ABS(FB)) THEN
        TEMP=FA
        FA=FB
        FB=TEMP
        TEMP=XA
        XA=XB
        XB=TEMP
      ENDIF

C  IF THIS IS THE FIRST TIME IN THIS LOOP, SET UP SOME EXTRA INFO
      IF (ZFIRST) THEN
        CONVGE=.FALSE.
        XE=XB
        XC=XA
        FC=FA
        PREV_BIS=.TRUE.
      ENDIF

C  SET UP SOME CONSTANTS (C.F. NUMERICAL RECIPES, P 253, WIKIPEDIA ON
C  BRENT METHOD)
      S=FB/FA
      SM1=S-1.D0
      BMA=XB-XA
      CMB=XC-XB
      CME=XC-XE
      IF (FA.NE.FB .AND. FB.NE.FC .AND. FA.NE.FC) THEN
C  USE INVERSE QUADRATIC INTERPOLATION
        R=FB/FC
        T=FA/FC
        P=S*(T*(R-T)*CMB-(1.D0-R)*BMA)
        Q=(R-1.D0)*SM1*(T-1.D0)
        METHOD='INV Q INTERP'
      ELSE
C  USE SECANT
        P=BMA*S
        Q=-SM1
        METHOD='SECANT      '
      ENDIF

C  NEW POINT IS B+DB
      DB=P/Q

      IF (PREV_BIS) THEN
        XE=XB
      ELSE
        XE=XD
      ENDIF
      CME=XC-XE
C  IF DB IS NOT BETWEEN 3(XA-XB)/4 AND ZERO, USE BISECTION
C  IF |DB| >= |(XC-XE)/2| OR |XE| < |DTOL| USE BISECTION
      IF ((3.D0*BMA/4.D0+DB)*BMA.LT.0.D0 .OR. BMA*DB.GT.0.D0 .OR.
     1    ABS(DB).GE.ABS(CME)/2.D0 .OR. ABS(XE).LT.ABS(DTOL)) THEN
        DB=-BMA/2.D0
        METHOD='BISECTION   '
        PREV_BIS=.TRUE.
      ELSE
        PREV_BIS=.FALSE.
      ENDIF

      BRENT=XB+DB
      XD=XC
      XC=XB
      FC=FB

      IF (ABS(DB).LT.ABS(DTOL)) CONVGE=.TRUE.

      RETURN
      END
