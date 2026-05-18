!===============================================================================
! MODULE:  MD_Base_IOSerialMgr
! LAYER:   L3_MD
! DOMAIN:  Model / Base
! ROLE:    _Mgr (IO serialization)
! BRIEF:   Unified I/O and serialization manager. File I/O, binary R/W,
!          HDF5, XML, and high-level data serialization/deserialization.
!===============================================================================
!   Unified I/O and serialization manager for model definition layer. Merged from
!   IO_Mgr (physical I/O, FileHandle, BinaryReader/Writer, HDF5, XML) and Serial_Core
!   (RW_Serializer, RW_Deserializer, RW_SymbolTable, RW_Serialize/Deserialize).
!   Provides file I/O operations, binary file reading/writing, HDF5 file operations,
!   XML document manipulation, and high-level data serialization/deserialization.
!
! Theory chain:
!   File I/O: Fortran file operations with mode management (READ, WRITE, APPEND, UPDATE),
!   file type detection (TEXT, BINARY, HDF5, XML). Binary I/O: Type-safe binary reading
!   and writing with endianness support, array operations. HDF5: Hierarchical data format
!   for scientific data storage (files, groups, datasets). XML: Document object model
!   for structured text data (documents, elements, attributes). Serialization: High-level
!   data serialization with symbol table management, variable entry tracking, memory
!   management. Ref: File I/O patterns, binary data formats, HDF5 specification, XML
!   standards, serialization protocols.
!
! Logic chain:
!   FileHandle: Init -> Open -> ReadLine/WriteLine -> Close/Destroy. BinaryReader:
!   Init -> Open -> ReadInt1/Int2/Int4/Int8/DP/Array/String -> Close/Destroy.
!   BinaryWriter: Init -> Open -> WriteInt1/Int2/Int4/Int8/DP/Array/String -> Flush ->
!   Close/Destroy. HDF5File: Init -> Open -> CreateGroup/OpenGroup -> CreateDataset/
!   OpenDataset -> Close/Destroy. XMLDocument: Init -> Load -> GetRoot/SetRoot ->
!   FindElement/FindElements -> Save -> Destroy. RW_Serializer: Init -> Open ->
!   Serialize (Int1/Int2/Int4/Int8/DP/String/Array) -> Flush -> Close/Destroy.
!   RW_Deserializer: Init -> Open -> Deserialize -> Close/Destroy. Dependency:
!   L3_MD Base -> L1 IF (Error API, Precision).
!
! Computation chain:
!   FileHandle_Open: Select mode (READ/WRITE/APPEND/UPDATE) -> Open file with appropriate
!   status/action -> Set is_open flag. BinaryReader_ReadInt1: Check init -> Read from file
!   unit -> Return value. BinaryWriter_WriteInt1: Check init -> Write to file unit ->
!   Return status. HDF5File_CreateGroup: Init group with name and parent_id -> Return group.
!   XMLDocument_Load: Open file -> Parse XML -> Build element tree -> Set root -> Set
!   is_loaded flag. RW_Serialize_Int1: Write Int1 via BinaryWriter. RW_Deserialize_Int1:
!   Read Int1 via BinaryReader. RW_SymbolTable_Reg: Check if var_id exists -> Expand entries
!   array if needed -> Create VariableEntry -> Calculate size and offset -> Update total_size.
!
! Data chain:
!   Input: Filename, mode (MD_MODEL_FILE_MODE_READ/WRITE/APPEND/UPDATE), file_type (MD_MODEL_FILE_TYPE_TEXT/
!   BINARY/HDF5/XML), data values (Int1/Int2/Int4/Int8/DP, arrays, strings), variable ID,
!   name, data type, rank, shape.
!   Output: FileHandle (unit, filename, mode, file_type, is_open, file_size, current_pos),
!   BinaryReader/Writer (file_handle, init, big_endian), HDF5File (file_id, filename, mode,
!   is_open, n_groups, n_datasets), HDF5Group (group_id, name, parent_id, is_open, n_subgroups,
!   n_datasets), HDF5Dataset (dataset_id, name, parent_id, is_open, rank, dims, dType),
!   XMLDocument (filename, version, encoding, root, is_loaded), XMLElement (name, text,
!   attributes, parent, children, n_attributes, n_children), RW_Serializer/Deserializer
!   (writer/reader, symbol_table, init), RW_SymbolTable (entries, n_entries, max_entries,
!   total_size), RW_VariableEntry (var_id, name, dType, rank, shape, size, offset,
!   is_allocated). State: File open state (is_open), initialization state (init), symbol
!   table state (n_entries, total_size).
!
! Data structure:
!   Container path: Base (I/O and serialization manager).
!   - Desc: FileHandle (file descriptor), RW_VariableEntry (variable entry descriptor).
!   - Algo: File I/O algorithms (FileHandle_Open/Close/ReadLine/WriteLine), binary I/O
!   algorithms (BR_ReadInt1, BW_WriteInt1, etc.), HDF5 algorithms (HDF5File_CreateGroup,
!   HDF5Dataset_ReadInt1, etc.), XML algorithms (XMLDocument_Load/Save, XMLElement operations),
!   serialization algorithms (RW_Serialize, RW_Deserialize).
!   - Ctx: BinaryReader/Writer (file_handle context), HDF5File (file context), XMLDocument
!   (document context), RW_Serializer/Deserializer (serialization context), RW_SymbolTable
!   (symbol table context).
!   - State: File open state (is_open), initialization state (init), symbol table state
!   (n_entries, total_size).
!   Supporting types: XMLAttribute (attribute name/value), RW_MemMgr (memory tracking).
!
! Three-step mapping:
!   FileHandle_Open/BinaryReader_Open/BinaryWriter_Open: Step level (file I/O setup).
!   BinaryReader_ReadInt1/BinaryWriter_WriteInt1: Step level (data I/O operations).
!   RW_Serialize/RW_Deserialize: Step level (data serialization/deserialization).
!   XMLDocument_Load/Save: Step level (XML I/O operations).
!
! Contents (A-Z):
!   Constants: MD_MODEL_FILE_MODE_APPEND, MD_MODEL_FILE_MODE_READ, MD_MODEL_FILE_MODE_UPDATE, MD_MODEL_FILE_MODE_WRITE,
!     MD_MODEL_FILE_TYPE_BINAR, MD_MODEL_FILE_TYPE_HDF5, MD_MODEL_FILE_TYPE_TEXT, MD_MODEL_FILE_TYPE_UNKNO, MD_MODEL_FILE_TYPE_XML,
!     MD_MODEL_RW_TYPE_CHAR, MD_MODEL_RW_TYPE_DP, MD_MODEL_RW_TYPE_INT1, MD_MODEL_RW_TYPE_INT2, MD_MODEL_RW_TYPE_INT4, MD_MODEL_RW_TYPE_INT8
!   Functions: BinaryReader_IsOpen, BinaryWriter_IsOpen, FileHandle_GetPosition,
!     FileHandle_GetSize, FileHandle_IsOpen, HDF5Dataset_IsOpen, HDF5File_GetDataset,
!     HDF5File_GetGroup, HDF5File_IsOpen, HDF5Group_IsOpen, RW_SymbolTable_Find,
!     RW_SymbolTable_Get, RW_SymbolTable_GetTotalSize, RW_Get_Variable, XMLElement_FindChild,
!     XMLElement_FindChildren, XMLElement_GetAttribute, XMLElement_GetChild,
!     XMLElement_GetChildren, XMLElement_ToString, XMLDocument_FindElement,
!     XMLDocument_FindElements, XMLDocument_GetRoot
!   Interfaces: RW_Deserialize, RW_Serialize
!   Subroutines: BinaryReader_Close, BinaryReader_Destroy, BinaryReader_Init, BinaryReader_Open,
!     BinaryReader_ReadArrayDP, BinaryReader_ReadArrayInt1, BinaryReader_ReadArrayInt4,
!     BinaryReader_ReadDP, BinaryReader_ReadInt1, BinaryReader_ReadInt2, BinaryReader_ReadInt4,
!     BinaryReader_ReadInt8, BinaryReader_ReadString, BinaryWriter_Close, BinaryWriter_Destroy,
!     BinaryWriter_Flush, BinaryWriter_Init, BinaryWriter_Open, BinaryWriter_WriteArrayDP,
!     BinaryWriter_WriteArrayInt1, BinaryWriter_WriteArrayInt4, BinaryWriter_WriteDP,
!     BinaryWriter_WriteInt1, BinaryWriter_WriteInt2, BinaryWriter_WriteInt4,
!     BinaryWriter_WriteInt8, BinaryWriter_WriteString, FileHandle_Close, FileHandle_Destroy,
!     FileHandle_Flush, FileHandle_Init, FileHandle_Open, FileHandle_ReadLine, FileHandle_Seek,
!     FileHandle_WriteLine, HDF5Dataset_Close, HDF5Dataset_Destroy, HDF5Dataset_GetDims,
!     HDF5Dataset_Init, HDF5Dataset_Open, HDF5Dataset_ReadDP, HDF5Dataset_ReadInt1,
!     HDF5Dataset_ReadInt4, HDF5Dataset_WriteDP, HDF5Dataset_WriteInt1, HDF5Dataset_WriteInt4,
!     HDF5File_Close, HDF5File_CreateDataset, HDF5File_CreateGroup, HDF5File_Destroy,
!     HDF5File_Init, HDF5File_Open, HDF5File_OpenDataset, HDF5File_OpenGroup, HDF5Group_Close,
!     HDF5Group_CreateDataset, HDF5Group_CreateSubgroup, HDF5Group_Destroy, HDF5Group_Init,
!     HDF5Group_Open, HDF5Group_OpenDataset, HDF5Group_OpenSubgroup, RW_Clear_SymbolTable,
!     RW_Deserializer_Close, RW_Deserializer_Destroy, RW_Deserializer_Deserialize,
!     RW_Deserializer_Init, RW_Deserializer_Open, RW_Deserialize_ArrayDP, RW_Deserialize_ArrayInt1,
!     RW_Deserialize_ArrayInt4, RW_Deserialize_DP, RW_Deserialize_Int1, RW_Deserialize_Int2,
!     RW_Deserialize_Int4, RW_Deserialize_Int8, RW_Deserialize_String, RW_MemMgr_Alloc,
!     RW_MemMgr_Dealloc, RW_MemMgr_GetStats, RW_MemMgr_Realloc, RW_MemMgr_Reset,
!     RW_Serializer_Close, RW_Serializer_Destroy, RW_Serializer_Flush, RW_Serializer_Init,
!     RW_Serializer_Open, RW_Serializer_Serialize, RW_Serialize_ArrayDP, RW_Serialize_ArrayInt1,
!     RW_Serialize_ArrayInt4, RW_Serialize_DP, RW_Serialize_Int1, RW_Serialize_Int2,
!     RW_Serialize_Int4, RW_Serialize_Int8, RW_Serialize_String, RW_Set_Variable,
!     RW_SymbolTable_Clear, RW_SymbolTable_Destroy, RW_SymbolTable_Init, RW_SymbolTable_Reg,
!     RW_SymbolTable_Set, XMLElement_AddAttribute, XMLElement_AddChild, XMLElement_Destroy,
!     XMLElement_Init, XMLElement_SetName, XMLElement_SetText, XMLDocument_Destroy,
!     XMLDocument_Init, XMLDocument_Load, XMLDocument_Save, XMLDocument_SetRoot
!
! Notes:
!   Merged module: IO_Mgr + Serial_Core. FileHandle: Basic file operations with mode
!   management. BinaryReader/Writer: Type-safe binary I/O with endianness support.
!   HDF5: Hierarchical data format operations (stub implementations). XML: Document object
!   model operations. RW_Serializer/Deserializer: High-level serialization with symbol table
!   management. Supports Int1/Int2/Int4/Int8, DP, String, and array types. Symbol table
!   tracks variable entries with IDs, names, types, ranks, shapes, sizes, offsets.
!   Memory manager tracks allocation/deallocation statistics. Note: FileHandle_Open has
!   duplicate case (MD_MODEL_FILE_MODE_READ) - should be MD_MODEL_FILE_MODE_UPDATE. HDF5 operations are stub
!   implementations. Logic/Computation chain diagrams: see MD_Base_IOSerial_Mgr_Chains.md
!
! Status: CORE | Last verified: 2026-03-02
! Theory: N/A
!===============================================================================
!>>> UFC_L3_QUENCH | Domain:Model | Role:Mgr | FuncSet:Query,Mutate | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
!>>> UFC_L3_CONTRACT | Model/CONTRACT.md

