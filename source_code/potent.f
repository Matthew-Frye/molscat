      SUBROUTINE POTENT(W, VECNOW, SCMAT, EIGNOW, HP, SCR, RNOW, DRNOW,
     1                  XLARGE, NCH, P, MXLAM, VL, IV, EP2RU, CM2RU,
     2                  RSCALE, ERED, EINT, CENT, NHAM, IPRINT)
C  Copyright (C) 2022 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
C
C ----------------------------------------------------------------------
C  AUTHOR:  MILLARD ALEXANDER
C  CURRENT REVISION DATE: 25-SEPT-87
C
C  THIS SUBROUTINE FIRST SETS UP THE WAVE-VECTOR MATRICES:
C    W = W[RNOW + 0.5 DRNOW/SQRT(3)] AND W = W[RNOW - 0.5 DRNOW/SQRT(3)]
C     B                                   A
C  THEN DIAGONALIZES THE AVERAGE; I.E. 0.5 (W  + W )
C                                            B    A
C  THE RADIAL DERIVATIVE OF THE WAVEVECTOR MATRIX IS CALCULATED BY FINITE
C  DIFFERENCE, USING THE NODES OF A TWO-POINT GAUSS-LEGENDRE QUADRATURE
C              1/2
C   D(W)/DR = 3    (W  - W ) / DRNOW
C                    B    A
C  THIS IS THEN TRANSFORMED INTO THE LOCAL BASIS
C ---------------------------------------------------------------------
C  VARIABLES IN CALL LIST:
C    W:        ON RETURN:  CONTAINS TRANSFORM OF DH/DR
C                          THIS IS THE SAME AS THE NEGATIVE OF THE
C                          WN-TILDE-PRIME MATRIX
C    VECNOW:   ON RETURN:  CONTAINS MATRIX OF EIGENVECTORS
C    SCMAT:    SCRATCH MATRIX
C    EIGNOW:   ON RETURN:  CONTAINS EIGENVALUES OF WAVEVECTOR MATRIX
C    HP:       ON RETURN: CONTAINS DIAGONAL ELEMENTS OF TRANSFORMED DH/DR
C                         THIS IS THE SAME AS THE NEGATIVE OF THE
C                         DIAGONAL ELEMENTS OF THE WN-TILDE-PRIME MATRIX
C    SCR:      SCRATCH VECTOR
C    RNOW:     MIDPOINT OF THE CURRENT INTERVAL
C    DRNOW:    WIDTH OF THE CURRENT INTERVAL
C    ERED:     TOTAL ENERGY IN ATOMIC UNITS
C    XLARGE:   ON RETURN CONTAINS LARGEST OFF-DIAGONAL ELEMENT IN
C              WN-TILDE-PRIME MATRIX
C    NCH:      NUMBER OF CHANNELS. SAME AS MAXIMUM ROW DIMENSION OF
C              MATRICES AND MAXIMUM DIMENSION OF VECTORS
C ----------------------------------------------------------------------
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      INTEGER ICOL, IERR, IONE, IPT, NCH, NCHM1, NCHP1, NROW
C  SQUARE MATRICES (OF ROW DIMENSION NCH)
      DIMENSION W(1), VECNOW(1), SCMAT(1)
C  VECTORS DIMENSIONED AT LEAST NCH
      DIMENSION EIGNOW(1), HP(1), SCR(1)
C
      DIMENSION P(1),VL(1),IV(1),EINT(1),CENT(1)
C
      DATA IONE / 1 /
      DATA ONE, XMIN1, HALF, SQ3 /1.D0, -1.D0, 0.5D0, 1.732050807D0/

      NCHP1 = NCH + 1
      NCHM1 = NCH - 1
      RA = RNOW - 0.5 * DRNOW / SQ3
      RB = RNOW + 0.5 * DRNOW / SQ3
C  SCMAT IS USED TO STORE THE WAVEVECTOR MATRIX AT RB
      CALL HAMMAT(W,    NCH,RA,P,VL,IV,ERED,EINT,CENT,EP2RU,CM2RU,
     1            RSCALE,SCR,MXLAM,NHAM,IPRINT)
      CALL HAMMAT(SCMAT,NCH,RB,P,VL,IV,ERED,EINT,CENT,EP2RU,CM2RU,
     1            RSCALE,SCR,MXLAM,NHAM,IPRINT)
