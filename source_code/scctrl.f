      SUBROUTINE SCCTRL(N,MXLAM,NHAM,
     1                  JSINDX,SR,SI,U,VL,
     2                  IV,EINT,CENT,WVEC,
     3                  L,NB,P,ERED,EP2RU,CM2RU,
     4                  RSCALE,DEGTOL,DRMAX,NSTAB,NOPEN,IPRINT,
     5                  IBOUND,ICHAN,WAVE,ILDSVU)
C  Copyright (C) 2022 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
C
C  THIS SUBROUTINE SETS UP THE STORAGE REQUIREMENTS FOR ALL THE
C  DIFFERENT PROPAGATORS IMPLEMENTED
C
C  03-12-15 CR Le Sueur:
C  LONG RANGE AND SHORT RANGE PROPAGATORS HAVE BEEN DECOUPLED.
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      INTEGER IPRINT
      LOGICAL PREV
      DIMENSION JSINDX(*),SR(*),SI(*),U(*),VL(*),IV(*),EINT(*),CENT(*),
     1          WVEC(*),L(*),NB(*),P(*)
C
C  DYNAMIC STORAGE COMMON BLOCK ...
      COMMON /MEMORY/ MX,IXNEXT,NIPR,IDUMMY,X(1)
C
C  COMMON BLOCK FOR CONTROL OF USE OF PROPAGATION SCRATCH FILE
      LOGICAL IREAD,IWRITE,IREADR,IWRITR
      COMMON /PRPSCR/ ESHIFT,ISCRU,ISCRUR,IREAD,IWRITE,IREADR,IWRITR
C
C  COMMON BLOCK FOR CONTROL OF PROPAGATION SEGMENTS
      COMMON /RADIAL/ RMNINT,RMXINT,RMID,RMATCH,DRS,DRL,STEPS,STEPL,
     1                POWRS,POWRL,TOLHIS,TOLHIL,CAYS,CAYL,unset,
     2                IPROPS,IPROPL,NSEG
C
      DIMENSION STPSEG(2),CAYSEG(2),TOLSEG(2),DRSEG(2),IPRSEG(2),
     1          RBSEG(2),RESEG(2),POWSEG(2),NSTEPS(2)

      LOGICAL WAVE

C  COMMON BLOCK FOR PROPAGATOR CONTROL

C  COMMON BLOCK FOR DERIVATIVES
      LOGICAL NUMDER
      COMMON /DERIVS/ NUMDER

C  COMMON BLOCK FOR INPUT/OUTPUT CHANNEL NUMBERS
      LOGICAL IWAVEF
      INTEGER IPSISC,IWAVSC,IWAVE
      COMMON /IOCHAN/ IPSISC,IWAVSC,IWAVE,NWVCOL,IWVSTP,IWAVEF
C
      NSQ=N*N

      IF (WAVE) CALL WVOPEN(N)

      CALL SCPSET(IPRSEG,RBSEG,RESEG,DRSEG,STPSEG,
     1            TOLSEG,CAYSEG,POWSEG)

      IREC=1
C
C  IC2 IS USED TO REMEMBER WHAT IS SCRATCH FOR RESETTING AT END
      IC2=IXNEXT
      NUSED=0
C
C  COUNT THE NUMBER OF OPEN CHANNELS AND SET UP WVEC ARRAY
      CALL GTWVEC(WVEC,WMAX,ERED,EINT,NOPEN,N)
      IF (NOPEN.EQ.0) RETURN

C  SET S MATRIX TO IDENTITY IN CASE NO PROPAGATION IS DONE
      IJ=0
      DO I=1,NOPEN
      DO J=1,NOPEN
        IJ=IJ+1
        SR(IJ)=0.D0
        SI(IJ)=0.D0
        IF (I.EQ.J) SR(IJ)=1.D0
      ENDDO
      ENDDO

C     ---------------------------------------------------------------

      ISTART=0

      DO ISEG=1,NSEG
        NUSED=0
        IF (ISEG.GT.1 .AND. PREV) RBSEG(ISEG)=RSTOP
        IPROP=IPRSEG(ISEG)
        RSTART=RBSEG(ISEG)
        RSTOP=RESEG(ISEG)
        CAY=CAYSEG(ISEG)
        DRT=DRSEG(ISEG)
        STEP=STPSEG(ISEG)
        TOLHIT=TOLSEG(ISEG)
        POW=POWSEG(ISEG)

        IF (RSTART.GE.RSTOP) THEN
          PREV=.FALSE.
          DR=DRT
          CYCLE
        ELSE
          PREV=.TRUE.
        ENDIF
        IF (IPROP.GT.-1) THEN
          IF (IREAD) THEN
            READ(ISCRU) RSTART,RSTOP,DR,EFIRST,NSTEP
            ESHIFT=ERED-EFIRST

          ELSE
            CALL DRSET(RSTART,RSTOP,STEP,TOLHIT,CAY,DRT,NSTEP,DR,
     1                 unset,IPROP,POW)
            IF (IWRITE) WRITE(ISCRU) RSTART,RSTOP,DR,ERED,NSTEP
          ENDIF
        ENDIF
        DRSEG(ISEG)=DR