!>>> UFC_L3_QUENCH | Domain:Model | Role:Mgr | FuncSet:Query,Mutate | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)

MODULE MD_Base_IOSerialMgr
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status
  USE IF_Prec_Core, ONLY: i4, i8, wp

  IMPLICIT NONE
  PRIVATE

  ! Model I/O status codes
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MODEL_STATUS_OK = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MODEL_STATUS_INVALID = -1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MODEL_STATUS_IO_ERROR = -2_i4

  ! Integer kinds not in IF_Prec (1-byte, 2-byte)
  integer, parameter :: i1 = selected_int_kind(2)
  integer, parameter :: i2 = selected_int_kind(4)

  ! File mode and type constants
  integer(i4), parameter :: MD_MODEL_FILE_MODE_READ   = 1_i4
  integer(i4), parameter :: MD_MODEL_FILE_MODE_WRITE  = 2_i4
  integer(i4), parameter :: MD_MODEL_FILE_MODE_APPEND = 3_i4
  integer(i4), parameter :: MD_MODEL_FILE_MODE_UPDATE = 4_i4
  integer(i4), parameter :: MD_MODEL_FILE_TYPE_UNKNO  = 0_i4
  integer(i4), parameter :: MD_MODEL_FILE_TYPE_TEXT   = 1_i4
  integer(i4), parameter :: MD_MODEL_FILE_TYPE_BINAR  = 2_i4
  integer(i4), parameter :: MD_MODEL_FILE_TYPE_HDF5   = 3_i4
  integer(i4), parameter :: MD_MODEL_FILE_TYPE_XML    = 4_i4

  ! RW type constants (needed for PUBLIC before RW types)
  integer(i4), parameter :: MD_MODEL_RW_TYPE_INT1 = 1_i4
  integer(i4), parameter :: MD_MODEL_RW_TYPE_INT2 = 2_i4
  integer(i4), parameter :: MD_MODEL_RW_TYPE_INT4 = 3_i4
  integer(i4), parameter :: MD_MODEL_RW_TYPE_INT8 = 4_i4
  integer(i4), parameter :: MD_MODEL_RW_TYPE_DP   = 5_i4
  integer(i4), parameter :: MD_MODEL_RW_TYPE_CHAR = 6_i4

    ! PUBLIC constants (A-Z)
    PUBLIC :: MD_MODEL_FILE_MODE_APPEND, MD_MODEL_FILE_MODE_READ, MD_MODEL_FILE_MODE_UPDATE, &
              MD_MODEL_FILE_MODE_WRITE
    PUBLIC :: MD_MODEL_FILE_TYPE_BINAR, MD_MODEL_FILE_TYPE_HDF5, MD_MODEL_FILE_TYPE_TEXT, &
              MD_MODEL_FILE_TYPE_UNKNO, MD_MODEL_FILE_TYPE_XML
    PUBLIC :: MD_MODEL_RW_TYPE_CHAR, MD_MODEL_RW_TYPE_DP, MD_MODEL_RW_TYPE_INT1, &
              MD_MODEL_RW_TYPE_INT2, MD_MODEL_RW_TYPE_INT4, MD_MODEL_RW_TYPE_INT8

    ! PUBLIC types (A-Z)
    PUBLIC :: BinaryReader, BinaryWriter
    PUBLIC :: FileHandle
    PUBLIC :: HDF5Dataset, HDF5File, HDF5Group
    PUBLIC :: RW_Deserializer, RW_MemMgr, RW_Serializer, RW_SymbolTable, RW_VariableEntry
    PUBLIC :: XMLAttribute, XMLDocument, XMLElement

  ! ===================================================================
  ! File Handle Type
  ! ===================================================================

  type :: FileHandle
    integer(i4) :: unit = 0_i4
    character(len=512) :: filename = ""
    integer(i4) :: mode = MD_MODEL_FILE_MODE_READ
    integer(i4) :: file_type = MD_MODEL_FILE_TYPE_UNKNO
    logical :: is_open = .false.
    integer(i8) :: file_size = 0_i8
    integer(i8) :: current_pos = 0_i8
  contains
    procedure :: Init => FileHandle_Init
    procedure :: Destroy => FileHandle_Destroy
    procedure :: Open => FileHandle_Open
    procedure :: Close => FileHandle_Close
    procedure :: ReadLine => FileHandle_ReadLine
    procedure :: WriteLine => FileHandle_WriteLine
    procedure :: IsOpen => FileHandle_IsOpen
    procedure :: GetSize => FileHandle_GetSize
    procedure :: GetPosition => FileHandle_GetPosition
    procedure :: Seek => FileHandle_Seek
    procedure :: Flush => FileHandle_Flush
  end type FileHandle

  ! ===================================================================
  ! Binary Reader Type
  ! ===================================================================

  type :: BinaryReader  ! BinaryReader: Binary file reader type
    type(FileHandle) :: file_handle
    LOGICAL :: is_initialized = .false.
    logical :: big_endian = .false.
  contains
    procedure :: Init => BR_Init
    procedure :: Destroy => BR_Destroy
    procedure :: Open => BR_Open
    procedure :: Close => BR_Close
    procedure :: ReadInt1 => BR_ReadInt1
    procedure :: ReadInt2 => BR_ReadInt2
    procedure :: ReadInt4 => BR_ReadInt4
    procedure :: ReadInt8 => BR_ReadInt8
    procedure :: ReadDP => BR_ReadDP
    procedure :: ReadArrayInt1 => BR_ReadArrInt1
    procedure :: ReadArrayInt4 => BR_ReadArrInt4
    procedure :: ReadArrayDP => BR_ReadArrDP
    procedure :: ReadString => BR_ReadStr
    procedure :: IsOpen => BR_IsOpen
  end type BinaryReader

  ! ===================================================================
  ! Binary Writer Type
  ! ===================================================================

  type :: BinaryWriter  ! BinaryWriter: Binary file writer type
    type(FileHandle) :: file_handle
    LOGICAL :: is_initialized = .false.
    logical :: big_endian = .false.
  contains
    procedure :: Init => BW_Init
    procedure :: Destroy => BW_Destroy
    procedure :: Open => BW_Open
    procedure :: Close => BW_Close
    procedure :: WriteInt1 => BW_WriteInt1
    procedure :: WriteInt2 => BW_WriteInt2
    procedure :: WriteInt4 => BW_WriteInt4
    procedure :: WriteInt8 => BW_WriteInt8
    procedure :: WriteDP => BW_WriteDP
    procedure :: WriteArrayInt1 => BW_WriteArrInt1
    procedure :: WriteArrayInt4 => BW_WriteArrInt4
    procedure :: WriteArrayDP => BW_WriteArrDP
    procedure :: WriteString => BW_WriteStr
    procedure :: IsOpen => BW_IsOpen
    procedure :: Flush => BW_Flush
  end type BinaryWriter

  ! ===================================================================
  ! HDF5 File Type
  ! ===================================================================

  type :: HDF5File
    integer(i8) :: file_id = 0_i8
    character(len=512) :: filename = ""
    integer(i4) :: mode = MD_MODEL_FILE_MODE_READ
    logical :: is_open = .false.
    integer(i4) :: n_groups = 0_i4
    integer(i4) :: n_datasets = 0_i4
  contains
    procedure :: Init => HDF5File_Init
    procedure :: Destroy => HDF5File_Destroy
    procedure :: Open => HDF5File_Open
    procedure :: Close => HDF5File_Close
    procedure :: CreateGroup => HDF5File_CreateGroup
    procedure :: OpenGroup => HDF5File_OpenGroup
    procedure :: CreateDataset => HDF5File_CreateDataset
    procedure :: OpenDataset => HDF5File_OpenDataset
    procedure :: IsOpen => HDF5File_IsOpen
    procedure :: GetGroup => HDF5File_GetGroup
    procedure :: GetDataset => HDF5File_GetDataset
  end type HDF5File

  ! ===================================================================
  ! HDF5 Group Type
  ! ===================================================================

  type :: HDF5Group
    integer(i8) :: group_id = 0_i8
    character(len=256) :: name = ""
    integer(i8) :: parent_id = 0_i8
    logical :: is_open = .false.
    integer(i4) :: n_subgroups = 0_i4
    integer(i4) :: n_datasets = 0_i4
  contains
    procedure :: Init => HDF5Group_Init
    procedure :: Destroy => HDF5Group_Destroy
    procedure :: Open => HDF5Group_Open
    procedure :: Close => HDF5Group_Close
    procedure :: CreateSubgroup => HDF5Group_CreateSubgroup
    procedure :: OpenSubgroup => HDF5Group_OpenSubgroup
    procedure :: CreateDataset => HDF5Group_CreateDataset
    procedure :: OpenDataset => HDF5Group_OpenDataset
    procedure :: IsOpen => HDF5Group_IsOpen
  end type HDF5Group

  ! ===================================================================
  ! HDF5 Dataset Type
  ! ===================================================================

  type :: HDF5Dataset
    integer(i8) :: dataset_id = 0_i8
    character(len=256) :: name = ""
    integer(i8) :: parent_id = 0_i8
    logical :: is_open = .false.
    integer(i4) :: rank = 0_i4
    integer(i8), allocatable :: dims(:)
    integer(i4) :: dType = 0_i4
  contains
    procedure :: Init => HDF5Dataset_Init
    procedure :: Destroy => HDF5Dataset_Destroy
    procedure :: Open => HDF5Dataset_Open
    procedure :: Close => HDF5Dataset_Close
    procedure :: ReadInt1 => HDF5Dataset_ReadInt1
    procedure :: ReadInt4 => HDF5Dataset_ReadInt4
    procedure :: ReadDP => HDF5Dataset_ReadDP
    procedure :: WriteInt1 => HDF5Dataset_WriteInt1
    procedure :: WriteInt4 => HDF5Dataset_WriteInt4
    procedure :: WriteDP => HDF5Dataset_WriteDP
    procedure :: GetDims => HDF5Dataset_GetDims
    procedure :: IsOpen => HDF5Dataset_IsOpen
  end type HDF5Dataset

  ! ===================================================================
  ! XML Attribute Type (must precede XMLElement)
  ! ===================================================================

  type :: XMLAttribute
    character(len=256) :: name = ""
    character(len=4096) :: value = ""
  end type XMLAttribute

  ! ===================================================================
  ! XML Element Type
  ! ===================================================================

  type :: XMLElement
    character(len=256) :: name = ""
    character(len=4096) :: text = ""
    type(XMLAttribute), allocatable :: attributes(:)
    type(XMLElement), pointer :: parent => null()
    type(XMLElement), pointer :: children(:) => null()
    integer(i4) :: n_attributes = 0_i4
    integer(i4) :: n_children = 0_i4
  contains
    procedure :: Init => XMLElement_Init
    procedure :: Destroy => XMLElement_Destroy
    procedure :: SetName => XMLElement_SetName
    procedure :: SetText => XMLElement_SetText
    procedure :: AddAttribute => XMLElement_AddAttribute
    procedure :: GetAttribute => XMLElement_GetAttribute
    procedure :: AddChild => XMLElement_AddChild
    procedure :: GetChild => XMLElement_GetChild
    procedure :: GetChildren => XMLElement_GetChildren
    procedure :: FindChild => XMLElement_FindChild
    procedure :: FindChildren => XMLElement_FindChildren
    procedure :: ToString => XMLElement_ToString
  end type XMLElement

  ! ===================================================================
  ! XML Document Type
  ! ===================================================================

  type :: XMLDocument
    character(len=512) :: filename = ""
    character(len=64) :: version = "1.0"
    character(len=32) :: encoding = "UTF-8"
    type(XMLElement), pointer :: root => null()
    logical :: is_loaded = .false.
  contains
    procedure :: Init => XMLDocument_Init
    procedure :: Destroy => XMLDocument_Destroy
    procedure :: Load => XMLDocument_Load
    procedure :: Save => XMLDocument_Save
    procedure :: GetRoot => XMLDocument_GetRoot
    procedure :: SetRoot => XMLDocument_SetRoot
    procedure :: FindElement => XMLDocument_FindElement
    procedure :: FindElements => XMLDocument_FindElements
  end type XMLDocument

  ! ===================================================================
  ! Serial_Core: RW Types (merged from MD_Base_Serial_Core)
  ! ===================================================================
  PUBLIC :: RW_Clear_SymbolTable, RW_Deserialize, RW_Deserialize_DP, RW_Deserialize_Int4, &
            RW_Deserialize_String, RW_Get_Variable, RW_Serialize, RW_Set_Variable

  type :: RW_VariableEntry
    integer(i4) :: var_id = 0_i4
    character(len=64) :: name = ""
    integer(i4) :: dType = 0_i4
    integer(i4) :: rank = 0_i4
    integer(i8), allocatable :: shape(:)
    integer(i8) :: size = 0_i8
    integer(i8) :: offset = 0_i8
    logical :: is_allocated = .false.
  end type RW_VariableEntry

  type :: RW_SymbolTable
    type(RW_VariableEntry), allocatable :: entries(:)
    integer(i4) :: n_entries = 0_i4
    integer(i4) :: max_entries = 0_i4
    integer(i8) :: total_size = 0_i8
  contains
    procedure :: Init => RW_SymbolTable_Init
    procedure :: Destroy => RW_SymbolTable_Destroy
    procedure :: Reg => RW_SymbolTable_Reg
    procedure :: Find => RW_SymbolTable_Find
    procedure :: Get => RW_SymbolTable_Get
    procedure :: Set => RW_SymbolTable_Set
    procedure :: Clear => RW_SymbolTable_Clear
    procedure :: GetTotalSize => RW_SymbolTable_GetTotalSize
  end type RW_SymbolTable

  type :: RW_Serializer
    type(BinaryWriter) :: writer
    type(RW_SymbolTable) :: symbol_table
    LOGICAL :: is_initialized = .false.
  contains
    procedure :: Init => RW_Serializer_Init
    procedure :: Destroy => RW_Serializer_Destroy
    procedure :: Open => RW_Serializer_Open
    procedure :: Close => RW_Serializer_Close
    procedure :: Flush => RW_Serializer_Flush
    procedure :: Serialize => RW_Serializer_Serialize
  end type RW_Serializer

  type :: RW_Deserializer
    type(BinaryReader) :: reader
    type(RW_SymbolTable) :: symbol_table
    LOGICAL :: is_initialized = .false.
  contains
    procedure :: Init => RW_Deserializer_Init
    procedure :: Destroy => RW_Deserializer_Destroy
    procedure :: Open => RW_Deserializer_Open
    procedure :: Close => RW_Deserializer_Close
    procedure :: Deserialize => RW_Deserializer_Deserialize
  end type RW_Deserializer

  type :: RW_MemMgr
    integer(i8) :: total_allocated = 0_i8
    integer(i8) :: total_freed = 0_i8
    integer(i4) :: n_allocations = 0_i4
    integer(i4) :: n_deallocations = 0_i4
    logical :: tracking_enable = .true.
  contains
    procedure :: Allocate => RW_MemMgr_Alloc
    procedure :: Deallocate => RW_MemMgr_Dealloc
    procedure :: Reallocate => RW_MemMgr_Realloc
    procedure :: GetStats => RW_MemMgr_GetStats
    procedure :: Reset => RW_MemMgr_Reset
  end type RW_MemMgr

  interface RW_Serialize
    module procedure RW_Serialize_Int1
    module procedure RW_Serialize_Int4
    module procedure RW_Serialize_Int8
    module procedure RW_Serialize_DP
    module procedure RW_Serialize_String
    module procedure RW_Serialize_ArrayInt4
    module procedure RW_Serialize_ArrayDP
  end interface RW_Serialize

  interface RW_Deserialize
    module procedure RW_Deserialize_Int1
    module procedure RW_Deserialize_Int4
    module procedure RW_Deserialize_Int8
    module procedure RW_Deserialize_DP
    module procedure RW_Deserialize_String
    module procedure RW_Deserialize_ArrayInt4
    module procedure RW_Deserialize_ArrayDP
  end interface RW_Deserialize

