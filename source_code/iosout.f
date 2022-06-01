      SUBROUTINE IOSOUT(ENERGY,QL,QLOLD,NVC,ITYPE,ATAU,LM,IXQL,
     1                  LMAX,NIXQL,NQL,JTSTEP)
C  Copyright (C) 2022 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
      USE sizes, ONLY: MXJLVL
      USE angles, ONLY: ICNSYM, IHOMO
      USE basis_data, ONLY: IDENT, JLEVEL, NLEVEL
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
C
C>>SG MODIFIED MAY 92 - ITYPE=3 / ADD JTSTEP TO PARAMETER LIST.
C>>SG MODIFIED FEB 92
C>>SG    TO CORRECT APPARENT COMPILER BUG, IN FORMATS 615,616
C>>SG    TO ALLOW FOR OUTPUT OF NOUT.LT.NVC VIB LEVELS IF SOME CLOSED
C
C  AUG 86 IXQLF ADD LM,LMAX ARGUMENTS
C  *** TO CONTROL OPTIONAL 'DEBUGGING' OUTPUT ***
      LOGICAL PRNT
C  ALLOW FOR MXSIG OUTPUT LEVELS
      PARAMETER (MXSIG=200)
      CHARACTER(1) S(MXSIG),SPACE,STAR
      CHARACTER(4) LCODE(3),LQLT,LQLS
      DIMENSION QL(NVC,NVC,NQL),QLOLD(NVC,NVC)
      DIMENSION LM(3,LMAX),IXQL(NIXQL,NQL)
      DIMENSION ATAU(2)
C  STORAGE RESERVED FOR MAXIMUM OF MXSIG LEVELS
      DIMENSION SIG(MXSIG),SIG3(MXSIG),INDLEV(MXSIG)
C
C  ALTERED TO USE ARRAY SIZES FROM MODULE sizes ON 23-06-17 BY CRLS
C  COMMON BLOCKS TO COMMUNICATE WITH IOSBIN(BASIS SET) ROUTINES
      COMMON /IOUTCM/ JTMAX,LEVV(MXJLVL)
C  COMMON TO GET SYMMETRY INFORMATION (IHOMO1,IHOMO2) FOR ITYPE=3
C  CHANGED TO USE ANGLES MODULE ON 16-08-2018
C     COMMON /ANGLES/ COSANG(MXANG),FACTOR,IHOMO,ICNSYM,IHOMO2,ICNSY2
C
      DATA IZERO/0/, ZTOL/1.D-8/
      DATA SPACE/' '/, STAR/'*'/
      DATA LCODE/'    ','REAL','IMAG'/, LQLT/' QLT'/, LQLS/' QLS'/
      DATA PRNT/.FALSE./
C
C  STATEMENT FUNCTION FOR NORMALIZATION XNORM . . .
      XNORM(EPSI)=1.D0/(1.D0+ABS(EPSI))
      FUNC(I)=2.D0*DBLE(I)+1.D0
C
      WRITE(6,601) ENERGY
  601 FORMAT('  STATE-TO-STATE CROSS SECTIONS (IN ANG**2) FOR KINETIC',
     &       ' ENERGY =',F12.4,' CM-1.'//
     &       '  PROCESSED BY IOSOUT (FEB 92).')
C
      XJSTEP=JTSTEP
      IF (JTSTEP.GT.1) WRITE(6,690) JTSTEP
  690 FORMAT(/'  CROSS SECTIONS (BUT NOT QL) MULTIPLIED BY JTSTEP =',I3)
      IF (ITYPE.EQ.5 .OR. ITYPE.EQ.6) GOTO 5000

      IF (ITYPE.EQ.3) GOTO 3000