C  SINCE HAMMAT RETURNS NEGATIVE OF LOWER TRIANGLE OF W(R) MATRIX
C  (EQ. 3 OF M.H. ALEXANDER, "HYBRID QUANTUM SCATTERING ALGORITHMS ..."),
C  NEXT STATEMENTS CHANGE ITS SIGN
C  NEXT LOOP STORES AVERAGE WAVEVECTOR MATRIX IN SCMAT AND DERIVATIVE OF
C  HAMILTONIAN MATRIX, IN FREE BASIS, IN W
      FACT =  SQ3 / DRNOW
C  THE ADDITIONAL MINUS SIGN IN THE PRECEDING EXPRESSION IS INTRODUCED BY
C  DH/DR =-DW/DR;  SEE EQ.(9) OF
C  M.H. ALEXANDER, "HYBRID QUANTUM SCATTERING ALGORITHMS ..."
      IPT = 1
      DO 105 ICOL = 1, NCH
C  NROW IS THE NUMBER OF (DIAGONAL PLUS SUBDIAGONAL) ELEMENTS IN COLUMN
C  IPT POINTS TO THE DIAGONAL ELEMENT IN COLUMN ICOL FOR A MATRIX STORED
C  IN PACKED COLUMN FORM
C  HP AND SCR ARE USED AS SCRATCH VECTORS HERE
        NROW = NCH - ICOL + 1
        CALL DCOPY(NROW, SCMAT(IPT), 1, SCR, 1)         !scr=W(rb)
        CALL DAXPY(NROW, ONE, W(IPT), 1, SCMAT(IPT), 1) !scmat=W(ra)+W(rb)
        CALL DAXPY(NROW, XMIN1, W(IPT), 1, SCR, 1)      !scr=W(rb)-W(ra)
        CALL DSCAL(NROW, -HALF, SCMAT(IPT), 1)        !scmat=-(W(ra)+W(rb))/2
        CALL DSCAL(NROW, FACT, SCR, 1)          !scr=root(3)*(W(rb)-W(ra))/dr
        CALL DCOPY(NROW, SCR, 1, W(IPT), 1)       !W=root(3)*(W(rb)-W(ra))/dr
        IPT = IPT + NCHP1
 105  CONTINUE
C  NEXT LOOP FILLS IN UPPER TRIANGLES OF W AND SCMAT
      IF (NCH.GT.1) THEN
        IPT = 2
        DO 110 ICOL = 1, NCH -1
C  IPT POINTS TO THE FIRST SUBDIAGONAL ELEMENT IN COLUMN ICOL
C  NROW IS THE NUMBER OF SUBDIAGONAL ELEMENTS IN COLUMN ICOL
          NROW = NCH - ICOL
          CALL DCOPY(NROW, W(IPT), 1, W(IPT + NCHM1), NCH)
          CALL DCOPY(NROW, SCMAT(IPT), 1, SCMAT(IPT + NCHM1), NCH)
          IPT = IPT + NCHP1
110     CONTINUE
      ENDIF
C ----------------------------------------------------------------------
C  DIAGONALIZE SCMAT AT RNOW AND TRANSPOSE MATRIX OF EIGENVECTORS
C  AFTER TRANSPOSITION, THE VECNOW MATRIX IS IDENTICAL TO THE TN MATRIX
C  OF EQ.(6) OF M.H. ALEXANDER, "HYBRID QUANTUM SCATTERING ALGORITHMS ..
      CALL DIAGVC(SCMAT,NCH,NCH,EIGNOW,VECNOW)
C  TRANSFORM THE DERIVATIVE INTO THE LOCAL BASIS
C  EQ.(9) OF M.H. ALEXANDER, "HYBRID QUANTUM SCATTERING ALGORITHMS ..."
      CALL TRNSFM(VECNOW, W, SCMAT, NCH, .FALSE., .TRUE.)
      CALL TRNSP(VECNOW, NCH)
      CALL DCOPY(NCH, W, NCH+1, HP, 1)
C
C     FIND LARGEST OFF-DIAGONAL ELEMENT IN TRANSFORMED W
C
      XLARGE=0.D0
      IPT=2
      DO 130 ICOL=1,NCH-1
        NCOL=NCH-ICOL
        CALL MAXMGV(W(IPT), 1, ZABS, IC, NCOL)
        IF (ZABS.GT.XLARGE) XLARGE=ZABS
        IPT=IPT+NCH+1
130   CONTINUE
C
      RETURN
      END
