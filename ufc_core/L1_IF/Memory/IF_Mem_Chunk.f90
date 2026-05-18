!===============================================================================
! MODULE: IF_Mem_Chunk
! LAYER:  L1_IF
! DOMAIN: Memory
! ROLE:   Impl — chunk metadata and registry for file sharding
! BRIEF:  Init / Clear / Register / Get-by-logical-id; GCM_MAX_CHUNKS.
!===============================================================================

MODULE IF_Mem_Chunk
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
        IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_NOT_FOUND
    USE IF_Prec_Core, ONLY: i8
    IMPLICIT NONE
    PRIVATE

    PUBLIC :: IF_Chunk_Max_Chunks
    PUBLIC :: IF_Chunk_Init, IF_Chunk_Clear, IF_Chunk_Register, IF_Chunk_Get
    PUBLIC :: GCM_MAX_CHUNKS
    PUBLIC :: gcm_init, gcm_clear, gcm_register_chunk, gcm_get_chunks

    INTEGER(i4), PARAMETER :: IF_Chunk_Max_Chunks = 4096
    INTEGER(i4), PARAMETER :: GCM_MAX_CHUNKS = IF_Chunk_Max_Chunks

    TYPE, PUBLIC :: ChunkMeta_Type
        CHARACTER(LEN=64)  :: logical_id  = ""
        CHARACTER(LEN=256) :: file_path   = ""
        INTEGER(i4) :: chunk_id    = 0
        INTEGER(KIND=8)    :: file_offset = 0_8
        INTEGER(KIND=8)    :: chunk_size  = 0_8
        INTEGER(i4) :: node_id     = 0
        LOGICAL            :: is_valid    = .FALSE.
    END TYPE ChunkMeta_Type
    ! Legacy name: same shape as ChunkMeta_Type (use ChunkMeta_Type in new code)
    TYPE, PUBLIC :: GenericChunkMetaType
        CHARACTER(LEN=64)  :: logical_id  = ""
        CHARACTER(LEN=256) :: file_path   = ""
        INTEGER(i4) :: chunk_id    = 0
        INTEGER(KIND=8)    :: file_offset = 0_8
        INTEGER(KIND=8)    :: chunk_size  = 0_8
        INTEGER(i4) :: node_id     = 0
        LOGICAL            :: is_valid    = .FALSE.
    END TYPE GenericChunkMetaType

    TYPE(ChunkMeta_Type), SAVE :: chunk_table(IF_Chunk_Max_Chunks)
    INTEGER, SAVE :: chunk_count = 0

CONTAINS

    SUBROUTINE IF_Chunk_Init(status)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL IF_Chunk_Clear(status)
        status%status_code = IF_STATUS_OK
    END SUBROUTINE IF_Chunk_Init

    SUBROUTINE IF_Chunk_Clear(status)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i
        CALL init_error_status(status)
        DO i = 1, IF_Chunk_Max_Chunks
            chunk_table(i)%logical_id  = ""
            chunk_table(i)%file_path   = ""
            chunk_table(i)%chunk_id    = 0
            chunk_table(i)%file_offset = 0_8
            chunk_table(i)%chunk_size  = 0_8
            chunk_table(i)%node_id     = 0
            chunk_table(i)%is_valid    = .FALSE.
        END DO
        chunk_count = 0
        status%status_code = IF_STATUS_OK
    END SUBROUTINE IF_Chunk_Clear

    SUBROUTINE IF_Chunk_Register(meta, status)
        TYPE(ChunkMeta_Type), INTENT(IN) :: meta
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: idx
        CALL init_error_status(status)
        IF (chunk_count >= IF_Chunk_Max_Chunks) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "IF_Chunk_Register: registry full"
            RETURN
        END IF
        idx = chunk_count + 1
        chunk_table(idx) = meta
        chunk_table(idx)%is_valid = .TRUE.
        chunk_count = idx
        status%status_code = IF_STATUS_OK
    END SUBROUTINE IF_Chunk_Register

    SUBROUTINE IF_Chunk_Get(logical_id, chunks, num_chunks, status)
        CHARACTER(LEN=*), INTENT(IN)  :: logical_id
        TYPE(ChunkMeta_Type), ALLOCATABLE, INTENT(OUT) :: chunks(:)
        INTEGER(i4), INTENT(OUT) :: num_chunks
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, count
        CALL init_error_status(status)
        num_chunks = 0
        count      = 0
        IF (chunk_count <= 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "IF_Chunk_Get: no chunks registered"
            RETURN
        END IF
        DO i = 1, chunk_count
            IF (chunk_table(i)%is_valid) THEN
                IF (TRIM(chunk_table(i)%logical_id) == TRIM(logical_id)) count = count + 1
            END IF
        END DO
        IF (count == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "IF_Chunk_Get: no chunks for logical_id='"//TRIM(logical_id)//"'"
            RETURN
        END IF
        IF (ALLOCATED(chunks)) DEALLOCATE(chunks)
        ALLOCATE(chunks(count))
        num_chunks = 0
        DO i = 1, chunk_count
            IF (chunk_table(i)%is_valid) THEN
                IF (TRIM(chunk_table(i)%logical_id) == TRIM(logical_id)) THEN
                    num_chunks = num_chunks + 1
                    chunks(num_chunks) = chunk_table(i)
                END IF
            END IF
        END DO
        status%status_code = IF_STATUS_OK
    END SUBROUTINE IF_Chunk_Get

    ! Legacy wrappers
    SUBROUTINE gcm_init(status)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL IF_Chunk_Init(status)
    END SUBROUTINE gcm_init
    SUBROUTINE gcm_clear(status)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL IF_Chunk_Clear(status)
    END SUBROUTINE gcm_clear
    SUBROUTINE gcm_register_chunk(meta, status)
        TYPE(GenericChunkMetaType), INTENT(IN) :: meta
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        TYPE(ChunkMeta_Type) :: m
        m%logical_id = meta%logical_id
        m%file_path = meta%file_path
        m%chunk_id = meta%chunk_id
        m%file_offset = meta%file_offset
        m%chunk_size = meta%chunk_size
        m%node_id = meta%node_id
        m%is_valid = meta%is_valid
        CALL IF_Chunk_Register(m, status)
    END SUBROUTINE gcm_register_chunk
    SUBROUTINE gcm_get_chunks(logical_id, chunks, num_chunks, status)
        CHARACTER(LEN=*), INTENT(IN)  :: logical_id
        TYPE(GenericChunkMetaType), ALLOCATABLE, INTENT(OUT) :: chunks(:)
        INTEGER(i4), INTENT(OUT) :: num_chunks
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        TYPE(ChunkMeta_Type), ALLOCATABLE :: c(:)
        INTEGER(i4) :: i
        CALL IF_Chunk_Get(logical_id, c, num_chunks, status)
        IF (status%status_code == IF_STATUS_OK .AND. num_chunks > 0) THEN
            ALLOCATE(chunks(num_chunks))
            DO i = 1, num_chunks
                chunks(i)%logical_id = c(i)%logical_id
                chunks(i)%file_path = c(i)%file_path
                chunks(i)%chunk_id = c(i)%chunk_id
                chunks(i)%file_offset = c(i)%file_offset
                chunks(i)%chunk_size = c(i)%chunk_size
                chunks(i)%node_id = c(i)%node_id
                chunks(i)%is_valid = c(i)%is_valid
            END DO
        END IF
    END SUBROUTINE gcm_get_chunks

END MODULE IF_Mem_Chunk