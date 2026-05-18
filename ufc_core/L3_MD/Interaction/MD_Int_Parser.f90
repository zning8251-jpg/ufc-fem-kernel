!======================================================================
! MODULE:  MD_Int_Parser
! LAYER:   L3_MD
! DOMAIN:  Interaction
! ROLE:    Impl
! BRIEF:   Parser for ABAQUS contact keywords.
!          *CONTACT PAIR, *SURFACE INTERACTION, *FRICTION.
! STATUS:  FOUR-TYPE-REFACTORED (B1 header)
! DATE:    2026-04-28
!======================================================================

MODULE MD_Int_Parser
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  USE MD_Int_Def, ONLY: CONTACT_TYPE_S2S, CONTACT_TYPE_P2S, &
                        FRICTION_COULOMB, FRICTION_PENALTY, FRICTION_VISCOUS
  IMPLICIT NONE
  PRIVATE

  !-------------------------------------------------------
  ! 公开接口
  !-------------------------------------------------------
  PUBLIC :: MD_Parse_ContactPair
  PUBLIC :: MD_Parse_SurfaceInteraction
  PUBLIC :: MD_Parse_Friction
  PUBLIC :: MD_Parse_InteractionVariables
  PUBLIC :: Extract_Parameter_Value
  PUBLIC :: Convert_To_Upper

  !-------------------------------------------------------
  ! 常量定义
  !-------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MAX_LINE_LENGTH = 256
  INTEGER(i4), PARAMETER, PUBLIC :: MAX_PARAM_NAME = 32
  INTEGER(i4), PARAMETER, PUBLIC :: MAX_PARAM_VALUE = 64

  ! 关键字白名单
  CHARACTER(len=32), PARAMETER :: VALID_CONTACT_KEYWORDS(6) = &
    (/ "INTERACTION    ", "TYPE           ", "SLAVE SURFACE  ", &
       "MASTER SURFACE ", "SMOOTHING      ", "TRACKING       " /)

  CHARACTER(len=32), PARAMETER :: VALID_SI_KEYWORDS(6) = &
    (/ "INTERACTION     ", "CONTACT PAIR    ", "NORMAL BEHAVIOR ", &
       "TANGENT BEHAVIOR", "NORMAL STIFFNESS", "TANGENT STIFFNES" /)

  CHARACTER(len=32), PARAMETER :: VALID_FRICTION_KEYWORDS(6) = &
    (/ "INTERACTION    ", "FRICTION MODEL ", "MU STATIC      ", &
       "MU KINETIC     ", "STICK SLIP     ", "DAMPING        " /)

  ! 关键字别名映射
  CHARACTER(len=32), PARAMETER :: ALIAS_SLAVE = "SLAVE"
  CHARACTER(len=32), PARAMETER :: ALIAS_MASTER = "MASTER"
  CHARACTER(len=32), PARAMETER :: ALIAS_MU_S = "MU_S"
  CHARACTER(len=32), PARAMETER :: ALIAS_MU_K = "MU_K"