C
C  INITIALISE Y MATRIX (HERE CALLED SR)
C
        IF (IPROP.NE.-1) THEN
          IT1=IC2    ! DIAG
          IT2=IT1+N  ! EVAL
          IXNEXT=IT2+N
          CALL CHKSTR(NUSED)
          IF (ISTART.EQ.0)
     1      CALL YINIT(SR,U,VL,IV,P,CENT,EINT,X(IT1),
     2                 X(IT2),SI,N,MXLAM,NHAM, !NPOTL,
     3                 ERED,RSTART,EP2RU,CM2RU,RSCALE,
     4                 .TRUE.,IPRINT)
          IXNEXT=IT1
          IC2=IT1
        ENDIF
C
        IF (IPROP.EQ.2) THEN
C  SOLVE COUPLED EQUATIONS BY PROPAGATOR OF DE VOGELAERE
C
          IT1=IC2        ! Y  (WAVEFUNCTION MATRIX)
          IT2=IT1+4*NSQ  ! YP (WAVEFUNCTION DERIVATIVE)
          IT3=IT2+2*NSQ  ! F
          IT4=IT3+4*NSQ  ! DIAG
          IXNEXT=IT4+N
          CALL CHKSTR(NUSED)
          CALL DVPROP(N,NSQ,MXLAM,NHAM,
     1                SR,U,VL,IV,EINT,CENT,L,NB,P,
     2                X(IT1),X(IT2),X(IT3),X(IT4),
     3                RSTART,RSTOP,NSTEP,DR,NSTAB,
     4                ERED,EP2RU,CM2RU,RSCALE,IPRINT)
          IF (IPRINT.GE.8) WRITE(6,1800) 'DVPROP',RSTART,RSTOP,NSTEP
 1800     FORMAT(/2X,A,'. PSI AND PSI'' PROPAGATED FROM ',
     &           F12.4,'  TO',1PG12.5,'  IN ',I6,'  STEPS.')
C
        ELSEIF (IPROP.EQ.3) THEN
C  SOLVE COUPLED EQUATIONS BY R-MATRIX PROPAGATOR OF WALKER & LIGHT
C
          IT1=IC2      ! W
          IT2=IT1+NSQ  ! R
          IT3=IT2+NSQ  ! EIGOLD
          IT4=IT3+N    ! EIGNOW
          IT5=IT4+N    ! DIAG
          IT6=IT5+N    ! R1/N1
          IT7=IT6+N    ! R2/N2
          IT8=IT7+N    ! R3
          IT9=IT8+N    ! R4
          IXNEXT=IT9+N
          CALL CHKSTR(NUSED)
          CALL RMPROP(N,NSQ,MXLAM,NHAM,
     1                SR,SI,U,VL,IV,EINT,CENT,P,
     2                X(IT1),X(IT2),X(IT3),X(IT4),X(IT5),X(IT6),X(IT7),
     3                X(IT8),X(IT9),X(IT6),X(IT7),
     4                RSTART,RSTOP,NSTEP,DR,POW,
     5                ERED,EP2RU,CM2RU,RSCALE,IPRINT)
          IF (IPRINT.GE.8) WRITE(6,1900) 'RMPROP',RSTART,RSTOP,NSTEP
 1900     FORMAT(/2X,A,'. R MATRIX PROPAGATED FROM ',
     &           F12.4,'  TO',1PG12.5,'  IN ',I6,'  STEPS.')
C
        ELSEIF (IPROP.EQ.4) THEN
C  SOLVE COUPLED EQUATIONS BY VIVS PROPAGATOR OF PARKER
C
C  VVPROP PROPAGATES THE R MATRIX, WHICH IS THE INVERSE OF THE
C  LOG-DERIVATIVE MATRIX PRODUCED BY YINIT AND USED BY OTHER PROPAGATORS
C  INVERT Y TO GET R (UNCONDITIONALLY, THOUGH VIVS IS NOT CURRENTLY
C  ALLOWED AS A SHORT-RANGE PROPAGATOR)
C
          CALL SYMINV(SR,N,N,IFAIL)
          CALL DSYFIL('U',N,SR,N)
