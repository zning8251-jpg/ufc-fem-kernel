# `IF_Mem_Serial.f90`

- **Source**: `L1_IF/Memory/IF_Mem_Serial.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `IF_Mem_Serial`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_Mem_Serial`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_Mem_Serial`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Memory`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Memory/IF_Mem_Serial.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `SerializationFormatType` (lines 35–43)

```fortran
    TYPE :: SerializationFormatType
        PRIVATE
        INTEGER(i4) :: format_id = 0
        CHARACTER(LEN=20) :: format_name = ""
        CHARACTER(LEN=50) :: file_extension = ""
        LOGICAL :: is_binary = .TRUE.
        LOGICAL :: supports_compression = .FALSE.
        LOGICAL :: supports_versioning = .FALSE.
    END TYPE SerializationFormatType
```

### `SerializationManagerType` (lines 48–81)

```fortran
    TYPE :: SerializationManagerType
        PRIVATE
        ! Supported formats registry
        TYPE(SerializationFormatType), ALLOCATABLE :: formats(:)
        INTEGER(i4) :: num_formats = 0
        INTEGER(i4) :: default_format = 1
        
        ! Compression settings
        LOGICAL :: compression_enabled = .TRUE.
        INTEGER(i4) :: compression_level = 6  ! 1-9
        CHARACTER(LEN=20) :: compression_algorithm = "ZLIB"
        
        ! Version management
        LOGICAL :: versioning_enabled = .TRUE.
        INTEGER(i4) :: current_version = 1
        INTEGER(i4) :: min_compatible_version = 1
        
        ! Data integrity
        LOGICAL :: checksum_enabled = .TRUE.
        CHARACTER(LEN=20) :: checksum_algorithm = "CRC32"
        
        ! Performance settings
        INTEGER(i4) :: buffer_size = 8192  ! bytes
        LOGICAL :: buffered_io = .TRUE.
        
    CONTAINS
        PROCEDURE :: Init
        PROCEDURE :: RegisterFormat
        PROCEDURE :: Serialize
        PROCEDURE :: Deserialize
        PROCEDURE :: Valid
        PROCEDURE :: GetFormatInfo
        PROCEDURE :: Finalize
    END TYPE SerializationManagerType
```

### `SerializationContextType` (lines 86–95)

```fortran
    TYPE :: SerializationContextType
        PRIVATE
        TYPE(SerializationFormatType) :: format
        INTEGER(i4) :: version = 1
        LOGICAL :: write_mode = .TRUE.
        INTEGER(i4) :: buffer_position = 0
        CHARACTER(LEN=:), ALLOCATABLE :: buffer
        INTEGER(i8) :: bytes_processed = 0_i8
        LOGICAL :: compression_active = .FALSE.
    END TYPE SerializationContextType
```

### `SerializableType` (lines 100–109)

```fortran
    TYPE, ABSTRACT :: SerializableType
        PRIVATE
        INTEGER(i4) :: object_id = 0
        CHARACTER(LEN=50) :: class_name = ""
        INTEGER(i4) :: serialization_version = 1
    CONTAINS
        PROCEDURE(SerializeInterface), DEFERRED :: SerializeData
        PROCEDURE(DeserializeInterface), DEFERRED :: DeserializeData
        PROCEDURE(GetSizeInterface), DEFERRED :: GetSerializedSize
    END TYPE SerializableType
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `SerializeInterface` | 115 | `SUBROUTINE SerializeInterface(this, context, status)` |
| SUBROUTINE | `DeserializeInterface` | 124 | `SUBROUTINE DeserializeInterface(this, context, status)` |
| FUNCTION | `GetSizeInterface` | 133 | `FUNCTION GetSizeInterface(this, format) RESULT(size)` |
| SUBROUTINE | `IF_Serial_Init` | 163 | `SUBROUTINE IF_Serial_Init(manager, default_format, status)` |
| SUBROUTINE | `IF_Serial_Finalize` | 201 | `SUBROUTINE IF_Serial_Finalize(manager, status)` |
| FUNCTION | `IF_Serial_Get_SuppFmts` | 220 | `FUNCTION IF_Serial_Get_SuppFmts() RESULT(formats)` |
| SUBROUTINE | `Init` | 237 | `SUBROUTINE Init(this, default_format, status)` |
| SUBROUTINE | `RegisterFormat` | 247 | `SUBROUTINE RegisterFormat(this, format, status)` |
| SUBROUTINE | `Serialize` | 288 | `SUBROUTINE Serialize(this, object, filename, format_name, &` |
| SUBROUTINE | `Deserialize` | 340 | `SUBROUTINE Deserialize(this, object, filename, format_name, &` |
| SUBROUTINE | `Valid` | 400 | `SUBROUTINE Valid(this, filename, format_name, status)` |
| SUBROUTINE | `GetFormatInfo` | 441 | `SUBROUTINE GetFormatInfo(this, format_name, info, status)` |
| SUBROUTINE | `Finalize` | 464 | `SUBROUTINE Finalize(this, status)` |
| SUBROUTINE | `InitializeSerializationContext` | 477 | `SUBROUTINE InitializeSerializationContext(context, format, write_mode, status)` |
| SUBROUTINE | `CleanupSerializationContext` | 502 | `SUBROUTINE CleanupSerializationContext(context)` |
| SUBROUTINE | `WriteSerializedData` | 519 | `SUBROUTINE WriteSerializedData(filename, context, status)` |
| SUBROUTINE | `ReadSerializedData` | 559 | `SUBROUTINE ReadSerializedData(filename, context, status)` |
| SUBROUTINE | `ValidateSerializedData` | 606 | `SUBROUTINE ValidateSerializedData(context, status)` |
| SUBROUTINE | `ValidateBinaryData` | 629 | `SUBROUTINE ValidateBinaryData(context, status)` |
| SUBROUTINE | `ValidateTextData` | 641 | `SUBROUTINE ValidateTextData(context, status)` |
| SUBROUTINE | `InitializeStandardFormats` | 657 | `SUBROUTINE InitializeStandardFormats(manager)` |
| FUNCTION | `IsFormatRegistered` | 675 | `FUNCTION IsFormatRegistered(manager, format_name) RESULT(registered)` |
| FUNCTION | `FindFormatId` | 693 | `FUNCTION FindFormatId(manager, format_name) RESULT(format_id)` |
| FUNCTION | `DetectFileFormat` | 711 | `FUNCTION DetectFileFormat(filename) RESULT(format)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
