!======================================================================
! MODULE:  MD_Hash_Table
! LAYER:   L3_MD
! DOMAIN:  Interaction
! ROLE:    Impl
! BRIEF:   String-to-integer hash table utility for surface
!          name queries.
! STATUS:  FOUR-TYPE-REFACTORED (B1 header)
! DATE:    2026-04-28
!======================================================================

MODULE MD_Hash_Table
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  !-------------------------------------------------------
  ! 公开接口
  !-------------------------------------------------------
  PUBLIC :: HashTableType
  PUBLIC :: HashTableEntry
  PUBLIC :: Init_HashTable
  PUBLIC :: Destroy_HashTable
  PUBLIC :: HashTable_Insert
  PUBLIC :: HashTable_Lookup
  PUBLIC :: HashTable_Remove
  PUBLIC :: HashTable_Clear
  PUBLIC :: HashTable_GetLoadFactor
  PUBLIC :: HashString
  PUBLIC :: IsEmpty_HashTable
  PUBLIC :: GetSize_HashTable

  !-------------------------------------------------------
  ! 常量定义
  !-------------------------------------------------------
  INTEGER(i4), PARAMETER :: DEFAULT_TABLE_SIZE = 32
  INTEGER(i4), PARAMETER :: MAX_KEY_LENGTH = 64
  REAL(wp), PARAMETER :: DEFAULT_LOAD_FACTOR = 0.7_wp
  INTEGER(i4), PARAMETER :: HASH_OK = 0
  INTEGER(i4), PARAMETER :: HASH_NOT_FOUND = -1
  INTEGER(i4), PARAMETER :: HASH_FULL = -2
  INTEGER(i4), PARAMETER :: HASH_DUPLICATE = -3

  !-------------------------------------------------------
  ! TYPE 定义
  !-------------------------------------------------------

  ! 哈希表条目
  TYPE :: HashTableEntry
    CHARACTER(len=MAX_KEY_LENGTH) :: key = ""
    INTEGER(i4) :: value = 0
    LOGICAL :: occupied = .FALSE.
    LOGICAL :: deleted = .FALSE.
  END TYPE HashTableEntry

  ! 哈希表容器
  TYPE :: HashTableType
    TYPE(HashTableEntry), ALLOCATABLE :: entries(:)
    INTEGER(i4) :: table_size = 0
    INTEGER(i4) :: num_entries = 0
    INTEGER(i4) :: num_active = 0
    REAL(wp) :: max_load_factor = DEFAULT_LOAD_FACTOR
  END TYPE HashTableType