C
          TLDIAG=0.064D0*SQRT(TOLHIT/0.001D0)
          TOFF=TLDIAG
          IT1=IC2              ! A1
          IT2=IT1+N            ! A1P
          IT3=IT2+N            ! B1
          IT4=IT3+N            ! B1P
          IT5=IT4+N            ! WKS
          IT6=IT5+N            ! G1
          IT7=IT6+N            ! G1P
          IT8=IT7+N            ! G2
          IT9=IT8+N            ! G2P
          IT10=IT9+N           ! COSX
          IT11=IT10+N          ! SINX
          IT12=IT11+N          ! SINE
          IT13=IT12+N          ! DIAG
          IT14=IT13+N          ! XK
          IT15=IT14+N          ! XSQ
          IT16=IT15+N          ! TSTORE
          IT17=IT16+NSQ        ! W0
          IT18=IT17+NSQ        ! W1
          IT19=IT18+NSQ        ! W2
          IT20=IT19+NSQ        ! EYE11
          IT21=IT20+NSQ        ! EYE12
          IT22=IT21+NSQ        ! EYE22
          IT23=IT22+NSQ        ! VECOLD
          IXNEXT=IT23+NSQ
          CALL CHKSTR(NUSED)
C
          CALL VVPROP(N,NSQ,MXLAM,NHAM,
     1               SR,SI,U,VL,IV,EINT,CENT,P,
     2               X(IT1),X(IT2),X(IT3),X(IT4),X(IT5),
     3               X(IT6),X(IT7),X(IT8),X(IT9),X(IT10),X(IT11),
     4               X(IT12),X(IT13),X(IT14),X(IT15),X(IT16),X(IT17),
     5               X(IT18),X(IT19),X(IT20),X(IT21),X(IT22),X(IT23),
     6               RSTART,RSTOP,NSTEP,DR,DRMAX,TLDIAG,TOFF,
     7               ERED,EP2RU,CM2RU,RSCALE,IPRINT)
C
C  INVERT R TO GET Y
C
          CALL SYMINV(SR,N,N,IFAIL)
          IF (IPRINT.GE.8) WRITE(6,1900) 'VVPROP',RSTART,RSTOP,NSTEP
C
        ELSEIF (IPROP.EQ.5) THEN
C  SOLVE COUPLED EQUATIONS BY LOG-DERIVATIVE PROPAGATOR OF JOHNSON
C
          IT1=IC2      ! DIAG
          IXNEXT=IT1+N
          CALL CHKSTR(NUSED)
          CALL LDPROP(N,MXLAM,NHAM,
     1                SR,U,VL,IV,EINT,CENT,P,X(IT1),
     2                RSTART,RSTOP,NSTEP,DR,NODES,
     3                ERED,EP2RU,CM2RU,RSCALE,IPRINT)
          IF (IPRINT.GE.8) WRITE(6,2000) 'LDPROP',RSTART,RSTOP,NSTEP
C
        ELSEIF (IPROP.EQ.6) THEN
C  SOLVE COUPLED EQUATIONS BY DIABATIC LOG-DERIVATIVE PROPAGATOR
C  OF MANOLOPOULOS
C
          IF ((N.GT.1 .OR. WAVE) .AND. NSTEP.GT.0 .AND.
     1        RSTART.LT.RSTOP) THEN
            IT1=IC2       ! Y14
            IT2=IT1+N     ! Y23
            IT3=IT2+N     ! DIAG
            IXNEXT=IT3+N
            IT4=IT3+N     ! W
            IT5=IT4+NSQ   ! W2
            IT6=IT5+NSQ   ! W3
            IF (WAVE) IXNEXT=IT6+NSQ
            CALL CHKSTR(NUSED)
            CALL MDPROP(N,MXLAM,NHAM,
     1                  SR,U,VL,IV,EINT,CENT,P,
     2                  X(IT1),X(IT2),X(IT3),X(IT4),X(IT5),X(IT6),
     3                  RSTART,RSTOP,NSTEP,DR,NODES,IREC,WAVE,
     4                  ERED,EP2RU,CM2RU,RSCALE,IPRINT)
            IF (IPRINT.GE.8) WRITE(6,2000) 'MDPROP',RSTART,RSTOP,NSTEP
          ELSEIF (N.EQ.1) THEN
            NPT=NSTEP+1
            IT1=IC2           ! U
            IT2=IT1+NPT       ! W
            IT3=IT2+NPT       ! Q
            IT4=IT3+NPT       ! Y1
            IT5=IT4+NPT       ! Y2
            IF1=IT5+NPT
            ITP=IT3           ! P
            IF2=ITP+NPT*NHAM !*MXLAM
            IXNEXT=MAX(IF1,IF2)
            NUSED=0
            CALL CHKSTR(NUSED)
            CALL ODPROP(MXLAM,NHAM,
     1                  SR(1),VL,IV,EINT,CENT,X(ITP),
     3                  X(IT1),X(IT2),X(IT3),X(IT4),X(IT5),
     4                  RSTART,RSTOP,NSTEP,DR,NODES,
     5                  ERED,EP2RU,CM2RU,RSCALE,IPRINT)
            IF (IPRINT.GE.8) WRITE(6,2000) 'ODPROP',RSTART,RSTOP,NSTEP
          ENDIF