C
C  CODE BELOW IS ITYPE=1,2 FROM VERSION 3.  IT SHOULD STILL WORK
C  SINCE ALL QL (NOW QLT) ARE IN ORDER.
      WRITE(6,610) NVC,(LEVV(I),I=1,NVC)
  610 FORMAT(/'  NO. OF VIBRATIONAL LEVELS =',I4,'.  LEVELS ARE'/
     &       (' ',13I10))
      IF (JTMAX.LT.MXSIG) GOTO 2200
      WRITE(6,692) JTMAX,MXSIG
  692 FORMAT(/'  JTMAX =',I6,'  REDUCED BECAUSE OF MXSIG =',I5)
      JTMAX=MXSIG-1
 2200 WRITE(6,602) JTMAX
  602 FORMAT(/'  MAXIMUM J-VALUE REQUESTED IS',I4)
C  >>SG ------------------------- >> CODE BELOW ADDED FEB 92
C  DETERMINE IF ALL CHANNELS ARE OPEN.  SINCE WE DON'T HAVE ACCESS
C  TO NOPEN HERE, SIMPLY FIND THE HIGHEST 'CHANNEL' FOR WHICH WE
C  HAVE NONZERO QL() OR QLOLD()
      NOUT=0
      DO 2300 IV=1,NVC

C  FIRST CHECK QLOLD
        DO 2301 IVP=1,NVC
          IF (QLOLD(IV,IVP).NE.0.D0) GOTO 2390

 2301   CONTINUE

C  THEN CHECK QL()
        DO 2302 IVP=1,NVC
        DO 2302 IL=1,NQL
          IF (QL(IV,IVP,IL).NE.0.D0) GOTO 2390

 2302   CONTINUE
        GOTO 2300

 2390   NOUT=IV
 2300 CONTINUE

      IF (NOUT.NE.NVC) WRITE(6,620) NOUT
  620 FORMAT(/'  IOSOUT (FEB 92).  ALL QL,QLOLD ZERO FOR SOME CHANNELS',
     1       ', PRESUMABLY CLOSED ENERGETICALLY.'/
     2       /'                    OUTPUT LIMITED TO NOUT =',I3)
C
C<<SG  -<< END OF ADDITIONAL CODE FEB 92.  NB NVC CHANGED TO NOUT BELOW
      IV=1
      WRITE(6,606)(IV,IVP,QLOLD(IV,IVP),IVP=1,NOUT)
  606 FORMAT(/'   QLOLD(0) ',4(2X,I3,' TO',I3,' =',1PE12.4) /
     &                  (12X,4(2X,I3,' TO',I3,' =',1PE12.4)))
      IF (NOUT.LE.1) GOTO 2001

      DO 2101 IV=2,NOUT
 2101   WRITE(6,616) (IV,IVP,QLOLD(IV,IVP),IVP=1,NOUT)
  616   FORMAT(12X,4(2X,I3,' TO',I3,' =',1PE12.4)/
     1         (12X,4(2X,I3,' TO',I3,' =',1PE12.4)))

 2001 DO 1300 L=1,NQL
        LM1=L-1
        IV=1
        WRITE(6,605) LM1,(IV,IVP,QL(IV,IVP,L),IVP=1,NOUT)
  605   FORMAT(/'   Q(',I3,' )  ',4(2X,I3,' TO',I3,' =',1PE12.4) /
     &                      (12X,4(2X,I3,' TO',I3,' =',1PE12.4)))
        IF (NOUT.LE.1) GOTO 1300

        DO 1301 IV=2,NOUT
 1301     WRITE(6,616) (IV,IVP,QL(IV,IVP,L),IVP=1,NOUT)
 1300 CONTINUE