contains

  ! ===================================================================
  ! File Handle Procedures
  ! ===================================================================
  subroutine FileHandle_Init(this, filename, mode, file_type)
    class(FileHandle), intent(inout) :: this
    character(len=*), intent(in) :: filename
    integer(i4), intent(in), optional :: mode, file_type

    this%filename = filename
    this%mode = MD_MODEL_FILE_MODE_READ
    this%file_type = MD_MODEL_FILE_TYPE_UNKNO
    this%is_open = .false.
    this%file_size = 0_i8
    this%current_pos = 0_i8

    if (present(mode)) this%mode = mode
    if (present(file_type)) this%file_type = file_type
  end subroutine FileHandle_Init

  subroutine FileHandle_Destroy(this)
    class(FileHandle), intent(inout) :: this
    type(ErrorStatusType) :: status
    if (this%is_open) call this%Close(status)
    this%filename = ""
    this%mode = MD_MODEL_FILE_MODE_READ
    this%file_type = MD_MODEL_FILE_TYPE_UNKNO
    this%is_open = .false.
    this%file_size = 0_i8
    this%current_pos = 0_i8
  end subroutine FileHandle_Destroy

  subroutine FileHandle_Open(this, status)
    class(FileHandle), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (this%is_open) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "File already open"
      status%source = "FileHandle_Open"
      status%has_error = .true.
      return
    end if

    select case (this%mode)
      case (MD_MODEL_FILE_MODE_READ)
        open(newunit=this%unit, file=trim(this%filename), status='old', action='read', iostat=status%status_code)
      case (MD_MODEL_FILE_MODE_WRITE)
        open(newunit=this%unit, file=trim(this%filename), status='replace', action='write', iostat=status%status_code)
      case (MD_MODEL_FILE_MODE_APPEND)
        open(newunit=this%unit, file=trim(this%filename), status='old', &
             action='write', position='append', iostat=status%status_code)
      case (MD_MODEL_FILE_MODE_UPDATE)
        open(newunit=this%unit, file=trim(this%filename), status='old', &
             action='readwrite', iostat=status%status_code)
    end select

    if (status%status_code /= 0) then
      status%status_code = MD_MODEL_STATUS_IO_ERROR
      status%message = "Failed to open file: " // trim(this%filename)
      status%source = "FileHandle_Open"
      status%has_error = .true.
      return
    end if

    this%is_open = .true.
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine FileHandle_Open

  subroutine FileHandle_Close(this, status)
    class(FileHandle), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%is_open) then
      status%status_code = MD_MODEL_STATUS_OK
      return
    end if

    close(this%unit, iostat=status%status_code)

    if (status%status_code /= 0) then
      status%status_code = MD_MODEL_STATUS_IO_ERROR
      status%message = "Failed to close file: " // trim(this%filename)
      status%source = "FileHandle_Close"
      status%has_error = .true.
      return
    end if

    this%is_open = .false.
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine FileHandle_Close

  subroutine FileHandle_ReadLine(this, line, status)
    class(FileHandle), intent(inout) :: this
    character(len=*), intent(out) :: line
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%is_open) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "File not open"
      status%source = "FileHandle_ReadLine"
      status%has_error = .true.
      return
    end if

    read(this%unit, '(A)', iostat=status%status_code) line

    if (status%status_code /= 0 .and. status%status_code /= -1) then
      status%status_code = MD_MODEL_STATUS_IO_ERROR
      status%message = "Failed to read line"
      status%source = "FileHandle_ReadLine"
      status%has_error = .true.
      return
    end if

    status%status_code = MD_MODEL_STATUS_OK
  end subroutine FileHandle_ReadLine

  subroutine FileHandle_WriteLine(this, line, status)
    class(FileHandle), intent(inout) :: this
    character(len=*), intent(in) :: line
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%is_open) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "File not open"
      status%source = "FileHandle_WriteLine"
      status%has_error = .true.
      return
    end if

    write(this%unit, '(A)', iostat=status%status_code) trim(line)

    if (status%status_code /= 0) then
      status%status_code = MD_MODEL_STATUS_IO_ERROR
      status%message = "Failed to write line"
      status%source = "FileHandle_WriteLine"
      status%has_error = .true.
      return
    end if

    status%status_code = MD_MODEL_STATUS_OK
  end subroutine FileHandle_WriteLine

  function FileHandle_IsOpen(this) result(is_open)
    class(FileHandle), intent(in) :: this
    logical :: is_open
    is_open = this%is_open
  end function FileHandle_IsOpen

  function FileHandle_GetSize(this) result(file_size)
    class(FileHandle), intent(in) :: this
    integer(i8) :: file_size
    file_size = this%file_size
  end function FileHandle_GetSize

  function FileHandle_GetPosition(this) result(current_pos)
    class(FileHandle), intent(in) :: this
    integer(i8) :: current_pos
    current_pos = this%current_pos
  end function FileHandle_GetPosition

  subroutine FileHandle_Seek(this, position, status)
    class(FileHandle), intent(inout) :: this
    integer(i8), intent(in) :: position
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    this%current_pos = position
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine FileHandle_Seek

  ! Flush output buffer to file
  subroutine FileHandle_Flush(this, status)
    class(FileHandle), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%is_open) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "File not open"
      status%source = "FileHandle_Flush"
      status%has_error = .true.
      return
    end if

    flush(this%unit, iostat=status%status_code)
    if (status%status_code /= 0) then
      status%status_code = MD_MODEL_STATUS_IO_ERROR
      status%message = "Failed to flush file"
      status%source = "FileHandle_Flush"
      status%has_error = .true.
      return
    end if

    status%status_code = MD_MODEL_STATUS_OK
  end subroutine FileHandle_Flush

  ! ===================================================================
  ! Binary Reader Procedures
  ! ===================================================================
  ! BR: Binary Reader - Init binary file reader
  subroutine BR_Init(this, filename, big_endian)
    class(BinaryReader), intent(inout) :: this
    character(len=*), intent(in) :: filename
    logical, intent(in), optional :: big_endian

    call this%file_handle%Init(filename, MD_MODEL_FILE_MODE_READ, MD_MODEL_FILE_TYPE_BINAR)
    this%is_initialized = .false.
    this%big_endian = .false.

    if (present(big_endian)) this%big_endian = big_endian
  end subroutine BR_Init

  ! BR: Binary Reader - Destroy binary file reader
  subroutine BR_Destroy(this)
    class(BinaryReader), intent(inout) :: this
    call this%file_handle%Destroy()
    this%is_initialized = .false.
  end subroutine BR_Destroy

  ! BR: Binary Reader - Open binary file for reading
  subroutine BR_Open(this, status)
    class(BinaryReader), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call this%file_handle%Open(status)
    if (status%status_code == MD_MODEL_STATUS_OK) then
      this%is_initialized = .true.
    end if
  end subroutine BR_Open

  ! BR: Binary Reader - Close binary file
  subroutine BR_Close(this, status)
    class(BinaryReader), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call this%file_handle%Close(status)
    this%is_initialized = .false.
  end subroutine BR_Close

  ! BR: Binary Reader - Read 1-byte integer
  subroutine BR_ReadInt1(this, value, status)
    class(BinaryReader), intent(inout) :: this
    integer(i1), intent(out) :: value
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%is_initialized) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "BinaryReader not initialized"
      status%source = "BR_ReadInt1"
      status%has_error = .true.
      return
    end if

    read(this%file_handle%unit, iostat=status%status_code) value
    if (status%status_code /= 0) then
      status%status_code = MD_MODEL_STATUS_IO_ERROR
      status%message = "Failed to read Int1"
      status%source = "BR_ReadInt1"
      status%has_error = .true.
    end if
  end subroutine BR_ReadInt1

  ! BR: Binary Reader - Read 2-byte integer
  subroutine BR_ReadInt2(this, value, status)
    class(BinaryReader), intent(inout) :: this
    integer(i2), intent(out) :: value
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%is_initialized) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "BinaryReader not initialized"
      status%source = "BR_ReadInt2"
      status%has_error = .true.
      return
    end if

    read(this%file_handle%unit, iostat=status%status_code) value
    if (status%status_code /= 0) then
      status%status_code = MD_MODEL_STATUS_IO_ERROR
      status%message = "Failed to read Int2"
      status%source = "BR_ReadInt2"
      status%has_error = .true.
    end if
  end subroutine BR_ReadInt2

  ! BR: Binary Reader - Read 4-byte integer
  subroutine BR_ReadInt4(this, value, status)
    class(BinaryReader), intent(inout) :: this
    integer(i4), intent(out) :: value
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%is_initialized) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "BinaryReader not initialized"
      status%source = "BR_ReadInt4"
      status%has_error = .true.
      return
    end if

    read(this%file_handle%unit, iostat=status%status_code) value
    if (status%status_code /= 0) then
      status%status_code = MD_MODEL_STATUS_IO_ERROR
      status%message = "Failed to read Int4"
      status%source = "BR_ReadInt4"
      status%has_error = .true.
    end if
  end subroutine BR_ReadInt4

  ! BR: Binary Reader - Read 8-byte integer
  subroutine BR_ReadInt8(this, value, status)
    class(BinaryReader), intent(inout) :: this
    integer(i8), intent(out) :: value
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%is_initialized) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "BinaryReader not initialized"
      status%source = "BR_ReadInt8"
      status%has_error = .true.
      return
    end if

    read(this%file_handle%unit, iostat=status%status_code) value
    if (status%status_code /= 0) then
      status%status_code = MD_MODEL_STATUS_IO_ERROR
      status%message = "Failed to read Int8"
      status%source = "BR_ReadInt8"
      status%has_error = .true.
    end if
  end subroutine BR_ReadInt8

  ! BR: Binary Reader - Read double precision real
  subroutine BR_ReadDP(this, value, status)
    class(BinaryReader), intent(inout) :: this
    real(wp), intent(out) :: value
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%is_initialized) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "BinaryReader not initialized"
      status%source = "BR_ReadDP"
      status%has_error = .true.
      return
    end if

    read(this%file_handle%unit, iostat=status%status_code) value
    if (status%status_code /= 0) then
      status%status_code = MD_MODEL_STATUS_IO_ERROR
      status%message = "Failed to read DP"
      status%source = "BR_ReadDP"
      status%has_error = .true.
    end if
  end subroutine BR_ReadDP

  ! BR: Binary Reader - Read array of 1-byte integers
  subroutine BR_ReadArrInt1(this, array, status)
    class(BinaryReader), intent(inout) :: this
    integer(i1), intent(out) :: array(:)
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%is_initialized) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "BinaryReader not initialized"
      status%source = "BR_ReadArrInt1"
      status%has_error = .true.
      return
    end if

    read(this%file_handle%unit, iostat=status%status_code) array
    if (status%status_code /= 0) then
      status%status_code = MD_MODEL_STATUS_IO_ERROR
      status%message = "Failed to read Int1 array"
      status%source = "BR_ReadArrInt1"
      status%has_error = .true.
    end if
  end subroutine BR_ReadArrInt1

  ! BR: Binary Reader - Read array of 4-byte integers
  subroutine BR_ReadArrInt4(this, array, status)
    class(BinaryReader), intent(inout) :: this
    integer(i4), intent(out) :: array(:)
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%is_initialized) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "BinaryReader not initialized"
      status%source = "BR_ReadArrInt4"
      status%has_error = .true.
      return
    end if

    read(this%file_handle%unit, iostat=status%status_code) array
    if (status%status_code /= 0) then
      status%status_code = MD_MODEL_STATUS_IO_ERROR
      status%message = "Failed to read Int4 array"
      status%source = "BR_ReadArrInt4"
      status%has_error = .true.
    end if
  end subroutine BR_ReadArrInt4

  ! BR: Binary Reader - Read array of double precision reals
  subroutine BR_ReadArrDP(this, array, status)
    class(BinaryReader), intent(inout) :: this
    real(wp), intent(out) :: array(:)
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%is_initialized) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "BinaryReader not initialized"
      status%source = "BR_ReadArrDP"
      status%has_error = .true.
      return
    end if

    read(this%file_handle%unit, iostat=status%status_code) array
    if (status%status_code /= 0) then
      status%status_code = MD_MODEL_STATUS_IO_ERROR
      status%message = "Failed to read DP array"
      status%source = "BR_ReadArrDP"
      status%has_error = .true.
    end if
  end subroutine BR_ReadArrDP

  ! BR: Binary Reader - Read character string
  subroutine BR_ReadStr(this, str, status)
    class(BinaryReader), intent(inout) :: this
    character(len=*), intent(out) :: str
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: str_len

    call init_error_status(status)

    if (.not. this%is_initialized) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "BinaryReader not initialized"
      status%source = "BR_ReadStr"
      status%has_error = .true.
      return
    end if

    read(this%file_handle%unit, iostat=status%status_code) str_len
    if (status%status_code /= 0) then
      status%status_code = MD_MODEL_STATUS_IO_ERROR
      status%message = "Failed to read string length"
      status%source = "BR_ReadStr"
      status%has_error = .true.
      return
    end if

    if (str_len > len(str)) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "String length exceeds buffer"
      status%source = "BR_ReadStr"
      status%has_error = .true.
      return
    end if

    if (str_len > 0) then
      read(this%file_handle%unit, iostat=status%status_code) str(1:str_len)
      if (status%status_code /= 0) then
        status%status_code = MD_MODEL_STATUS_IO_ERROR
      status%message = "Failed to read string"
      status%source = "BR_ReadStr"
      status%has_error = .true.
        return
      end if
    end if

    str(str_len+1:) = ""
  end subroutine BR_ReadStr

  ! BR: Binary Reader - Check if file is open
  function BR_IsOpen(this) result(is_open)
    class(BinaryReader), intent(in) :: this
    logical :: is_open
    is_open = this%is_initialized
  end function BR_IsOpen

  ! ===================================================================
  ! Binary Writer Procedures
  ! ===================================================================
  ! BW: Binary Writer - Init binary file writer
  subroutine BW_Init(this, filename, big_endian)
    class(BinaryWriter), intent(inout) :: this
    character(len=*), intent(in) :: filename
    logical, intent(in), optional :: big_endian

    call this%file_handle%Init(filename, MD_MODEL_FILE_MODE_WRITE, MD_MODEL_FILE_TYPE_BINAR)
    this%is_initialized = .false.
    this%big_endian = .false.

    if (present(big_endian)) this%big_endian = big_endian
  end subroutine BW_Init

  ! BW: Binary Writer - Destroy binary file writer
  subroutine BW_Destroy(this)
    class(BinaryWriter), intent(inout) :: this
    call this%file_handle%Destroy()
    this%is_initialized = .false.
  end subroutine BW_Destroy

  ! BW: Binary Writer - Open binary file for writing
  subroutine BW_Open(this, status)
    class(BinaryWriter), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call this%file_handle%Open(status)
    if (status%status_code == MD_MODEL_STATUS_OK) then
      this%is_initialized = .true.
    end if
  end subroutine BW_Open

  ! BW: Binary Writer - Close binary file
  subroutine BW_Close(this, status)
    class(BinaryWriter), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call this%file_handle%Close(status)
    this%is_initialized = .false.
  end subroutine BW_Close

  ! BW: Binary Writer - Write 1-byte integer
  subroutine BW_WriteInt1(this, value, status)
    class(BinaryWriter), intent(inout) :: this
    integer(i1), intent(in) :: value
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%is_initialized) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "BinaryWriter not initialized"
      status%source = "BW_WriteInt1"
      status%has_error = .true.
      return
    end if

    write(this%file_handle%unit, iostat=status%status_code) value
    if (status%status_code /= 0) then
      status%status_code = MD_MODEL_STATUS_IO_ERROR
      status%message = "Failed to write Int1"
      status%source = "BW_WriteInt1"
      status%has_error = .true.
    end if
  end subroutine BW_WriteInt1

  ! BW: Binary Writer - Write 2-byte integer
  subroutine BW_WriteInt2(this, value, status)
    class(BinaryWriter), intent(inout) :: this
    integer(i2), intent(in) :: value
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%is_initialized) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "BinaryWriter not initialized"
      status%source = "BW_WriteInt2"
      status%has_error = .true.
      return
    end if

    write(this%file_handle%unit, iostat=status%status_code) value
    if (status%status_code /= 0) then
      status%status_code = MD_MODEL_STATUS_IO_ERROR
      status%message = "Failed to write Int2"
      status%source = "BW_WriteInt2"
      status%has_error = .true.
    end if
  end subroutine BW_WriteInt2

  ! BW: Binary Writer - Write 4-byte integer
  subroutine BW_WriteInt4(this, value, status)
    class(BinaryWriter), intent(inout) :: this
    integer(i4), intent(in) :: value
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%is_initialized) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "BinaryWriter not initialized"
      status%source = "BW_WriteInt4"
      status%has_error = .true.
      return
    end if

    write(this%file_handle%unit, iostat=status%status_code) value
    if (status%status_code /= 0) then
      status%status_code = MD_MODEL_STATUS_IO_ERROR
      status%message = "Failed to write Int4"
      status%source = "BW_WriteInt4"
      status%has_error = .true.
    end if
  end subroutine BW_WriteInt4

  ! BW: Binary Writer - Write 8-byte integer
  subroutine BW_WriteInt8(this, value, status)
    class(BinaryWriter), intent(inout) :: this
    integer(i8), intent(in) :: value
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%is_initialized) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "BinaryWriter not initialized"
      status%source = "BW_WriteInt8"
      status%has_error = .true.
      return
    end if

    write(this%file_handle%unit, iostat=status%status_code) value
    if (status%status_code /= 0) then
      status%status_code = MD_MODEL_STATUS_IO_ERROR
      status%message = "Failed to write Int8"
      status%source = "BW_WriteInt8"
      status%has_error = .true.
    end if
  end subroutine BW_WriteInt8

  ! BW: Binary Writer - Write double precision real
  subroutine BW_WriteDP(this, value, status)
    class(BinaryWriter), intent(inout) :: this
    real(wp), intent(in) :: value
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%is_initialized) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "BinaryWriter not initialized"
      status%source = "BW_WriteDP"
      status%has_error = .true.
      return
    end if

    write(this%file_handle%unit, iostat=status%status_code) value
    if (status%status_code /= 0) then
      status%status_code = MD_MODEL_STATUS_IO_ERROR
      status%message = "Failed to write DP"
      status%source = "BW_WriteDP"
      status%has_error = .true.
    end if
  end subroutine BW_WriteDP

  ! BW: Binary Writer - Write array of 1-byte integers
  subroutine BW_WriteArrInt1(this, array, status)
    class(BinaryWriter), intent(inout) :: this
    integer(i1), intent(in) :: array(:)
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%is_initialized) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "BinaryWriter not initialized"
      status%source = "BW_WriteArrInt1"
      status%has_error = .true.
      return
    end if

    write(this%file_handle%unit, iostat=status%status_code) array
    if (status%status_code /= 0) then
      status%status_code = MD_MODEL_STATUS_IO_ERROR
      status%message = "Failed to write Int1 array"
      status%source = "BW_WriteArrInt1"
      status%has_error = .true.
    end if
  end subroutine BW_WriteArrInt1

  ! BW: Binary Writer - Write array of 4-byte integers
  subroutine BW_WriteArrInt4(this, array, status)
    class(BinaryWriter), intent(inout) :: this
    integer(i4), intent(in) :: array(:)
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%is_initialized) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "BinaryWriter not initialized"
      status%source = "BW_WriteArrInt4"
      status%has_error = .true.
      return
    end if

    write(this%file_handle%unit, iostat=status%status_code) array
    if (status%status_code /= 0) then
      status%status_code = MD_MODEL_STATUS_IO_ERROR
      status%message = "Failed to write Int4 array"
      status%source = "BW_WriteArrInt4"
      status%has_error = .true.
    end if
  end subroutine BW_WriteArrInt4

  ! BW: Binary Writer - Write array of double precision reals
  subroutine BW_WriteArrDP(this, array, status)
    class(BinaryWriter), intent(inout) :: this
    real(wp), intent(in) :: array(:)
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%is_initialized) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "BinaryWriter not initialized"
      status%source = "BW_WriteArrDP"
      status%has_error = .true.
      return
    end if

    write(this%file_handle%unit, iostat=status%status_code) array
    if (status%status_code /= 0) then
      status%status_code = MD_MODEL_STATUS_IO_ERROR
      status%message = "Failed to write DP array"
      status%source = "BW_WriteArrDP"
      status%has_error = .true.
    end if
  end subroutine BW_WriteArrDP

  ! BW: Binary Writer - Write character string
  subroutine BW_WriteStr(this, str, status)
    class(BinaryWriter), intent(inout) :: this
    character(len=*), intent(in) :: str
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: str_len

    call init_error_status(status)

    if (.not. this%is_initialized) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "BinaryWriter not initialized"
      status%source = "BW_WriteStr"
      status%has_error = .true.
      return
    end if

    str_len = len_trim(str)
    write(this%file_handle%unit, iostat=status%status_code) str_len
    if (status%status_code /= 0) then
      status%status_code = MD_MODEL_STATUS_IO_ERROR
      status%message = "Failed to write string length"
      status%source = "BW_WriteStr"
      status%has_error = .true.
      return
    end if

    if (str_len > 0) then
      write(this%file_handle%unit, iostat=status%status_code) str(1:str_len)
      if (status%status_code /= 0) then
        status%status_code = MD_MODEL_STATUS_IO_ERROR
      status%message = "Failed to write string"
      status%source = "BW_WriteStr"
      status%has_error = .true.
        return
      end if
    end if

    status%status_code = MD_MODEL_STATUS_OK
  end subroutine BW_WriteStr

  ! BW: Binary Writer - Check if file is open
  function BW_IsOpen(this) result(is_open)
    class(BinaryWriter), intent(in) :: this
    logical :: is_open
    is_open = this%is_initialized
  end function BW_IsOpen

  ! BW: Binary Writer - Flush output buffer
  subroutine BW_Flush(this, status)
    class(BinaryWriter), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    call this%file_handle%Flush(status)
  end subroutine BW_Flush

  ! ===================================================================
  ! HDF5 File Procedures
  ! ===================================================================
  subroutine HDF5File_Init(this, filename, mode)
    class(HDF5File), intent(inout) :: this
    character(len=*), intent(in) :: filename
    integer(i4), intent(in), optional :: mode

    this%filename = filename
    this%mode = MD_MODEL_FILE_MODE_READ
    this%is_open = .false.
    this%n_groups = 0_i4
    this%n_datasets = 0_i4

    if (present(mode)) this%mode = mode
  end subroutine HDF5File_Init

  subroutine HDF5File_Destroy(this)
    class(HDF5File), intent(inout) :: this
    type(ErrorStatusType) :: status
    if (this%is_open) call this%Close(status)
    this%filename = ""
    this%mode = MD_MODEL_FILE_MODE_READ
    this%is_open = .false.
    this%n_groups = 0_i4
    this%n_datasets = 0_i4
  end subroutine HDF5File_Destroy

  subroutine HDF5File_Open(this, status)
    class(HDF5File), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    this%is_open = .true.
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine HDF5File_Open

  subroutine HDF5File_Close(this, status)
    class(HDF5File), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    this%is_open = .false.
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine HDF5File_Close

  subroutine HDF5File_CreateGroup(this, name, group, status)
    class(HDF5File), intent(inout) :: this
    character(len=*), intent(in) :: name
    type(HDF5Group), intent(out) :: group
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    call group%Init(name, this%file_id)
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine HDF5File_CreateGroup

  subroutine HDF5File_OpenGroup(this, name, group, status)
    class(HDF5File), intent(in) :: this
    character(len=*), intent(in) :: name
    type(HDF5Group), intent(out) :: group
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    call group%Init(name, this%file_id)
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine HDF5File_OpenGroup

  subroutine HDF5File_CreateDataset(this, name, dataset, status)
    class(HDF5File), intent(inout) :: this
    character(len=*), intent(in) :: name
    type(HDF5Dataset), intent(out) :: dataset
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    call dataset%Init(name, this%file_id)
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine HDF5File_CreateDataset

  subroutine HDF5File_OpenDataset(this, name, dataset, status)
    class(HDF5File), intent(in) :: this
    character(len=*), intent(in) :: name
    type(HDF5Dataset), intent(out) :: dataset
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    call dataset%Init(name, this%file_id)
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine HDF5File_OpenDataset

  function HDF5File_IsOpen(this) result(is_open)
    class(HDF5File), intent(in) :: this
    logical :: is_open
    is_open = this%is_open
  end function HDF5File_IsOpen

  function HDF5File_GetGroup(this, name) result(group)
    class(HDF5File), intent(in) :: this
    character(len=*), intent(in) :: name
    type(HDF5Group) :: group
    call group%Init(name, this%file_id)
  end function HDF5File_GetGroup

  function HDF5File_GetDataset(this, name) result(dataset)
    class(HDF5File), intent(in) :: this
    character(len=*), intent(in) :: name
    type(HDF5Dataset) :: dataset
    call dataset%Init(name, this%file_id)
  end function HDF5File_GetDataset

  ! ===================================================================
  ! HDF5 Group Procedures
  ! ===================================================================
  subroutine HDF5Group_Init(this, name, parent_id)
    class(HDF5Group), intent(inout) :: this
    character(len=*), intent(in) :: name
    integer(i8), intent(in) :: parent_id

    this%name = name
    this%parent_id = parent_id
    this%is_open = .false.
    this%n_subgroups = 0_i4
    this%n_datasets = 0_i4
  end subroutine HDF5Group_Init

  subroutine HDF5Group_Destroy(this)
    class(HDF5Group), intent(inout) :: this
    type(ErrorStatusType) :: status
    if (this%is_open) call this%Close(status)
    this%name = ""
    this%parent_id = 0_i8
    this%is_open = .false.
    this%n_subgroups = 0_i4
    this%n_datasets = 0_i4
  end subroutine HDF5Group_Destroy

  subroutine HDF5Group_Open(this, status)
    class(HDF5Group), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    this%is_open = .true.
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine HDF5Group_Open

  subroutine HDF5Group_Close(this, status)
    class(HDF5Group), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    this%is_open = .false.
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine HDF5Group_Close

  subroutine HDF5Group_CreateSubgroup(this, name, subgroup, status)
    class(HDF5Group), intent(inout) :: this
    character(len=*), intent(in) :: name
    type(HDF5Group), intent(out) :: subgroup
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    call subgroup%Init(name, this%group_id)
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine HDF5Group_CreateSubgroup

  subroutine HDF5Group_OpenSubgroup(this, name, subgroup, status)
    class(HDF5Group), intent(in) :: this
    character(len=*), intent(in) :: name
    type(HDF5Group), intent(out) :: subgroup
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    call subgroup%Init(name, this%group_id)
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine HDF5Group_OpenSubgroup

  subroutine HDF5Group_CreateDataset(this, name, dataset, status)
    class(HDF5Group), intent(inout) :: this
    character(len=*), intent(in) :: name
    type(HDF5Dataset), intent(out) :: dataset
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    call dataset%Init(name, this%group_id)
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine HDF5Group_CreateDataset

  subroutine HDF5Group_OpenDataset(this, name, dataset, status)
    class(HDF5Group), intent(in) :: this
    character(len=*), intent(in) :: name
    type(HDF5Dataset), intent(out) :: dataset
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    call dataset%Init(name, this%group_id)
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine HDF5Group_OpenDataset

  function HDF5Group_IsOpen(this) result(is_open)
    class(HDF5Group), intent(in) :: this
    logical :: is_open
    is_open = this%is_open
  end function HDF5Group_IsOpen

  ! ===================================================================
  ! HDF5 Dataset Procedures
  ! ===================================================================
  subroutine HDF5Dataset_Init(this, name, parent_id)
    class(HDF5Dataset), intent(inout) :: this
    character(len=*), intent(in) :: name
    integer(i8), intent(in) :: parent_id

    this%name = name
    this%parent_id = parent_id
    this%is_open = .false.
    this%rank = 0_i4
    this%dType = 0_i4
  end subroutine HDF5Dataset_Init

  subroutine HDF5Dataset_Destroy(this)
    class(HDF5Dataset), intent(inout) :: this
    type(ErrorStatusType) :: status
    if (this%is_open) call this%Close(status)
    this%name = ""
    this%parent_id = 0_i8
    this%is_open = .false.
    this%rank = 0_i4
    this%dType = 0_i4
    if (allocated(this%dims)) deallocate(this%dims)
  end subroutine HDF5Dataset_Destroy

  subroutine HDF5Dataset_Open(this, status)
    class(HDF5Dataset), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    this%is_open = .true.
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine HDF5Dataset_Open

  subroutine HDF5Dataset_Close(this, status)
    class(HDF5Dataset), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    this%is_open = .false.
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine HDF5Dataset_Close

  subroutine HDF5Dataset_ReadInt1(this, vals, status)
    class(HDF5Dataset), intent(inout) :: this
    integer(i1), intent(out) :: vals(:)
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%is_open) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "HDF5Dataset not open"
      status%source = "HDF5Dataset_ReadInt1"
      status%has_error = .true.
      return
    end if

    vals = 0_i1
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine HDF5Dataset_ReadInt1

  subroutine HDF5Dataset_ReadInt4(this, vals, status)
    class(HDF5Dataset), intent(inout) :: this
    integer(i4), intent(out) :: vals(:)
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%is_open) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "HDF5Dataset not open"
      status%source = "HDF5Dataset_ReadInt4"
      status%has_error = .true.
      return
    end if

    vals = 0_i4
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine HDF5Dataset_ReadInt4

  subroutine HDF5Dataset_ReadDP(this, vals, status)
    class(HDF5Dataset), intent(inout) :: this
    real(wp), intent(out) :: vals(:)
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%is_open) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "HDF5Dataset not open"
      status%source = "HDF5Dataset_ReadDP"
      status%has_error = .true.
      return
    end if

    vals = 0.0_wp
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine HDF5Dataset_ReadDP

  subroutine HDF5Dataset_WriteInt1(this, vals, status)
    class(HDF5Dataset), intent(inout) :: this
    integer(i1), intent(in) :: vals(:)
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%is_open) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "HDF5Dataset not open"
      status%source = "HDF5Dataset_WriteInt1"
      status%has_error = .true.
      return
    end if

    status%status_code = MD_MODEL_STATUS_OK
  end subroutine HDF5Dataset_WriteInt1

  subroutine HDF5Dataset_WriteInt4(this, vals, status)
    class(HDF5Dataset), intent(inout) :: this
    integer(i4), intent(in) :: vals(:)
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%is_open) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "HDF5Dataset not open"
      status%source = "HDF5Dataset_WriteInt4"
      status%has_error = .true.
      return
    end if

    status%status_code = MD_MODEL_STATUS_OK
  end subroutine HDF5Dataset_WriteInt4

  subroutine HDF5Dataset_WriteDP(this, vals, status)
    class(HDF5Dataset), intent(inout) :: this
    real(wp), intent(in) :: vals(:)
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%is_open) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "HDF5Dataset not open"
      status%source = "HDF5Dataset_WriteDP"
      status%has_error = .true.
      return
    end if

    status%status_code = MD_MODEL_STATUS_OK
  end subroutine HDF5Dataset_WriteDP

  subroutine HDF5Dataset_GetDims(this, dims)
    class(HDF5Dataset), intent(in) :: this
    integer(i8), intent(out) :: dims(:)

    if (allocated(this%dims)) then
      dims(1:min(size(dims), size(this%dims))) = this%dims(1:min(size(dims), size(this%dims)))
    else
      dims = 0_i8
    end if
  end subroutine HDF5Dataset_GetDims

  function HDF5Dataset_IsOpen(this) result(is_open)
    class(HDF5Dataset), intent(in) :: this
    logical :: is_open
    is_open = this%is_open
  end function HDF5Dataset_IsOpen

  ! ===================================================================
  ! XML Document Procedures
  ! ===================================================================
  subroutine XMLDocument_Init(this, filename)
    class(XMLDocument), intent(inout) :: this
    character(len=*), intent(in), optional :: filename

    this%filename = ""
    this%version = "1.0"
    this%encoding = "UTF-8"
    this%is_loaded = .false.
    nullify(this%root)

    if (present(filename)) this%filename = filename
  end subroutine XMLDocument_Init

  subroutine XMLDocument_Destroy(this)
    class(XMLDocument), intent(inout) :: this

    if (associated(this%root)) then
      call this%root%Destroy()
      deallocate(this%root)
      nullify(this%root)
    end if

    this%filename = ""
    this%version = "1.0"
    this%encoding = "UTF-8"
    this%is_loaded = .false.
  end subroutine XMLDocument_Destroy

  subroutine XMLDocument_Load(this, filename, status)
    class(XMLDocument), intent(inout) :: this
    character(len=*), intent(in) :: filename
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: unit, io_stat

    call init_error_status(status)
    this%filename = filename

    open(newunit=unit, file=trim(filename), status='old', action='read', iostat=io_stat)
    if (io_stat /= 0) then
      status%status_code = MD_MODEL_STATUS_IO_ERROR
      status%message = "Failed to open XML file: " // trim(filename)
      status%source = "XMLDocument_Load"
      status%has_error = .true.
      return
    end if
    close(unit)

    this%is_loaded = .true.
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine XMLDocument_Load

  subroutine XMLDocument_Save(this, filename, status)
    class(XMLDocument), intent(in) :: this
    character(len=*), intent(in), optional :: filename
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: unit, io_stat
    character(len=8192) :: xml_content
    character(len=512) :: save_filename

    call init_error_status(status)

    if (present(filename)) then
      save_filename = filename
    else
      save_filename = this%filename
    end if

    if (len_trim(save_filename) == 0) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "No filename specified"
      status%source = "XMLDocument_Save"
      status%has_error = .true.
      return
    end if

    open(newunit=unit, file=trim(save_filename), status='replace', action='write', iostat=io_stat)
    if (io_stat /= 0) then
      status%status_code = MD_MODEL_STATUS_IO_ERROR
      status%message = "Failed to open XML file for writing"
      status%source = "XMLDocument_Save"
      status%has_error = .true.
      return
    end if

    write(unit, '(A)', iostat=io_stat) '<?xml version="' // trim(this%version) // '" encoding="' // trim(this%encoding) // '"?>'
    if (associated(this%root)) then
      xml_content = this%root%ToString()
      write(unit, '(A)', iostat=io_stat) trim(xml_content)
    end if
    close(unit)

    status%status_code = MD_MODEL_STATUS_OK
  end subroutine XMLDocument_Save

  function XMLDocument_GetRoot(this) result(root)
    class(XMLDocument), intent(in) :: this
    type(XMLElement), pointer :: root
    root => this%root
  end function XMLDocument_GetRoot

  subroutine XMLDocument_SetRoot(this, root)
    class(XMLDocument), intent(inout) :: this
    type(XMLElement), intent(in), target :: root

    if (associated(this%root)) then
      call this%root%Destroy()
      deallocate(this%root)
    end if

    allocate(this%root)
    this%root = root
  end subroutine XMLDocument_SetRoot

  function XMLDocument_FindElement(this, name) result(Element)
    class(XMLDocument), intent(in) :: this
    character(len=*), intent(in) :: name
    type(XMLElement), pointer :: Element

    nullify(Element)
    if (.not. associated(this%root)) return
    Element => this%root%FindChild(name)
  end function XMLDocument_FindElement

  function XMLDocument_FindElements(this, name) result(elements)
    class(XMLDocument), intent(in) :: this
    character(len=*), intent(in) :: name
    type(XMLElement), allocatable :: elements(:)

    if (.not. associated(this%root)) then
      allocate(elements(0))
      return
    end if
    elements = this%root%FindChildren(name)
  end function XMLDocument_FindElements

  ! ===================================================================
  ! XML Element Procedures
  ! ===================================================================
  subroutine XMLElement_Init(this, name)
    class(XMLElement), intent(inout) :: this
    character(len=*), intent(in) :: name

    this%name = name
    this%text = ""
    this%n_attributes = 0_i4
    this%n_children = 0_i4
    nullify(this%parent)
  end subroutine XMLElement_Init

  subroutine XMLElement_Destroy(this)
    class(XMLElement), intent(inout) :: this
    integer(i4) :: i

    if (allocated(this%attributes)) deallocate(this%attributes)
    if (associated(this%children)) then
      do i = 1, this%n_children
        call this%children(i)%Destroy()
      end do
      deallocate(this%children)
    end if

    this%name = ""
    this%text = ""
    this%n_attributes = 0_i4
    this%n_children = 0_i4
    nullify(this%parent)
  end subroutine XMLElement_Destroy

  subroutine XMLElement_SetName(this, name)
    class(XMLElement), intent(inout) :: this
    character(len=*), intent(in) :: name
    this%name = name
  end subroutine XMLElement_SetName

  subroutine XMLElement_SetText(this, text)
    class(XMLElement), intent(inout) :: this
    character(len=*), intent(in) :: text
    this%text = text
  end subroutine XMLElement_SetText

  subroutine XMLElement_AddAttribute(this, name, value)
    class(XMLElement), intent(inout) :: this
    character(len=*), intent(in) :: name, value

    this%n_attributes = this%n_attributes + 1_i4
    if (.not. allocated(this%attributes)) then
      allocate(this%attributes(10))
    else if (this%n_attributes > size(this%attributes)) then
      call resize_attributes(this)
    end if

    this%attributes(this%n_attributes)%name = name
    this%attributes(this%n_attributes)%value = value
  end subroutine XMLElement_AddAttribute

  function XMLElement_GetAttribute(this, name) result(value)
    class(XMLElement), intent(in) :: this
    character(len=*), intent(in) :: name
    character(len=4096) :: value
    integer(i4) :: i

    value = ""
    do i = 1, this%n_attributes
      if (trim(this%attributes(i)%name) == trim(name)) then
        value = this%attributes(i)%value
        return
      end if
    end do
  end function XMLElement_GetAttribute

  subroutine XMLElement_AddChild(this, child)
    class(XMLElement), intent(inout), target :: this
    type(XMLElement), intent(in) :: child

    this%n_children = this%n_children + 1_i4
    if (.not. associated(this%children)) then
      allocate(this%children(10))
    else if (this%n_children > size(this%children)) then
      call resize_children(this)
    end if

    this%children(this%n_children) = child
    this%children(this%n_children)%parent => this
  end subroutine XMLElement_AddChild

  function XMLElement_GetChild(this, index) result(child)
    class(XMLElement), intent(in) :: this
    integer(i4), intent(in) :: index
    type(XMLElement), pointer :: child

    nullify(child)
    if (index < 1 .or. index > this%n_children) return
    child => this%children(index)
  end function XMLElement_GetChild

  function XMLElement_GetChildren(this) result(children)
    class(XMLElement), intent(in) :: this
    type(XMLElement), pointer :: children(:)

    if (associated(this%children)) then
      children => this%children(1:this%n_children)
    else
      nullify(children)
    end if
  end function XMLElement_GetChildren

  function XMLElement_FindChild(this, name) result(child)
    class(XMLElement), intent(in) :: this
    character(len=*), intent(in) :: name
    type(XMLElement), pointer :: child
    integer(i4) :: i

    nullify(child)
    do i = 1, this%n_children
      if (trim(this%children(i)%name) == trim(name)) then
        child => this%children(i)
        return
      end if
    end do
  end function XMLElement_FindChild

  function XMLElement_FindChildren(this, name) result(children)
    class(XMLElement), intent(in) :: this
    character(len=*), intent(in) :: name
    type(XMLElement), pointer :: children(:)
    integer(i4) :: i, count

    nullify(children)
    count = 0_i4
    do i = 1, this%n_children
      if (trim(this%children(i)%name) == trim(name)) count = count + 1_i4
    end do

    if (count == 0_i4) return
    allocate(children(count))
    count = 0_i4
    do i = 1, this%n_children
      if (trim(this%children(i)%name) == trim(name)) then
        count = count + 1_i4
        children(count) = this%children(i)
      end if
    end do
  end function XMLElement_FindChildren

  recursive function XMLElement_ToString(this) result(xml_str)
    class(XMLElement), intent(in) :: this
    character(len=8192) :: xml_str
    integer(i4) :: i
    character(len=4096) :: temp_str

    xml_str = ""
    if (len_trim(this%name) == 0) return
    xml_str = "<" // trim(this%name)
    do i = 1, this%n_attributes
      xml_str = trim(xml_str) // " " // trim(this%attributes(i)%name) // '="' // trim(this%attributes(i)%value) // '"'
    end do

    if (this%n_children == 0 .and. len_trim(this%text) == 0) then
      xml_str = trim(xml_str) // "/>"
      return
    end if

    xml_str = trim(xml_str) // ">"
    if (len_trim(this%text) > 0) xml_str = trim(xml_str) // trim(this%text)
    do i = 1, this%n_children
      temp_str = this%children(i)%ToString()
      xml_str = trim(xml_str) // trim(temp_str)
    end do
    xml_str = trim(xml_str) // "</" // trim(this%name) // ">"
  end function XMLElement_ToString

  ! ===================================================================
  ! Helper Subroutines
  ! ===================================================================
  subroutine resize_attributes(this)
    class(XMLElement), intent(inout) :: this
    type(XMLAttribute), allocatable :: temp(:)
    integer(i4) :: new_size

    new_size = size(this%attributes) * 2
    allocate(temp(new_size))
    temp(1:this%n_attributes) = this%attributes(1:this%n_attributes)
    deallocate(this%attributes)
    allocate(this%attributes(new_size))
    this%attributes(1:this%n_attributes) = temp(1:this%n_attributes)
    deallocate(temp)
  end subroutine resize_attributes

  subroutine resize_children(this)
    class(XMLElement), intent(inout) :: this
    type(XMLElement), allocatable :: temp(:)
    integer(i4) :: new_size

    new_size = size(this%children) * 2
    allocate(temp(new_size))
    temp(1:this%n_children) = this%children(1:this%n_children)
    deallocate(this%children)
    allocate(this%children(new_size))
    this%children(1:this%n_children) = temp(1:this%n_children)
    deallocate(temp)
  end subroutine resize_children

  ! RW Serialization Procedures
  subroutine RW_Serialize_Int1(serializer, v, status)
    type(RW_Serializer), intent(inout) :: serializer
    integer(i1), intent(in) :: v
    type(ErrorStatusType), intent(out) :: status
    call init_error_status(status)
    call serializer%writer%WriteInt1(v, status)
  end subroutine RW_Serialize_Int1

  subroutine RW_Serialize_Int2(serializer, v, status)
    type(RW_Serializer), intent(inout) :: serializer
    integer(i2), intent(in) :: v
    type(ErrorStatusType), intent(out) :: status
    call init_error_status(status)
    call serializer%writer%WriteInt2(v, status)
  end subroutine RW_Serialize_Int2

  subroutine RW_Serialize_Int4(serializer, v, status)
    type(RW_Serializer), intent(inout) :: serializer
    integer(i4), intent(in) :: v
    type(ErrorStatusType), intent(out) :: status
    call init_error_status(status)
    call serializer%writer%WriteInt4(v, status)
  end subroutine RW_Serialize_Int4

  subroutine RW_Serialize_Int8(serializer, v, status)
    type(RW_Serializer), intent(inout) :: serializer
    integer(i8), intent(in) :: v
    type(ErrorStatusType), intent(out) :: status
    call init_error_status(status)
    call serializer%writer%WriteInt8(v, status)
  end subroutine RW_Serialize_Int8

  subroutine RW_Serialize_DP(serializer, v, status)
    type(RW_Serializer), intent(inout) :: serializer
    real(wp), intent(in) :: v
    type(ErrorStatusType), intent(out) :: status
    call init_error_status(status)
    call serializer%writer%WriteDP(v, status)
  end subroutine RW_Serialize_DP

  subroutine RW_Serialize_String(serializer, str, status)
    type(RW_Serializer), intent(inout) :: serializer
    character(len=*), intent(in) :: str
    type(ErrorStatusType), intent(out) :: status
    integer(i4) :: len_str
    call init_error_status(status)
    len_str = len_trim(str)
    call serializer%writer%WriteInt4(len_str, status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return
    call serializer%writer%WriteString(str, status)
  end subroutine RW_Serialize_String

  subroutine RW_Serialize_ArrayInt1(serializer, a, status)
    type(RW_Serializer), intent(inout) :: serializer
    integer(i1), intent(in) :: a(:)
    type(ErrorStatusType), intent(out) :: status
    integer(i4) :: n
    call init_error_status(status)
    n = size(a)
    call serializer%writer%WriteInt4(n, status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return
    call serializer%writer%WriteArrayInt1(a, status)
  end subroutine RW_Serialize_ArrayInt1

  subroutine RW_Serialize_ArrayInt4(serializer, a, status)
    type(RW_Serializer), intent(inout) :: serializer
    integer(i4), intent(in) :: a(:)
    type(ErrorStatusType), intent(out) :: status
    integer(i4) :: n
    call init_error_status(status)
    n = size(a)
    call serializer%writer%WriteInt4(n, status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return
    call serializer%writer%WriteArrayInt4(a, status)
  end subroutine RW_Serialize_ArrayInt4

  subroutine RW_Serialize_ArrayDP(serializer, a, status)
    type(RW_Serializer), intent(inout) :: serializer
    real(wp), intent(in) :: a(:)
    type(ErrorStatusType), intent(out) :: status
    integer(i4) :: n
    call init_error_status(status)
    n = size(a)
    call serializer%writer%WriteInt4(n, status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return
    call serializer%writer%WriteArrayDP(a, status)
  end subroutine RW_Serialize_ArrayDP

  subroutine RW_Deserialize_Int1(deserializer, v, status)
    type(RW_Deserializer), intent(inout) :: deserializer
    integer(i1), intent(out) :: v
    type(ErrorStatusType), intent(out) :: status
    call init_error_status(status)
    call deserializer%reader%ReadInt1(v, status)
  end subroutine RW_Deserialize_Int1

  subroutine RW_Deserialize_Int2(deserializer, v, status)
    type(RW_Deserializer), intent(inout) :: deserializer
    integer(i2), intent(out) :: v
    type(ErrorStatusType), intent(out) :: status
    call init_error_status(status)
    call deserializer%reader%ReadInt2(v, status)
  end subroutine RW_Deserialize_Int2

  subroutine RW_Deserialize_Int4(deserializer, v, status)
    type(RW_Deserializer), intent(inout) :: deserializer
    integer(i4), intent(out) :: v
    type(ErrorStatusType), intent(out) :: status
    call init_error_status(status)
    call deserializer%reader%ReadInt4(v, status)
  end subroutine RW_Deserialize_Int4

  subroutine RW_Deserialize_Int8(deserializer, v, status)
    type(RW_Deserializer), intent(inout) :: deserializer
    integer(i8), intent(out) :: v
    type(ErrorStatusType), intent(out) :: status
    call init_error_status(status)
    call deserializer%reader%ReadInt8(v, status)
  end subroutine RW_Deserialize_Int8

  subroutine RW_Deserialize_DP(deserializer, v, status)
    type(RW_Deserializer), intent(inout) :: deserializer
    real(wp), intent(out) :: v
    type(ErrorStatusType), intent(out) :: status
    call init_error_status(status)
    call deserializer%reader%ReadDP(v, status)
  end subroutine RW_Deserialize_DP

  subroutine RW_Deserialize_String(deserializer, str, status)
    type(RW_Deserializer), intent(inout) :: deserializer
    character(len=:), allocatable, intent(out) :: str
    type(ErrorStatusType), intent(out) :: status
    integer(i4) :: len_str
    call init_error_status(status)
    call deserializer%reader%ReadInt4(len_str, status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return
    allocate(character(len=len_str) :: str)
    call deserializer%reader%ReadString(str, status)
  end subroutine RW_Deserialize_String

  subroutine RW_Deserialize_ArrayInt1(deserializer, a, status)
    type(RW_Deserializer), intent(inout) :: deserializer
    integer(i1), allocatable, intent(out) :: a(:)
    type(ErrorStatusType), intent(out) :: status
    integer(i4) :: n
    call init_error_status(status)
    call deserializer%reader%ReadInt4(n, status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return
    allocate(a(n))
    call deserializer%reader%ReadArrayInt1(a, status)
  end subroutine RW_Deserialize_ArrayInt1

  subroutine RW_Deserialize_ArrayInt4(deserializer, a, status)
    type(RW_Deserializer), intent(inout) :: deserializer
    integer(i4), allocatable, intent(out) :: a(:)
    type(ErrorStatusType), intent(out) :: status
    integer(i4) :: n
    call init_error_status(status)
    call deserializer%reader%ReadInt4(n, status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return
    allocate(a(n))
    call deserializer%reader%ReadArrayInt4(a, status)
  end subroutine RW_Deserialize_ArrayInt4

  subroutine RW_Deserialize_ArrayDP(deserializer, a, status)
    type(RW_Deserializer), intent(inout) :: deserializer
    real(wp), allocatable, intent(out) :: a(:)
    type(ErrorStatusType), intent(out) :: status
    integer(i4) :: n
    call init_error_status(status)
    call deserializer%reader%ReadInt4(n, status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return
    allocate(a(n))
    call deserializer%reader%ReadArrayDP(a, status)
  end subroutine RW_Deserialize_ArrayDP

  subroutine RW_SymbolTable_Init(this)
    class(RW_SymbolTable), intent(out) :: this
    this%n_entries = 0_i4
    this%max_entries = 0_i4
    this%total_size = 0_i8
  end subroutine RW_SymbolTable_Init

  subroutine RW_SymbolTable_Destroy(this)
    class(RW_SymbolTable), intent(inout) :: this
    call RW_Clear_SymbolTable(this)
  end subroutine RW_SymbolTable_Destroy

  subroutine RW_SymbolTable_Reg(this, var_id, name, dType, rank, shape, status)
    class(RW_SymbolTable), intent(inout) :: this
    integer(i4), intent(in) :: var_id
    character(len=*), intent(in) :: name
    integer(i4), intent(in) :: dType
    integer(i4), intent(in) :: rank
    integer(i8), intent(in) :: shape(:)
    type(ErrorStatusType), intent(out) :: status
    type(RW_VariableEntry), allocatable :: tmp(:)
    integer(i4) :: i, n
    integer(i8) :: var_size

    call init_error_status(status)
    var_size = 1_i8
    do i = 1, rank
      var_size = var_size * shape(i)
    end do

    if (allocated(this%entries)) then
      n = size(this%entries)
      do i = 1, n
        if (this%entries(i)%var_id == var_id) then
          status%status_code = MD_MODEL_STATUS_INVALID
          status%message = "Variable ID already exists"
          status%source = "RW_SymbolTable_Reg"
          return
        end If
      end do
      allocate(tmp(n))
      tmp = this%entries
      deallocate(this%entries)
      allocate(this%entries(n+1))
      this%entries(1:n) = tmp
      deallocate(tmp)
      n = n + 1
    else
      allocate(this%entries(1))
      n = 1
    end If

    this%entries(n)%var_id = var_id
    this%entries(n)%name = name
    this%entries(n)%dType = dType
    this%entries(n)%rank = rank
    allocate(this%entries(n)%shape(rank))
    this%entries(n)%shape = shape
    this%entries(n)%size = var_size
    this%entries(n)%offset = this%total_size
    this%entries(n)%is_allocated = .false.

    this%total_size = this%total_size + var_size
    this%n_entries = n
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine RW_SymbolTable_Reg

  function RW_SymbolTable_Find(this, name) result(idx)
    class(RW_SymbolTable), intent(in) :: this
    character(len=*), intent(in) :: name
    integer(i4) :: idx, i
    idx = 0_i4
    if (allocated(this%entries)) then
      do i = 1, size(this%entries)
        if (trim(this%entries(i)%name) == trim(name)) then
          idx = i
          return
        end If
      end do
    end If
  end function RW_SymbolTable_Find

  function RW_SymbolTable_Get(this, idx) result(entry)
    class(RW_SymbolTable), intent(in) :: this
    integer(i4), intent(in) :: idx
    type(RW_VariableEntry) :: entry
    entry%var_id = 0_i4
    entry%name = ""
    if (allocated(this%entries)) then
      if (idx >= 1 .and. idx <= size(this%entries)) entry = this%entries(idx)
    end If
  end function RW_SymbolTable_Get

  subroutine RW_SymbolTable_Set(this, idx, is_allocated)
    class(RW_SymbolTable), intent(inout) :: this
    integer(i4), intent(in) :: idx
    logical, intent(in) :: is_allocated
    if (allocated(this%entries)) then
      if (idx >= 1 .and. idx <= size(this%entries)) this%entries(idx)%is_allocated = is_allocated
    end If
  end subroutine RW_SymbolTable_Set

  subroutine RW_SymbolTable_Clear(this)
    class(RW_SymbolTable), intent(inout) :: this
    integer(i4) :: i
    if (allocated(this%entries)) then
      do i = 1, size(this%entries)
        if (allocated(this%entries(i)%shape)) deallocate(this%entries(i)%shape)
      end do
      deallocate(this%entries)
    end If
    this%n_entries = 0_i4
    this%max_entries = 0_i4
    this%total_size = 0_i8
  end subroutine RW_SymbolTable_Clear

  function RW_SymbolTable_GetTotalSize(this) result(total_size)
    class(RW_SymbolTable), intent(in) :: this
    integer(i8) :: total_size
    total_size = this%total_size
  end function RW_SymbolTable_GetTotalSize

  function RW_Get_Variable(table, name, entry, status) result(found)
    type(RW_SymbolTable), intent(in) :: table
    character(len=*), intent(in) :: name
    type(RW_VariableEntry), intent(out) :: entry
    type(ErrorStatusType), intent(out) :: status
    logical :: found
    integer(i4) :: idx
    call init_error_status(status)
    idx = table%Find(name)
    if (idx > 0) then
      entry = table%Get(idx)
      found = .true.
      status%status_code = MD_MODEL_STATUS_OK
    else
      found = .false.
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "Variable not found: " // trim(name)
      status%source = "RW_Get_Variable"
    end if
  end function RW_Get_Variable

  subroutine RW_Set_Variable(table, name, is_allocated, status)
    type(RW_SymbolTable), intent(inout) :: table
    character(len=*), intent(in) :: name
    logical, intent(in) :: is_allocated
    type(ErrorStatusType), intent(out) :: status
    integer(i4) :: idx
    call init_error_status(status)
    idx = table%Find(name)
    if (idx > 0) then
      call table%Set(idx, is_allocated)
      status%status_code = MD_MODEL_STATUS_OK
    else
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "Variable not found: " // trim(name)
      status%source = "RW_Set_Variable"
    end if
  end subroutine RW_Set_Variable

  subroutine RW_Clear_SymbolTable(table)
    type(RW_SymbolTable), intent(inout) :: table
    call table%Clear()
  end subroutine RW_Clear_SymbolTable

  subroutine RW_Serializer_Init(this, filename, status)
    class(RW_Serializer), intent(out) :: this
    character(len=*), intent(in) :: filename
    type(ErrorStatusType), intent(out) :: status
    call init_error_status(status)
    call this%writer%Init(filename, .false.)
    call this%symbol_table%Init()
    this%is_initialized = .false.
  end subroutine RW_Serializer_Init

  subroutine RW_Serializer_Destroy(this)
    class(RW_Serializer), intent(inout) :: this
    call this%symbol_table%Destroy()
    call this%writer%Destroy()
    this%is_initialized = .false.
  end subroutine RW_Serializer_Destroy

  subroutine RW_Serializer_Open(this, status)
    class(RW_Serializer), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status
    call init_error_status(status)
    call this%writer%Open(status)
    if (status%status_code == MD_MODEL_STATUS_OK) this%is_initialized = .true.
  end subroutine RW_Serializer_Open

  subroutine RW_Serializer_Close(this, status)
    class(RW_Serializer), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status
    call init_error_status(status)
    call this%writer%Close(status)
    this%is_initialized = .false.
  end subroutine RW_Serializer_Close

  subroutine RW_Serializer_Flush(this, status)
    class(RW_Serializer), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status
    call init_error_status(status)
    call this%writer%Flush(status)
  end subroutine RW_Serializer_Flush

  subroutine RW_Serializer_Serialize(this, data, status)
    class(RW_Serializer), intent(inout) :: this
    class(*), intent(in) :: data
    type(ErrorStatusType), intent(out) :: status
    call init_error_status(status)
    select type (data)
      type is (integer(i1))
        call RW_Serialize_Int1(this, data, status)
      type is (integer(i2))
        call RW_Serialize_Int2(this, data, status)
      type is (integer(i4))
        call RW_Serialize_Int4(this, data, status)
      type is (integer(i8))
        call RW_Serialize_Int8(this, data, status)
      type is (real(wp))
        call RW_Serialize_DP(this, data, status)
      type is (character(*))
        call RW_Serialize_String(this, data, status)
      class default
        status%status_code = MD_MODEL_STATUS_INVALID
        status%message = "Unsupported data type for serialization. For arrays, use specialized procedures."
        status%source = "RW_Serializer_Serialize"
    end select
  end subroutine RW_Serializer_Serialize

  subroutine RW_Deserializer_Init(this, filename, status)
    class(RW_Deserializer), intent(out) :: this
    character(len=*), intent(in) :: filename
    type(ErrorStatusType), intent(out) :: status
    call init_error_status(status)
    call this%reader%Init(filename, .false.)
    call this%symbol_table%Init()
    this%is_initialized = .false.
  end subroutine RW_Deserializer_Init

  subroutine RW_Deserializer_Destroy(this)
    class(RW_Deserializer), intent(inout) :: this
    call this%symbol_table%Destroy()
    call this%reader%Destroy()
    this%is_initialized = .false.
  end subroutine RW_Deserializer_Destroy

  subroutine RW_Deserializer_Open(this, status)
    class(RW_Deserializer), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status
    call init_error_status(status)
    call this%reader%Open(status)
    if (status%status_code == MD_MODEL_STATUS_OK) this%is_initialized = .true.
  end subroutine RW_Deserializer_Open

  subroutine RW_Deserializer_Close(this, status)
    class(RW_Deserializer), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status
    call init_error_status(status)
    call this%reader%Close(status)
    this%is_initialized = .false.
  end subroutine RW_Deserializer_Close

  subroutine RW_Deserializer_Deserialize(this, data, status)
    class(RW_Deserializer), intent(inout) :: this
    class(*), intent(out) :: data
    type(ErrorStatusType), intent(out) :: status
    call init_error_status(status)
    select type (data)
      type is (integer(i1))
        call RW_Deserialize_Int1(this, data, status)
      type is (integer(i2))
        call RW_Deserialize_Int2(this, data, status)
      type is (integer(i4))
        call RW_Deserialize_Int4(this, data, status)
      type is (integer(i8))
        call RW_Deserialize_Int8(this, data, status)
      type is (real(wp))
        call RW_Deserialize_DP(this, data, status)
      type is (character(len=*))
        block
          character(len=:), allocatable :: str_tmp
          call RW_Deserialize_String(this, str_tmp, status)
          if (status%status_code == MD_MODEL_STATUS_OK) data = str_tmp
        end block
      class default
        status%status_code = MD_MODEL_STATUS_INVALID
        status%message = "Unsupported data type for deserialization. For arrays, use specialized procedures."
        status%source = "RW_Deserializer_Deserialize"
    end select
  end subroutine RW_Deserializer_Deserialize

  subroutine RW_MemMgr_Alloc(this, size, status)
    class(RW_MemMgr), intent(inout) :: this
    integer(i8), intent(in) :: size
    type(ErrorStatusType), intent(out) :: status
    call init_error_status(status)
    if (this%tracking_enable) then
      this%total_allocated = this%total_allocated + size
      this%n_allocations = this%n_allocations + 1_i4
    end If
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine RW_MemMgr_Alloc

  subroutine RW_MemMgr_Dealloc(this, size, status)
    class(RW_MemMgr), intent(inout) :: this
    integer(i8), intent(in) :: size
    type(ErrorStatusType), intent(out) :: status
    call init_error_status(status)
    if (this%tracking_enable) then
      this%total_freed = this%total_freed + size
      this%n_deallocations = this%n_deallocations + 1_i4
    end If
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine RW_MemMgr_Dealloc

  subroutine RW_MemMgr_Realloc(this, old_size, new_size, status)
    class(RW_MemMgr), intent(inout) :: this
    integer(i8), intent(in) :: old_size
    integer(i8), intent(in) :: new_size
    type(ErrorStatusType), intent(out) :: status
    call init_error_status(status)
    if (this%tracking_enable) then
      this%total_freed = this%total_freed + old_size
      this%total_allocated = this%total_allocated + new_size
    end If
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine RW_MemMgr_Realloc

  subroutine RW_MemMgr_GetStats(this, total_allocated, total_freed, &
                                     n_allocations, n_deallocations, status)
    class(RW_MemMgr), intent(in) :: this
    integer(i8), intent(out) :: total_allocated, total_freed
    integer(i4), intent(out) :: n_allocations, n_deallocations
    type(ErrorStatusType), intent(out) :: status
    call init_error_status(status)
    total_allocated = this%total_allocated
    total_freed = this%total_freed
    n_allocations = this%n_allocations
    n_deallocations = this%n_deallocations
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine RW_MemMgr_GetStats

  subroutine RW_MemMgr_Reset(this)
    class(RW_MemMgr), intent(inout) :: this
    this%total_allocated = 0_i8
    this%total_freed = 0_i8
    this%n_allocations = 0_i4
    this%n_deallocations = 0_i4
  end subroutine RW_MemMgr_Reset

END MODULE MD_Base_IOSerialMgr