C
        ELSEIF (IPROP.EQ.7) THEN
C  SOLVE COUPLED EQUATIONS BY ADIABATIC LOG-DERIVATIVE PROPAGATOR
C  OF MANOLOPOULOS
C
          IT2=IC2      ! Q
          IT3=IT2+NSQ  ! W
          IT4=IT3+NSQ  ! EIVAL
          IT5=IT4+N    ! Y1
          IT6=IT5+N    ! Y2
          IT7=IT6+N    ! Y3
          IT8=IT7+N    ! Y4
          IT9=IT8+N    ! DIAG
          IXNEXT=IT9+N
          CALL CHKSTR(NUSED)
          CALL MAPROP(N,NSQ,MXLAM,NHAM,
     1                SR,SI,U,VL,IV,EINT,CENT,P,
     2                X(IT2),X(IT3),X(IT4),X(IT5),X(IT6),X(IT7),X(IT8),
     3                X(IT9),
     4                RSTART,RSTOP,NSTEP,DR,NODES,
     4                ERED,EP2RU,CM2RU,RSCALE,IPRINT)
          IF (IPRINT.GE.8) WRITE(6,2000) 'MAPROP',RSTART,RSTOP,NSTEP
 2000     FORMAT(/2X,A,'. LOG-DERIVATIVE MATRIX PROPAGATED FROM ',
     &           F12.4,'  TO',1PG12.5,'  IN ',I6,'  STEPS.')

C
        ELSEIF (IPROP.EQ.8) THEN
C  SOLVE COUPLED EQUATIONS BY SYMPLECTIC LOG-DERIVATIVE PROPAGATORS
C  OF MANOLOPOULOS & GREY
C
          IT1=IC2      ! DIAG
          IXNEXT=IT1+N
          CALL CHKSTR(NUSED)
          CALL MGPROP(N,MXLAM,NHAM,
     1                SR,U,VL,IV,EINT,CENT,P,X(IT1),
     3                RSTART,RSTOP,NSTEP,DR,NODES,
     4                ERED,EP2RU,CM2RU,RSCALE,IPRINT)
          IF (IPRINT.GE.8) WRITE(6,2000) 'MGPROP',RSTART,RSTOP,NSTEP
C
        ELSEIF (IPROP.EQ.9) THEN
C  SOLVE COUPLED EQUATIONS BY AIRY PROPAGATOR OF ALEXANDER AND MANOLOPOULOS
C
          IF (RSTART.LT.RSTOP) THEN
            IF (ISCRU.EQ.0) ITWO=-1
            IT1=IC2     ! Y1
            IT2=IT1+N   ! Y2
            IT3=IT2+N   ! Y4
            IT4=IT3+N   ! VECNOW
            IT5=IT4+NSQ ! VECNEW
            IT6=IT5+NSQ ! EIGOLD
            IT7=IT6+N   ! EIGNOW
            IT8=IT7+N   ! HP
            IXNEXT=IT8+N
            CALL CHKSTR(NUSED)
            CALL AIPROP(N,MXLAM,NHAM,
     1                  SR,SI,U,VL,IV,EINT,CENT,P,
     3                  X(IT1),X(IT2),X(IT3),X(IT4),X(IT5),
     4                  X(IT6),X(IT7),X(IT8),
     5                  RSTART,RSTOP,NSTEP,DR,POW,TOLHIT,NODES,
     6                  ERED,EP2RU,CM2RU,RSCALE,IPRINT,IREC,WAVE)
            IF (IPRINT.GE.8) WRITE(6,2000) 'AIPROP',RSTART,RSTOP,NSTEP
          ENDIF