C
      DO 4000 IV=1,NOUT
      DO 4000 IVP=1,NOUT
        WRITE(6,640) IV,IVP
  640   FORMAT(/'  ***** ***** ***** BELOW FOR VIB LEVEL',I3,' TO',I3)
        IMSG=0
        DO 1000 JI=IZERO,JTMAX
          WRITE(6,603) JI
  603     FORMAT(/'  FOR INITIAL LEVEL J =',I4,'  NON-ZERO CROSS ',
     1           'SECTIONS (ANG**2) TO FINAL LEVELS ARE')
          NONZRO=0
          DO 1100 JF=IZERO,JTMAX
            IIF=JF+1
            S(IIF)=SPACE
            LLOW=ABS(JF-JI)
            LTOP=JF+JI
            IF (LTOP.LE.LMAX-1) GOTO 1101

            S(IIF)=STAR
            IMSG=1
            LTOP=LMAX-1
 1101       SIG(IIF)=0.D0
            IF (LLOW.GT.LTOP) GOTO 1100

            DO 1200 L=LLOW,LTOP
              TJ=THREEJ(JI,L,JF)
 1200         SIG(IIF)=SIG(IIF)+TJ*TJ*QL(IV,IVP,L+1)
            SIG(IIF)=FUNC(JF)*SIG(IIF) * XJSTEP
            IF (SIG(IIF).NE.0.D0) THEN
              NONZRO=NONZRO+1
              INDLEV(NONZRO)=IIF
            ENDIF
 1100     CONTINUE
 1000     WRITE(6,604) (INDLEV(IL)-1,SIG(INDLEV(IL)),S(INDLEV(IL)),
     1                  IL=1,NONZRO)
  604     FORMAT(6(4X,I3,1PE12.4,A1))
        IF (IMSG.GT.0) WRITE(6,699)
  699   FORMAT(/'  ***** NOTE.  FOR CROSS SECTIONS MARKED WITH A ',
     1          'STAR, SOME CONTRIBUTING Q(L) ARE NOT AVAILABLE.')
 4000 CONTINUE
      RETURN
