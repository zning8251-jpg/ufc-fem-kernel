!===============================================================================
! MODULE: MD_Constr_Prop
! LAYER:  L3_MD
! DOMAIN: Constraint
! ROLE:   Prop — Contact property database
! BRIEF:  Name->(mu_s,mu_k,penalty) mapping for contact interactions.
!===============================================================================
!
! Types:
!   [Desc] UF_ContactPropertyDef — Single contact property definition
!   [Desc] UF_ContactPropertyDB  — Contact property database container
!
! Procedures (P0):
!   cpdb_init / cpdb_add_property / cpdb_find_by_name / cpdb_find_by_id
!   cpdb_get_property / cpdb_clear
!
! Status: ACTIVE | Last verified: 2026-04-28
!===============================================================================
!>>> UFC_L3_QUENCH | Domain:Const | Role:Other | FuncSet:Query | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
!>>> UFC_L3_CONTRACT | Constraint/CONTRACT.md

MODULE MD_Constr_Prop
    USE IF_Prec_Core, ONLY: wp, i4
    IMPLICIT NONE
    PRIVATE

    ! PUBLIC types (A-Z)
    PUBLIC :: UF_ContactPropertyDB, UF_ContactPropertyDef

    INTEGER(i4), PARAMETER :: MAX_CONTACT_NAME = 80

    ! ------------------------------------------------------------------
    ! Single contact property definition (L2 side) (F2.2: penalty_n/penalty_t)
    ! ------------------------------------------------------------------
    TYPE :: UF_ContactPropertyDef
        CHARACTER(LEN=MAX_CONTACT_NAME) :: name = ""
        INTEGER(i4) :: id = 0
        REAL(wp)    :: mu_s = 0.0_wp        ! Static friction coefficient
        REAL(wp)    :: mu_k = 0.0_wp        ! Kinetic friction coefficient
        REAL(wp)    :: penalty_scale = 10.0_wp ! Penalty scaling factor
        REAL(wp)    :: penalty_n = 0.0_wp   ! F2.2: Normal penalty (0 => use scale*E/h)
        REAL(wp)    :: penalty_t = 0.0_wp   ! F2.2: Tangential penalty (0 => use ratio*penalty_n)
        REAL(wp)    :: adjust = 0.0_wp       ! Initial clearance adjustment
    END TYPE UF_ContactPropertyDef

    ! ------------------------------------------------------------------
    ! Contact property database (L2, owned by UF_ModelDef)
    ! ------------------------------------------------------------------
    TYPE :: UF_ContactPropertyDB
        INTEGER(i4) :: num_props = 0
        TYPE(UF_ContactPropertyDef), ALLOCATABLE :: props(:)
    CONTAINS
        PROCEDURE :: init          => cpdb_init
        PROCEDURE :: add_property  => cpdb_add_property
        PROCEDURE :: find_by_name  => cpdb_find_by_name
        PROCEDURE :: find_by_id    => cpdb_find_by_id
        PROCEDURE :: get_property  => cpdb_get_property
        PROCEDURE :: clear         => cpdb_clear
    END TYPE UF_ContactPropertyDB

CONTAINS

    ! ------------------------------------------------------------------
    ! Initialize database (allocate storage)
    ! ------------------------------------------------------------------
    SUBROUTINE cpdb_init(this, capacity)
        CLASS(UF_ContactPropertyDB), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN), OPTIONAL :: capacity
        INTEGER(i4) :: cap

        cap = 16
        IF (PRESENT(capacity)) cap = capacity

        this%num_props = 0
        IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
        ALLOCATE(this%props(cap))
    END SUBROUTINE cpdb_init

    ! ------------------------------------------------------------------
    ! Add a new property (append, auto-assign id)
    ! ------------------------------------------------------------------
    SUBROUTINE cpdb_add_property(this, prop)
        CLASS(UF_ContactPropertyDB), INTENT(INOUT) :: this
        TYPE(UF_ContactPropertyDef), INTENT(IN) :: prop
        TYPE(UF_ContactPropertyDef), ALLOCATABLE :: tmp(:)

        IF (.NOT. ALLOCATED(this%props)) CALL this%init()

        IF (this%num_props >= SIZE(this%props)) THEN
            ALLOCATE(tmp(SIZE(this%props) * 2))
            tmp(1:this%num_props) = this%props(1:this%num_props)
            CALL MOVE_ALLOC(tmp, this%props)
        END IF

        this%num_props = this%num_props + 1
        this%props(this%num_props) = prop
        this%props(this%num_props)%cfg%id = this%num_props
    END SUBROUTINE cpdb_add_property

    ! ------------------------------------------------------------------
    ! Find property by name; returns index (>=1) or -1 if not found
    ! ------------------------------------------------------------------
    INTEGER(i4) FUNCTION cpdb_find_by_name(this, name) RESULT(idx)
        CLASS(UF_ContactPropertyDB), INTENT(IN) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        INTEGER(i4) :: i

        idx = -1
        IF (.NOT. ALLOCATED(this%props)) RETURN

        DO i = 1, this%num_props
            IF (TRIM(this%props(i)%name) == TRIM(name)) THEN
                idx = i
                RETURN
            END IF
        END DO
    END FUNCTION cpdb_find_by_name

    ! ------------------------------------------------------------------
    ! Validate id; returns same id if valid, -1 otherwise
    ! ------------------------------------------------------------------
    INTEGER(i4) FUNCTION cpdb_find_by_id(this, id) RESULT(idx)
        CLASS(UF_ContactPropertyDB), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: id

        idx = -1
        IF (id >= 1 .AND. id <= this%num_props) idx = id
    END FUNCTION cpdb_find_by_id

    ! ------------------------------------------------------------------
    ! Get property pointer by index
    ! ------------------------------------------------------------------
    FUNCTION cpdb_get_property(this, idx) RESULT(prop_ptr)
        CLASS(UF_ContactPropertyDB), INTENT(IN), TARGET :: this
        INTEGER(i4), INTENT(IN) :: idx
        TYPE(UF_ContactPropertyDef), POINTER :: prop_ptr

        NULLIFY(prop_ptr)
        IF (.NOT. ALLOCATED(this%props)) RETURN
        IF (idx < 1 .OR. idx > this%num_props) RETURN

        prop_ptr => this%props(idx)
    END FUNCTION cpdb_get_property

    ! ------------------------------------------------------------------
    ! Clear database
    ! ------------------------------------------------------------------
    SUBROUTINE cpdb_clear(this)
        CLASS(UF_ContactPropertyDB), INTENT(INOUT) :: this

        this%num_props = 0
        IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    END SUBROUTINE cpdb_clear

END MODULE MD_Constr_Prop