C
        ELSEIF (IPROP.EQ.-1) THEN
C
C  SOLVE SINGLE-CHANNEL EQUATION BY WKB USING GAUSS-MEHLER INTEGRATION.
C
          IF (N.EQ.1) GOTO 810
          WRITE(6,601) N
  601     FORMAT(/' ***** ERROR.  WKB IMPLEMENTED ONLY FOR',
     1           ' ONE-CHANNEL CASE.  TERMINATED WITH N =',I4)
          STOP
  810     IT1=IC2   ! W
          IT2=IT1+1 ! DIAG
          IXNEXT=IT2+1
          IF (NUMDER) IXNEXT=IXNEXT+2*IPDIM
          CALL CHKSTR(NUSED)
C
          DWVEC=SQRT(ERED-EINT(1))
          CALL WKB(N,MXLAM,NHAM,
     1             SR,SI,VL,IV,EINT,CENT,P,
     2             DWVEC,L,X(IT1),X(IT2),
     3             RSTART,TOLHIT,ERED,EP2RU,CM2RU,RSCALE,IPRINT)
C
        ELSE
          WRITE(6,699) IPROP
  699     FORMAT(/' SCCTRL CALLED WITH AN ILLEGAL IPROP=',I4)
          STOP
        ENDIF
        ISTART=1
        NSTEPS(ISEG)=NSTEP
      ENDDO
      IF (ISCRUR.NE.0) REWIND (ISCRUR)
C
C  -----------------------------------------------------------------------
C  END OF PROPAGATION
C
      IF (IPRSEG(NSEG).GE.0) THEN
        CALL YTRANS(SR,SI,EINT,WVEC,
     1              JSINDX,L,N,P,VL,IV,
     2              MXLAM,NHAM,ERED,EP2RU,CM2RU,DEGTOL,
     3              NOPEN,IBOUND,CENT,IPRINT,.TRUE.)
C  IF OUTPUT OF LOG-DERIVATIVE MATRIX REQUESTED,
C  WRITE PROPAGATION VECTORS (LDRWPV) AND MATRIX (LDRWMD)
        IF (ILDSVU.GT.0) THEN
          IDUM=LDRWPV(ILDSVU,.TRUE.,N,JSINDX,L,EINT)
          IDUM=LDRWMD(ILDSVU,.TRUE.,N,RSTOP,SR)
        ENDIF
C
        IT1=IC2      ! SJ
        IT2=IT1+N    ! SJP
        IT3=IT2+N    ! SN
        IT4=IT3+N    ! SNP
        IT5=IT4+N    ! WORKSPACE TO SAVE SI FOR WAVEFUNCTIONS
        IXNEXT=IT5
        IF (WAVE) IXNEXT=IT5+NSQ
        CALL CHKSTR(NUSED)

C  LOG-DERIVATIVE MATRIX STORED IN SR ON EXIT FROM PROPAGATOR ROUTINES
        IF (WAVE) X(IT5:IT5+NSQ-1)=SI(1:NSQ)
C
C  CONVERT LOG-DERIVATIVE MATRIX TO K MATRIX AND THEN TO S MATRIX
C
        CALL YTOK(NB,WVEC,L,N,NOPEN,X(IT1),X(IT2),X(IT3),X(IT4),
     2            SR,SI,U,RSTOP,CENT)
        CALL KTOS(U,SR,SI,NOPEN)
      ENDIF

      IF (WAVE) THEN
C  CALCULATE SCATTERING WAVEFUNCTION
        IT6=IT5+NSQ
        IXNEXT=IT6+NSQ
        CALL CHKSTR(NUSED)
        CALL SCWAVE(RBSEG,RESEG,DRSEG,IPRSEG,NSTEPS,NSEG,
     1              WVEC,X(IT1),X(IT2),X(IT3),X(IT4),
     1              X(IT6),SR,SI,X(IT5),U,L,N,NSQ,NOPEN,NB,
     2              ICHAN,IREC,IPRINT)
      ENDIF
C
C  WE ARE FINISHED WITH THIS TEMPORARY STORAGE; RESTORE IXNEXT.
C  THIS IS CONSISTENT W/ V11 WHICH DID NOT MODIFY SCCTRL IC2 ARGUMENT
C  ALLOCATED STORAGE ABOVE IC2 IS NOT RETAINED BEYOND A SCATTERING CALL
      IXNEXT=IC2
      IF (WAVE) THEN
        CLOSE(IPSISC)
        CLOSE(IWAVSC)
      ENDIF
      RETURN
      END