C
C>>SG ITYPE=3 CODE ADDED MAY 92.  ASSUMES NVC=1 (ONE VIB CHANNEL)
 3000 WRITE(6,630)
  630 FORMAT(///'  ACCUMULATED Q(L1,L2,L) ARE AS FOLLOWS')
      WRITE(6,651) LCODE(1),LQLS,LM(1,1),LM(2,1),LM(3,1),QLOLD(1,1)
      DO 3001 L=1,NQL
 3001 WRITE(6,651) LCODE(1),LQLT,LM(1,L),LM(2,L),LM(3,L),QL(1,1,L)
      IF (LM(1,1).EQ.0 .AND. LM(2,1).EQ.0 .AND. LM(3,1).EQ.0) GOTO 3002
      WRITE(6,639)
  639 FORMAT(' IOSOUT *** ERROR. L1=L2=L=0 IS NOT FIRST SYMMETRY IN LM')
 3002 L1MAX=0
      L2MAX=0
      DO 3003 IL=1,LMAX
        L1MAX=MAX(L1MAX,LM(1,IL))
 3003   L2MAX=MAX(L2MAX,LM(2,IL))
      NL2=L2MAX/ICNSYM+1
      IX=0
      DO 3100 L1=0,L1MAX,IHOMO
        LTOP=L2MAX
        IF (IDENT.GT.0) LTOP=L1
      DO 3100 L2=0,LTOP,ICNSYM
        IX=IX+1
        NSIG=IX
        IF (NSIG.LE.MXSIG) GOTO 3109
        WRITE(6,638) MXSIG
  638   FORMAT(' *** ERROR.  MXSIG (DIMENSION OF SIG3) EXCEEDED',I5)
        STOP
 3109   SIG3(IX)=0.
        LLO=ABS(L1-L2)
        LHI=L1+L2
        DO 3102 LL=LLO,LHI,2
C  SEARCH LM(,IL) FOR L1,L2,LL
          DO 3101 IL=1,LMAX
            IF (L1.NE.LM(1,IL) .OR. L2.NE.LM(2,IL) .OR. LL.NE.LM(3,IL))
     1        GOTO 3101
            SIG3(IX)=SIG3(IX)+QL(1,1,IL) * XJSTEP
            GOTO 3102
 3101     CONTINUE
          WRITE(6,631) L1,L2,LL
  631     FORMAT(' IOSOUT *** ERROR.  REQUIRED QL(',3I3,') NOT FOUND.')
 3102   CONTINUE
 3100   WRITE(6,632) L1,L2,SIG3(IX)
  632   FORMAT(' SIG(  0  0 ->',2I3,') =',F10.3,' ANG**2')
C
      IF (NLEVEL.LE.0) RETURN

      WRITE(6,633) (I,JLEVEL(2*I-1),JLEVEL(2*I),I=1,NLEVEL)
  633 FORMAT(///'  CROSS SECTIONS WILL BE COMPUTED AMONG FOLLOWING ',
     &       'LEVELS'//'  LEVEL J1  J2 '/(' ',3I4))
      IF (NLEVEL.GT.MXSIG) THEN
        WRITE(6,693) NLEVEL,MXSIG
        NLEVEL=MXSIG
      ENDIF
      IMSG=0
      DO 3200 I=1,NLEVEL
        JI1=JLEVEL(2*I-1)
        JI2=JLEVEL(2*I)
        WRITE(6,634) I,JI1,JI2
  634   FORMAT(/'  INITIAL LEVEL =',I4,'      J1, J2  =',3I4)
        NONZRO=0
        DO 3201 IIF=1,NLEVEL
          JF1=JLEVEL(2*IIF-1)
          JF2=JLEVEL(2*IIF)
          SIG(IIF)=0.D0
          S(IIF)=SPACE
          L1LO=ABS(JI1-JF1)
          L1HI=JI1+JF1
          L2LO=ABS(JI2-JF2)
          L2HI=JI2+JF2
          DO 3202 L1=L1LO,L1HI,IHOMO
            IX1=L1/IHOMO+1
          DO 3202 L2=L2LO,L2HI,ICNSYM
            IX2=L2/ICNSYM+1
            IF (IDENT.NE.0) GOTO 3203

C  INDEX FOR DISTINGUISHABLE PARTICLES
            IX=(IX1-1)*NL2+IX2
            GOTO 3204

C  BELOW FOR INDISTINGUISHABLE PARTICLES/ ASSUME ICNSYM=IHOMO.
 3203       IX1=MAX(L1,L2)/IHOMO+1
            IX2=MIN(L1,L2)/IHOMO+1
            IX=(IX1-1)*IX1/2+IX2
C  SEE IF WE HAVE THIS (I.E., IX.LE.NSIG)
 3204       IF (IX.LE.NSIG) GOTO 3205

            S(IIF)=STAR
            IMSG=1
            GOTO 3202

 3205       TJ1=THREEJ(JI1,L1,JF1)
            TJ2=THREEJ(JI2,L2,JF2)
            SIG(IIF)=SIG(IIF)+TJ1*TJ1*TJ2*TJ2*SIG3(IX)
 3202     CONTINUE
          SIG(IIF)=SIG(IIF)*(2*JF1+1)*(2*JF2+1)
          IF (SIG(IIF).NE.0.D0) THEN
            NONZRO=NONZRO+1
            INDLEV(NONZRO)=IIF
          ENDIF
 3201   CONTINUE
 3200   WRITE(6,604) (INDLEV(IL),SIG(INDLEV(IL)),S(INDLEV(IL)),
     1                IL=1,NONZRO)

      IF (IMSG.GT.0) WRITE(6,699)
      RETURN
C
C  BELOW FOR ITYPE=5, INITIAL PROCESSING FOR ITYPE=6 ALSO
C  >>SG (FEB 92) N.B. CODE *ASSUMES* NVC=1 (ONE VIB CHANNEL).
 5000 WRITE(6,650)
  650 FORMAT(///'  ACCUMULATED Q(L,M1,M2) ARE AS FOLLOWS')
      WRITE(6,651) LCODE(1),LQLS,IZERO,IZERO,IZERO,QLOLD(1,1)
  651 FORMAT(' ',A4,2X,A4,'(',3I3,') =',1PE13.5)
      DO 5001 L=1,NQL
 5001   WRITE(6,651) LCODE(IXQL(NIXQL,L)+1),LQLT,LM(1,IXQL(1,L)),
     &               LM(2,IXQL(1,L)),LM(2,IXQL(2,L)),QL(1,1,L)
      IMSG=0
      IF (NLEVEL.LE.MXSIG) GOTO 5109

      WRITE(6,693) NLEVEL,MXSIG
  693 FORMAT(/'  NLEVEL =',I6,'  REDUCED BECAUSE OF MXSIG =',I5)
      NLEVEL=MXSIG
 5109 IF (ITYPE.EQ.6) GOTO 6000

      WRITE(6,652)
  652 FORMAT(///'  CROSS SECTIONS WILL BE COMPUTED AMONG FOLLOWING ',
     &       'LEVELS'//'  LEVEL J   K PRTY')
      DO 5002 I=1,NLEVEL
 5002   WRITE(6,653) I,JLEVEL(3*I-2),JLEVEL(3*I-1),JLEVEL(3*I)
  653   FORMAT(' ',4I4)

      DO 5100 I=1,NLEVEL
        JI=JLEVEL(3*I-2)
        XJI=JI
        KI=JLEVEL(3*I-1)
        XKI=KI
        EPSI=PARSGN(JLEVEL(3*I))
        IF (KI.EQ.0) EPSI=0.D0
        XNI=XNORM(EPSI)
        WRITE(6,654) I,JI,KI,JLEVEL(3*I)
  654   FORMAT(/'  INITIAL LEVEL =',I4,'      J, K, PRTY =',3I4)
        NONZRO=0
        DO 5101 IIF=1,NLEVEL
          JF=JLEVEL(3*IIF-2)
          XJF=JF
          KF=JLEVEL(3*IIF-1)
          XKF=KF
          EPSF=PARSGN(JLEVEL(3*IIF))
          IF (KF.EQ.0) EPSF=0.D0
          XNF=XNORM(EPSF)
          LLO=ABS(JI-JF)
          LHI=JI+JF
          PJK=PARSGN(JI+JF+KI+KF)
          MPLS=KI+KF
          MMIN=ABS(KI-KF)
          P2=1.D0
          IF (KI-KF.LT.0) P2=PARSGN(MMIN)
          SIG(IIF)=0.D0
          S(IIF)=SPACE
          TMAX=0.D0
          DO 5102 L=LLO,LHI
            XL=L
            PL=PJK*PARSGN(L)
C  -----------------------TERM 1 -------------------
            PP=1.D0+EPSI*EPSF*PL
            PP=PP*PP
            IF (PP.LE.ZTOL) GOTO 5200

            TJ=THRJ(XJF,XL,XJI,XKF,XKI-XKF,-XKI)
            TJ=TJ*TJ
            IF (TJ.LE.ZTOL) GOTO 5200

            CALL IXQLF(LM,LMAX,L,MMIN,MMIN,0,INDX,IXQL,NIXQL,NQL)
            IF (INDX.GT.0) GOTO 5110

            IF (INDX.EQ.-1) GOTO 5200

            IMSG=1
            S(IIF)=STAR
            GOTO 5200

 5110       TT=PP*TJ*QL(1,1,INDX)
            TMAX=MAX(ABS(TT),TMAX)
            SIG(IIF)=SIG(IIF)+TT * XJSTEP
C  -----------------------TERM 2 -------------------
 5200       PP=(1.D0+EPSI*EPSF*PL)*(EPSF+EPSI*PL)
            IF (ABS(PP).LE.ZTOL) GOTO 5300

            TJ=THRJ(XJF,XL,XJI,XKF,XKI-XKF,-XKI)*
     &         THRJ(XJF,XL,XJI,-XKF,XKF+XKI,-XKI)
            IF (ABS(TJ).LE.ZTOL) GOTO 5300

            CALL IXQLF(LM,LMAX,L,MPLS,MMIN,1,INDX,IXQL,NIXQL,NQL)
            IF (INDX.GT.0) GOTO 5210

            IF (INDX.EQ.-1) GOTO 5300

            IMSG=1
            S(IIF)=STAR
            GOTO 5300

 5210       TT=2.D0*P2*PP*TJ*QL(1,1,INDX)
            TMAX=MAX(TMAX,ABS(TT))
            SIG(IIF)=SIG(IIF)+TT * XJSTEP
C  -----------------------TERM 3 -------------------
 5300       PP=EPSF+EPSI*PL
            PP=PP*PP
            IF (PP.LE.ZTOL) GOTO 5102

            TJ=THRJ(XJF,XL,XJI,-XKF,XKF+XKI,-XKI)
            TJ=TJ*TJ
            IF (TJ.LE.ZTOL) GOTO 5102

            CALL IXQLF(LM,LMAX,L,MPLS,MPLS,0,INDX,IXQL,NIXQL,NQL)
            IF (INDX.GT.0) GOTO 5310

            IF (INDX.EQ.-1) GOTO 5102

            S(IIF)=STAR
            IMSG=1
            GOTO 5102

 5310       TT=PP*TJ*QL(1,1,INDX)
            TMAX=MAX(ABS(TT),TMAX)
            SIG(IIF)=SIG(IIF)+TT * XJSTEP
 5102     CONTINUE
          IF (ABS(SIG(IIF)).GE.ZTOL*TMAX) GOTO 5101
          IF (SIG(IIF).EQ.0.D0) GOTO 5101

          IF (PRNT) WRITE(6,697) IIF,SIG(IIF),TMAX
  697     FORMAT('  * * * NOTE.  ROUND-OFF ERROR FOR LEV(F) =',I3,
     &           ',   SIG(IIF),TMAX =',2E12.4)
          SIG(IIF)=0.D0
          SIG(IIF)=SIG(IIF)*XNI*XNF*FUNC(JF)
          IF (SIG(IIF).NE.0.D0) THEN
            NONZRO=NONZRO+1
            INDLEV(NONZRO)=IIF
          ENDIF
 5101   CONTINUE
 5100   WRITE(6,604) (INDLEV(IL),SIG(INDLEV(IL)),S(INDLEV(IL)),
     1                IL=1,NONZRO)

      IF (IMSG.GT.0) WRITE(6,699)
      RETURN
C
C  BELOW FOR ITYPE=6
 6000 DO 6100 I=1,NLEVEL
        WRITE(6,664) I,JLEVEL(4*I-3),JLEVEL(4*I-2),JLEVEL(4*I-1)
  664   FORMAT(/'  INITIAL LEVEL =',I4,'      J, TAU, PARITY =',3I4)
        NONZRO=0
        DO 6101 IIF=1,NLEVEL
          SIG(IIF)=0.D0
          S(IIF)=SPACE
          CALL SIG6(NLEVEL,JLEVEL,ATAU,I,IIF,SIG(IIF),S(IIF),IMSG,
     1              QL,IXQL,NIXQL,NQL,LM,LMAX)
          IF (SIG(IIF).NE.0.D0) THEN
            NONZRO=NONZRO+1
            INDLEV(NONZRO)=IIF
          ENDIF
 6101   CONTINUE
 6100   WRITE(6,604) (INDLEV(IL),SIG(INDLEV(IL))*XJSTEP,S(INDLEV(IL)),
     1                IL=1,NONZRO)

      IF (IMSG.GT.0) WRITE(6,699)
      RETURN
C
      END