CONTAINS

  !===============================================================================
  ! 函数: GetLoadFactor
  ! Purpose: 计算当前负载因子
  ! Note: 必须在 CONTAINS 内定义
  !===============================================================================
  REAL(wp) FUNCTION GetLoadFactor(table) RESULT(load_factor)
    TYPE(HashTableType), INTENT(IN) :: table

    IF (table%table_size == 0) THEN
      load_factor = 0.0_wp
    ELSE
      load_factor = REAL(table%num_active, wp) / REAL(table%table_size, wp)
    END IF

  END FUNCTION GetLoadFactor

  !===============================================================================
  ! 函数: HashTable_GetLoadFactor
  ! Purpose: 外部接口别名
  !===============================================================================
  REAL(wp) FUNCTION HashTable_GetLoadFactor(table) RESULT(load_factor)
    TYPE(HashTableType), INTENT(IN) :: table

    load_factor = GetLoadFactor(table)

  END FUNCTION HashTable_GetLoadFactor

  !===============================================================================
  ! 函数: HashString
  ! Purpose: djb2 哈希函数 (Daniel J. Bernstein)
  ! Input:  key - 输入字符串
  ! Output: 哈希值 (正整数)
  !===============================================================================
  INTEGER(i4) FUNCTION HashString(key) RESULT(hash)
    CHARACTER(len=*), INTENT(IN) :: key

    INTEGER(i4) :: i
    CHARACTER(len=1) :: c

    hash = 5381

    DO i = 1, LEN_TRIM(key)
      c = key(i:i)
      hash = Ishft(hash, 5) + hash + ICHAR(c)  ! hash * 33 + c
    END DO

    ! 确保非负
    IF (hash < 0) hash = -hash

  END FUNCTION HashString

  !===============================================================================
  ! 子程序: Init_HashTable
  ! Purpose: 初始化哈希表
  !===============================================================================
  SUBROUTINE Init_HashTable(table, initial_size, max_load, status)
    TYPE(HashTableType), INTENT(INOUT) :: table
    INTEGER(i4), INTENT(IN), OPTIONAL :: initial_size
    REAL(wp), INTENT(IN), OPTIONAL :: max_load
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: alloc_stat

    status%status_code = 0

    ! 设置表大小
    IF (PRESENT(initial_size)) THEN
      table%table_size = initial_size
    ELSE
      table%table_size = DEFAULT_TABLE_SIZE
    END IF

    ! 确保表大小为 2 的幂次 (利于取模)
    table%table_size = NextPowerOfTwo(table%table_size)

    ! 设置最大负载因子
    IF (PRESENT(max_load)) THEN
      table%max_load_factor = max_load
    ELSE
      table%max_load_factor = DEFAULT_LOAD_FACTOR
    END IF

    ! 分配条目数组
    IF (ALLOCATED(table%entries)) DEALLOCATE(table%entries)
    ALLOCATE(table%entries(table%table_size), STAT=alloc_stat)

    IF (alloc_stat /= 0) THEN
      status%status_code = 1
      RETURN
    END IF

    ! 初始化所有条目
    table%entries%occupied = .FALSE.
    table%entries%deleted = .FALSE.
    table%entries%key = ""
    table%entries%value = 0

    table%num_entries = 0
    table%num_active = 0

  END SUBROUTINE Init_HashTable

  !===============================================================================
  ! 子程序: Destroy_HashTable
  ! Purpose: 销毁哈希表，释放内存
  !===============================================================================
  SUBROUTINE Destroy_HashTable(table, status)
    TYPE(HashTableType), INTENT(INOUT) :: table
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    status%status_code = 0

    IF (ALLOCATED(table%entries)) THEN
      DEALLOCATE(table%entries)
    END IF

    table%table_size = 0
    table%num_entries = 0
    table%num_active = 0

  END SUBROUTINE Destroy_HashTable

  !===============================================================================
  ! 子程序: HashTable_Insert
  ! Purpose: 向哈希表插入键值对
  !===============================================================================
  SUBROUTINE HashTable_Insert(table, key, value, status)
    TYPE(HashTableType), INTENT(INOUT) :: table
    CHARACTER(len=*), INTENT(IN) :: key
    INTEGER(i4), INTENT(IN) :: value
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: hash, index, probe_count
    LOGICAL :: inserted

    status%status_code = HASH_OK

    ! 检查负载因子
    IF (GetLoadFactor(table) > table%max_load_factor) THEN
      ! 需要扩容
      CALL Resize_HashTable(table, table%table_size * 2, status)
      IF (status%status_code /= 0) THEN
        status%status_code = HASH_FULL
        RETURN
      END IF
    END IF

    hash = MOD(HashString(key), table%table_size)
    inserted = .FALSE.

    ! 线性探测寻找空位
    DO probe_count = 0, table%table_size - 1
      index = MOD(hash + probe_count, table%table_size)

      IF (.NOT. table%entries(index)%occupied) THEN
        ! 找到空位，插入
        table%entries(index)%key = TRIM(key)
        table%entries(index)%value = value
        table%entries(index)%occupied = .TRUE.
        table%entries(index)%deleted = .FALSE.
        table%num_entries = table%num_entries + 1
        table%num_active = table%num_active + 1
        inserted = .TRUE.
        EXIT

      ELSE IF (TRIM(table%entries(index)%key) == TRIM(key) .AND. &
               .NOT. table%entries(index)%deleted) THEN
        ! 键已存在，更新值
        table%entries(index)%value = value
        inserted = .TRUE.
        EXIT
      END IF
    END DO

    IF (.NOT. inserted) THEN
      status%status_code = HASH_FULL
    END IF

  END SUBROUTINE HashTable_Insert

  !===============================================================================
  ! 子程序: HashTable_Lookup
  ! Purpose: 在哈希表中查找键对应的值
  !===============================================================================
  SUBROUTINE HashTable_Lookup(table, key, value, found, status)
    TYPE(HashTableType), INTENT(IN) :: table
    CHARACTER(len=*), INTENT(IN) :: key
    INTEGER(i4), INTENT(OUT) :: value
    LOGICAL, INTENT(OUT) :: found
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: hash, index, probe_count

    status%status_code = HASH_OK
    found = .FALSE.
    value = 0

    hash = MOD(HashString(key), table%table_size)

    DO probe_count = 0, table%table_size - 1
      index = MOD(hash + probe_count, table%table_size)

      IF (.NOT. table%entries(index)%occupied) THEN
        ! 遇到空位，键不存在
        EXIT

      ELSE IF (.NOT. table%entries(index)%deleted) THEN
        IF (TRIM(table%entries(index)%key) == TRIM(key)) THEN
          found = .TRUE.
          value = table%entries(index)%value
          EXIT
        END IF
      END IF
    END DO

    IF (.NOT. found) THEN
      status%status_code = HASH_NOT_FOUND
    END IF

  END SUBROUTINE HashTable_Lookup

  !===============================================================================
  ! 子程序: HashTable_Remove
  ! Purpose: 从哈希表中删除键值对
  !===============================================================================
  SUBROUTINE HashTable_Remove(table, key, status)
    TYPE(HashTableType), INTENT(INOUT) :: table
    CHARACTER(len=*), INTENT(IN) :: key
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: hash, index, probe_count
    LOGICAL :: found

    status%status_code = HASH_OK
    found = .FALSE.

    hash = MOD(HashString(key), table%table_size)

    DO probe_count = 0, table%table_size - 1
      index = MOD(hash + probe_count, table%table_size)

      IF (.NOT. table%entries(index)%occupied) THEN
        EXIT

      ELSE IF (.NOT. table%entries(index)%deleted) THEN
        IF (TRIM(table%entries(index)%key) == TRIM(key)) THEN
          table%entries(index)%deleted = .TRUE.
          table%num_active = table%num_active - 1
          found = .TRUE.
          EXIT
        END IF
      END IF
    END DO

    IF (.NOT. found) THEN
      status%status_code = HASH_NOT_FOUND
    END IF

  END SUBROUTINE HashTable_Remove

  !===============================================================================
  ! 子程序: HashTable_Clear
  ! Purpose: 清空哈希表
  !===============================================================================
  SUBROUTINE HashTable_Clear(table, status)
    TYPE(HashTableType), INTENT(INOUT) :: table
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    status%status_code = 0

    IF (ALLOCATED(table%entries)) THEN
      table%entries%occupied = .FALSE.
      table%entries%deleted = .FALSE.
    END IF

    table%num_entries = 0
    table%num_active = 0

  END SUBROUTINE HashTable_Clear

  !===============================================================================
  ! 函数: IsEmpty_HashTable
  ! Purpose: 检查哈希表是否为空
  !===============================================================================
  LOGICAL FUNCTION IsEmpty_HashTable(table) RESULT(is_empty)
    TYPE(HashTableType), INTENT(IN) :: table

    is_empty = (table%num_active == 0)

  END FUNCTION IsEmpty_HashTable

  !===============================================================================
  ! 函数: GetSize_HashTable
  ! Purpose: 获取哈希表大小
  !===============================================================================
  INTEGER(i4) FUNCTION GetSize_HashTable(table) RESULT(size)
    TYPE(HashTableType), INTENT(IN) :: table

    size = table%num_active

  END FUNCTION GetSize_HashTable

  !===============================================================================
  ! 内部函数: NextPowerOfTwo
  ! Purpose: 计算不小于 n 的最小 2 的幂次
  !===============================================================================
  INTEGER(i4) FUNCTION NextPowerOfTwo(n) RESULT(pow2)
    INTEGER(i4), INTENT(IN) :: n

    INTEGER(i4) :: x

    x = n - 1
    x = IOR(x, ISHFT(x, -1))
    x = IOR(x, ISHFT(x, -2))
    x = IOR(x, ISHFT(x, -4))
    x = IOR(x, ISHFT(x, -8))
    x = IOR(x, ISHFT(x, -16))
    x = IOR(x, ISHFT(x, -32))
    pow2 = x + 1

  END FUNCTION NextPowerOfTwo

  !===============================================================================
  ! 内部子程序: Resize_HashTable
  ! Purpose: 调整哈希表大小
  !===============================================================================
  SUBROUTINE Resize_HashTable(table, new_size, status)
    TYPE(HashTableType), INTENT(INOUT) :: table
    INTEGER(i4), INTENT(IN) :: new_size
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(HashTableEntry), ALLOCATABLE :: temp_entries(:)
    INTEGER(i4) :: old_size, i, alloc_stat

    status%status_code = 0
    old_size = table%table_size

    ! 保存旧条目到临时数组
    IF (ALLOCATED(table%entries)) THEN
      ALLOCATE(temp_entries(old_size), STAT=alloc_stat)
      IF (alloc_stat /= 0) THEN
        status%status_code = 1
        RETURN
      END IF
      temp_entries = table%entries
    END IF

    ! 重新分配新条目
    DEALLOCATE(table%entries)
    ALLOCATE(table%entries(new_size), STAT=alloc_stat)
    IF (alloc_stat /= 0) THEN
      status%status_code = 1
      IF (ALLOCATED(temp_entries)) DEALLOCATE(temp_entries)
      RETURN
    END IF

    ! 初始化新条目
    table%entries%occupied = .FALSE.
    table%entries%deleted = .FALSE.
    table%entries%key = ""
    table%entries%value = 0

    ! 更新表大小
    table%table_size = new_size
    table%num_entries = 0
    table%num_active = 0

    ! 重新插入所有有效条目
    IF (ALLOCATED(temp_entries)) THEN
      DO i = 1, old_size
        IF (temp_entries(i)%occupied .AND. .NOT. temp_entries(i)%deleted) THEN
          CALL HashTable_Insert(table, temp_entries(i)%key, temp_entries(i)%value, status)
          IF (status%status_code /= 0) THEN
            DEALLOCATE(temp_entries)
            RETURN
          END IF
        END IF
      END DO
      DEALLOCATE(temp_entries)
    END IF

  END SUBROUTINE Resize_HashTable

END MODULE MD_Hash_Table