CONTAINS

  !===============================================================================
  ! 工具函数：大小写转换
  !===============================================================================
  SUBROUTINE Convert_To_Upper(str)
    CHARACTER(len=*), INTENT(INOUT) :: str
    INTEGER(i4) :: i, ic
    
    DO i = 1, LEN_TRIM(str)
      ic = ICHAR(str(i:i))
      IF (ic >= ICHAR('a') .AND. ic <= ICHAR('z')) THEN
        str(i:i) = CHAR(ic - 32)
      END IF
    END DO
  END SUBROUTINE Convert_To_Upper

  !===============================================================================
  ! 工具函数：参数提取 (通用的 KEY=VALUE 解析)
  !===============================================================================
  LOGICAL FUNCTION Extract_Parameter_Value(line, param_name, value) RESULT(found)
    CHARACTER(len=*), INTENT(IN) :: line, param_name
    CHARACTER(len=*), INTENT(OUT) :: value
    INTEGER(i4) :: eq_pos, comma_pos, start_pos, end_pos, i
    CHARACTER(len=256) :: upper_line, upper_param

    value = ""
    found = .FALSE.

    ! 转换为大写用于查找
    upper_line = line
    upper_param = param_name
    CALL Convert_To_Upper(upper_line)
    CALL Convert_To_Upper(upper_param)

    ! 查找参数名
    start_pos = INDEX(upper_line, TRIM(upper_param))
    IF (start_pos == 0) RETURN

    ! 找到 "=" 符号
    eq_pos = INDEX(upper_line(start_pos:), "=")
    IF (eq_pos == 0) RETURN
    eq_pos = start_pos + eq_pos - 1

    ! 提取等号后的值
    start_pos = eq_pos + 1
    DO WHILE (start_pos <= LEN_TRIM(upper_line) .AND. &
              (upper_line(start_pos:start_pos) == ' ' .OR. &
               upper_line(start_pos:start_pos) == CHAR(9)))
      start_pos = start_pos + 1
    END DO

    ! 找到值的末尾（逗号或行末）
    comma_pos = INDEX(upper_line(start_pos:), ",")
    IF (comma_pos > 0) THEN
      end_pos = start_pos + comma_pos - 2
    ELSE
      end_pos = LEN_TRIM(upper_line)
    END IF

    ! 去除尾部空格
    DO WHILE (end_pos >= start_pos .AND. &
              (upper_line(end_pos:end_pos) == ' ' .OR. &
               upper_line(end_pos:end_pos) == CHAR(9)))
      end_pos = end_pos - 1
    END DO

    IF (end_pos >= start_pos) THEN
      value = ADJUSTL(line(start_pos:end_pos))
      found = .TRUE.
    END IF

  END FUNCTION Extract_Parameter_Value

  !===============================================================================
  ! 函数：检查关键字有效性
  !===============================================================================
  LOGICAL FUNCTION IsValidContactKeyword(keyword) RESULT(valid)
    CHARACTER(len=*), INTENT(IN) :: keyword
    INTEGER(i4) :: i
    CHARACTER(len=32) :: upper_kw

    valid = .FALSE.
    upper_kw = keyword
    CALL Convert_To_Upper(upper_kw)

    DO i = 1, SIZE(VALID_CONTACT_KEYWORDS)
      IF (INDEX(upper_kw, TRIM(VALID_CONTACT_KEYWORDS(i))) > 0) THEN
        valid = .TRUE.
        RETURN
      END IF
    END DO
  END FUNCTION IsValidContactKeyword

  !===============================================================================
  ! 子程序：解析 *CONTACT PAIR 块
  !===============================================================================
  SUBROUTINE MD_Parse_ContactPair(lines, num_lines, pair_name, slave_surf, &
                                   master_surf, contact_type, status)
    CHARACTER(len=*), INTENT(IN) :: lines(:)
    INTEGER(i4), INTENT(IN) :: num_lines
    CHARACTER(len=*), INTENT(OUT) :: pair_name, slave_surf, master_surf
    INTEGER(i4), INTENT(OUT) :: contact_type
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CHARACTER(len=256) :: upper_line, value
    INTEGER(i4) :: i
    LOGICAL :: found_pair_name

    status%status_code = 0
    pair_name = ""
    slave_surf = ""
    master_surf = ""
    contact_type = CONTACT_TYPE_S2S
    found_pair_name = .FALSE.

    ! 第一行是 *CONTACT PAIR, INTERACTION=name 格式
    DO i = 1, MIN(num_lines, 5)
      upper_line = lines(i)
      CALL Convert_To_Upper(upper_line)

      ! 检查是否为 CONTACT PAIR 关键字行
      IF (INDEX(upper_line, "*CONTACT PAIR") > 0) THEN
        IF (Extract_Parameter_Value(lines(i), "INTERACTION", value)) THEN
          pair_name = TRIM(value)
          found_pair_name = .TRUE.
        END IF

        ! 检查接触类型
        IF (Extract_Parameter_Value(lines(i), "TYPE", value)) THEN
          CALL Convert_To_Upper(value)
          IF (INDEX(value, "SURFACE-TO-SURFACE") > 0 .OR. &
              INDEX(value, "S2S") > 0) THEN
            contact_type = CONTACT_TYPE_S2S
          ELSE IF (INDEX(value, "POINT-TO-SURFACE") > 0 .OR. &
                   INDEX(value, "P2S") > 0) THEN
            contact_type = CONTACT_TYPE_P2S
          END IF
        END IF
      END IF

      ! 解析 SLAVE SURFACE 和 MASTER SURFACE 参数
      IF (INDEX(upper_line, "SLAVE SURFACE") > 0) THEN
        ! 下一行是从表面名称
        IF (i + 1 <= num_lines) THEN
          slave_surf = ADJUSTL(lines(i+1))
        END IF
      END IF

      IF (INDEX(upper_line, "MASTER SURFACE") > 0) THEN
        ! 下一行是主表面名称
        IF (i + 1 <= num_lines) THEN
          master_surf = ADJUSTL(lines(i+1))
        END IF
      END IF
    END DO

    ! 验证必需字段
    IF (.NOT. found_pair_name) THEN
      status%status_code = 1
      RETURN
    END IF

    IF (LEN_TRIM(slave_surf) == 0 .OR. LEN_TRIM(master_surf) == 0) THEN
      status%status_code = 1
      RETURN
    END IF

  END SUBROUTINE MD_Parse_ContactPair

  !===============================================================================
  ! 子程序：解析 *SURFACE INTERACTION 块
  !===============================================================================
  SUBROUTINE MD_Parse_SurfaceInteraction(lines, num_lines, interaction_name, &
                                         pair_name, normal_behavior, &
                                         normal_stiffness, status)
    CHARACTER(len=*), INTENT(IN) :: lines(:)
    INTEGER(i4), INTENT(IN) :: num_lines
    CHARACTER(len=*), INTENT(OUT) :: interaction_name, pair_name, normal_behavior
    REAL(wp), INTENT(OUT) :: normal_stiffness
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CHARACTER(len=256) :: upper_line, value
    INTEGER(i4) :: i
    LOGICAL :: found_name

    status%status_code = 0
    interaction_name = ""
    pair_name = ""
    normal_behavior = "HARD"
    normal_stiffness = 0.0_wp
    found_name = .FALSE.

    DO i = 1, MIN(num_lines, 10)
      upper_line = lines(i)
      CALL Convert_To_Upper(upper_line)

      ! 检查是否为 SURFACE INTERACTION 关键字行
      IF (INDEX(upper_line, "*SURFACE INTERACTION") > 0) THEN
        IF (Extract_Parameter_Value(lines(i), "NAME", value)) THEN
          interaction_name = TRIM(value)
          found_name = .TRUE.
        END IF
      END IF

      ! 解析 INTERACTION（即 CONTACT PAIR）参数
      IF (Extract_Parameter_Value(lines(i), "INTERACTION", value)) THEN
        pair_name = TRIM(value)
      END IF

      ! 解析法向行为
      IF (INDEX(upper_line, "*NORMAL BEHAVIOR") > 0) THEN
        IF (Extract_Parameter_Value(lines(i), "PRESSURE", value)) THEN
          CALL Convert_To_Upper(value)
          IF (INDEX(value, "EXPONENTIAL") > 0) THEN
            normal_behavior = "EXPONENTIAL"
          ELSE IF (INDEX(value, "LINEAR") > 0) THEN
            normal_behavior = "LINEAR"
          ELSE IF (INDEX(value, "HARD") > 0) THEN
            normal_behavior = "HARD"
          END IF
        END IF

        ! 提取法向刚度（如果存在）
        IF (Extract_Parameter_Value(lines(i), "STIFFNESS", value)) THEN
          READ(value, *, IOSTAT=status%status_code) normal_stiffness
          IF (status%status_code /= 0) normal_stiffness = 0.0_wp
        END IF
      END IF
    END DO

    IF (.NOT. found_name) THEN
      status%status_code = 1
      RETURN
    END IF

  END SUBROUTINE MD_Parse_SurfaceInteraction

  !===============================================================================
  ! 子程序：解析 *FRICTION 块
  !===============================================================================
  SUBROUTINE MD_Parse_Friction(lines, num_lines, friction_name, model_type, &
                                mu_static, mu_kinetic, status)
    CHARACTER(len=*), INTENT(IN) :: lines(:)
    INTEGER(i4), INTENT(IN) :: num_lines
    CHARACTER(len=*), INTENT(OUT) :: friction_name
    INTEGER(i4), INTENT(OUT) :: model_type
    REAL(wp), INTENT(OUT) :: mu_static, mu_kinetic
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CHARACTER(len=256) :: upper_line, value
    INTEGER(i4) :: i, stat_code
    LOGICAL :: found_name

    status%status_code = 0
    friction_name = ""
    model_type = FRICTION_COULOMB
    mu_static = 0.3_wp
    mu_kinetic = 0.2_wp
    found_name = .FALSE.

    DO i = 1, MIN(num_lines, 10)
      upper_line = lines(i)
      CALL Convert_To_Upper(upper_line)

      ! 检查是否为 FRICTION 关键字行
      IF (INDEX(upper_line, "*FRICTION") > 0) THEN
        IF (Extract_Parameter_Value(lines(i), "INTERACTION", value)) THEN
          friction_name = TRIM(value)
          found_name = .TRUE.
        END IF

        ! 检查摩擦模型类型
        IF (Extract_Parameter_Value(lines(i), "FORMULATION", value)) THEN
          CALL Convert_To_Upper(value)
          IF (INDEX(value, "PENALTY") > 0) THEN
            model_type = FRICTION_PENALTY
          ELSE IF (INDEX(value, "VISCOUS") > 0) THEN
            model_type = FRICTION_VISCOUS
          ELSE IF (INDEX(value, "COULOMB") > 0) THEN
            model_type = FRICTION_COULOMB
          END IF
        END IF
      END IF

      ! 解析摩擦系数
      IF (INDEX(upper_line, "*COULOMB FRICTION") > 0) THEN
        ! 下一行包含摩擦系数
        IF (i + 1 <= num_lines) THEN
          ! 第一个数字是摩擦系数
          READ(lines(i+1), *, IOSTAT=stat_code) mu_static
          IF (stat_code /= 0) mu_static = 0.3_wp
          mu_kinetic = mu_static * 0.8_wp  ! 假设动摩擦系数为静摩擦系数的 80%
        END IF
      END IF

      ! 解析单独的摩擦系数参数
      IF (Extract_Parameter_Value(lines(i), "MU", value)) THEN
        READ(value, *, IOSTAT=stat_code) mu_static
        IF (stat_code /= 0) mu_static = 0.3_wp
        mu_kinetic = mu_static * 0.8_wp
      END IF
    END DO

    IF (.NOT. found_name) THEN
      status%status_code = 1
      RETURN
    END IF

  END SUBROUTINE MD_Parse_Friction

  !===============================================================================
  ! 子程序：解析输出变量列表
  !===============================================================================
  SUBROUTINE MD_Parse_InteractionVariables(lines, num_lines, variables, num_vars, status)
    CHARACTER(len=*), INTENT(IN) :: lines(:)
    INTEGER(i4), INTENT(IN) :: num_lines
    CHARACTER(len=*), INTENT(OUT) :: variables(:)
    INTEGER(i4), INTENT(OUT) :: num_vars
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CHARACTER(len=256) :: upper_line
    INTEGER(i4) :: i, j, var_count
    CHARACTER(len=64) :: var_name

    status%status_code = 0
    num_vars = 0
    var_count = 0

    DO i = 1, MIN(num_lines, 20)
      upper_line = lines(i)
      CALL Convert_To_Upper(upper_line)

      ! 查找变量关键字行
      IF (INDEX(upper_line, "*NODE OUTPUT") > 0 .OR. &
          INDEX(upper_line, "*ELEMENT OUTPUT") > 0 .OR. &
          INDEX(upper_line, "*CONTACT OUTPUT") > 0) THEN

        ! 下一行开始是变量列表
        DO j = i+1, MIN(num_lines, i+15)
          var_name = ADJUSTL(lines(j))
          CALL Convert_To_Upper(var_name)

          IF (LEN_TRIM(var_name) > 0 .AND. INDEX(var_name, "*") == 0) THEN
            var_count = var_count + 1
            IF (var_count <= SIZE(variables)) THEN
              variables(var_count) = TRIM(var_name)
            END IF
          ELSE IF (INDEX(var_name, "*") > 0) THEN
            EXIT
          END IF
        END DO

        EXIT
      END IF
    END DO

    num_vars = var_count

  END SUBROUTINE MD_Parse_InteractionVariables

END MODULE MD_Int_Parser