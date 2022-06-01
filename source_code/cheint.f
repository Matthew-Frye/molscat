      SUBROUTINE CHEINT(EINT,DGVL,N,OLDFAC,CM2RU)
C  Copyright (C) 2022 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
C
C  Written by C R Le Sueur Sep 2018
C  THIS SUBROUTINE ALTERS EINT FROM ITS VALUE ON ENTRY TO THE VALUE FOR
C  THE CURRENT SET OF CONDITIONS (MOSTLY EFVs IN THE ARRAY VCONST).
C  IF A PERTURBATION IS PRESENT, IT IS INCLUDED IN THE SHIFT
C
C  ON ENTRY: EINT   CONTAINS THE INTERNAL ENERGY (FROM PREVIOUS LOOP
C                            OVER EFVs OR FROM INITIALISATION)
C            DGVL   CONTAINS FACTORS WHICH, WHEN MULTIPLIED BY THE VALUES
C                            IN VCONST, GIVE CONTRIBUTIONS TO THE INTERNAL
C                            ENERGY OF EACH BASIS FUNCTION
C            N      IS THE SIZE OF THE CURRENT BASIS
C            OLDFAC CONTAINS THE VALUES OF VCONST FROM THE PREVIOUS LOOP
C                            OVER EFVs (IT CONTAINS ZEROS BEFORE THE LOOP
C                            BEGINS)
C            CM2RU  IS THE FACTOR THAT CONVERTS EINT INTO INTERNAL REDUCED
C                   UNITS FROM CM-1
C
C  ON EXIT: EINT   CONTAINS THE CURRENT VALUES FOR THE INTERNAL ENERGY
C           OLDFAC REMEMBERS THE TOTAL SHIFT SO FAR FOR THE NEXT CYCLE

      USE potential, ONLY: MXOMEG, NCONST, NDGVL, VCONST
      IMPLICIT NONE

      SAVE
      DOUBLE PRECISION, INTENT(INOUT) :: EINT(N),OLDFAC(MXOMEG)
      DOUBLE PRECISION, INTENT(IN)    :: DGVL(N,NDGVL),CM2RU
      INTEGER,          INTENT(IN)    :: N

      DOUBLE PRECISION SHIFT,DELTAN
      INTEGER I,J,IPERTN,IPOWN

      COMMON/EXPVAL/IPERTN,IPOWN,DELTAN

      IF (NCONST.NE.0) RETURN
      DO I=1,N
        DO J=1,NDGVL
          SHIFT=VCONST(J)-OLDFAC(J)
          IF (-IPERTN.EQ.J .AND. IPOWN.EQ.0) SHIFT=SHIFT+DELTAN
          EINT(I)=EINT(I)+CM2RU*SHIFT*DGVL(I,J)
        ENDDO
      ENDDO

      DO J=1,NDGVL
       OLDFAC(J)=VCONST(J)
       IF (-IPERTN.EQ.J .AND. IPOWN.EQ.0) OLDFAC(J)=OLDFAC(J)+DELTAN
      ENDDO

      RETURN
      END
