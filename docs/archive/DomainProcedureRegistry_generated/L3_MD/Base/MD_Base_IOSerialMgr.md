# `MD_Base_IOSerialMgr.f90`

- **Source**: `L3_MD/Base/MD_Base_IOSerialMgr.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `MD_Base_IOSerialMgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Base_IOSerialMgr`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Base_IOSerialMgr`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Base`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Base/MD_Base_IOSerialMgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `FileHandle` (lines 198–218)

```fortran
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
```

### `BinaryReader` (lines 224–243)

```fortran
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
```

### `BinaryWriter` (lines 249–269)

```fortran
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
```

### `HDF5File` (lines 275–294)

```fortran
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
```

### `HDF5Group` (lines 300–317)

```fortran
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
```

### `HDF5Dataset` (lines 323–344)

```fortran
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
```

### `XMLAttribute` (lines 350–353)

```fortran
  type :: XMLAttribute
    character(len=256) :: name = ""
    character(len=4096) :: value = ""
  end type XMLAttribute
```

### `XMLElement` (lines 359–380)

```fortran
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
```

### `XMLDocument` (lines 386–401)

```fortran
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
```

### `RW_VariableEntry` (lines 409–418)

```fortran
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
```

### `RW_SymbolTable` (lines 420–434)

```fortran
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
```

### `RW_Serializer` (lines 436–447)

```fortran
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
```

### `RW_Deserializer` (lines 449–459)

```fortran
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
```

### `RW_MemMgr` (lines 461–473)

```fortran
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
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `FileHandle_Init` | 500 | `subroutine FileHandle_Init(this, filename, mode, file_type)` |
| SUBROUTINE | `FileHandle_Destroy` | 516 | `subroutine FileHandle_Destroy(this)` |
| SUBROUTINE | `FileHandle_Open` | 528 | `subroutine FileHandle_Open(this, status)` |
| SUBROUTINE | `FileHandle_Close` | 567 | `subroutine FileHandle_Close(this, status)` |
| SUBROUTINE | `FileHandle_ReadLine` | 592 | `subroutine FileHandle_ReadLine(this, line, status)` |
| SUBROUTINE | `FileHandle_WriteLine` | 620 | `subroutine FileHandle_WriteLine(this, line, status)` |
| FUNCTION | `FileHandle_IsOpen` | 648 | `function FileHandle_IsOpen(this) result(is_open)` |
| FUNCTION | `FileHandle_GetSize` | 654 | `function FileHandle_GetSize(this) result(file_size)` |
| FUNCTION | `FileHandle_GetPosition` | 660 | `function FileHandle_GetPosition(this) result(current_pos)` |
| SUBROUTINE | `FileHandle_Seek` | 666 | `subroutine FileHandle_Seek(this, position, status)` |
| SUBROUTINE | `FileHandle_Flush` | 677 | `subroutine FileHandle_Flush(this, status)` |
| SUBROUTINE | `BR_Init` | 707 | `subroutine BR_Init(this, filename, big_endian)` |
| SUBROUTINE | `BR_Destroy` | 720 | `subroutine BR_Destroy(this)` |
| SUBROUTINE | `BR_Open` | 727 | `subroutine BR_Open(this, status)` |
| SUBROUTINE | `BR_Close` | 738 | `subroutine BR_Close(this, status)` |
| SUBROUTINE | `BR_ReadInt1` | 747 | `subroutine BR_ReadInt1(this, value, status)` |
| SUBROUTINE | `BR_ReadInt2` | 772 | `subroutine BR_ReadInt2(this, value, status)` |
| SUBROUTINE | `BR_ReadInt4` | 797 | `subroutine BR_ReadInt4(this, value, status)` |
| SUBROUTINE | `BR_ReadInt8` | 822 | `subroutine BR_ReadInt8(this, value, status)` |
| SUBROUTINE | `BR_ReadDP` | 847 | `subroutine BR_ReadDP(this, value, status)` |
| SUBROUTINE | `BR_ReadArrInt1` | 872 | `subroutine BR_ReadArrInt1(this, array, status)` |
| SUBROUTINE | `BR_ReadArrInt4` | 897 | `subroutine BR_ReadArrInt4(this, array, status)` |
| SUBROUTINE | `BR_ReadArrDP` | 922 | `subroutine BR_ReadArrDP(this, array, status)` |
| SUBROUTINE | `BR_ReadStr` | 947 | `subroutine BR_ReadStr(this, str, status)` |
| FUNCTION | `BR_IsOpen` | 996 | `function BR_IsOpen(this) result(is_open)` |
| SUBROUTINE | `BW_Init` | 1006 | `subroutine BW_Init(this, filename, big_endian)` |
| SUBROUTINE | `BW_Destroy` | 1019 | `subroutine BW_Destroy(this)` |
| SUBROUTINE | `BW_Open` | 1026 | `subroutine BW_Open(this, status)` |
| SUBROUTINE | `BW_Close` | 1037 | `subroutine BW_Close(this, status)` |
| SUBROUTINE | `BW_WriteInt1` | 1046 | `subroutine BW_WriteInt1(this, value, status)` |
| SUBROUTINE | `BW_WriteInt2` | 1071 | `subroutine BW_WriteInt2(this, value, status)` |
| SUBROUTINE | `BW_WriteInt4` | 1096 | `subroutine BW_WriteInt4(this, value, status)` |
| SUBROUTINE | `BW_WriteInt8` | 1121 | `subroutine BW_WriteInt8(this, value, status)` |
| SUBROUTINE | `BW_WriteDP` | 1146 | `subroutine BW_WriteDP(this, value, status)` |
| SUBROUTINE | `BW_WriteArrInt1` | 1171 | `subroutine BW_WriteArrInt1(this, array, status)` |
| SUBROUTINE | `BW_WriteArrInt4` | 1196 | `subroutine BW_WriteArrInt4(this, array, status)` |
| SUBROUTINE | `BW_WriteArrDP` | 1221 | `subroutine BW_WriteArrDP(this, array, status)` |
| SUBROUTINE | `BW_WriteStr` | 1246 | `subroutine BW_WriteStr(this, str, status)` |
| FUNCTION | `BW_IsOpen` | 1288 | `function BW_IsOpen(this) result(is_open)` |
| SUBROUTINE | `BW_Flush` | 1295 | `subroutine BW_Flush(this, status)` |
| SUBROUTINE | `HDF5File_Init` | 1306 | `subroutine HDF5File_Init(this, filename, mode)` |
| SUBROUTINE | `HDF5File_Destroy` | 1320 | `subroutine HDF5File_Destroy(this)` |
| SUBROUTINE | `HDF5File_Open` | 1331 | `subroutine HDF5File_Open(this, status)` |
| SUBROUTINE | `HDF5File_Close` | 1340 | `subroutine HDF5File_Close(this, status)` |
| SUBROUTINE | `HDF5File_CreateGroup` | 1349 | `subroutine HDF5File_CreateGroup(this, name, group, status)` |
| SUBROUTINE | `HDF5File_OpenGroup` | 1360 | `subroutine HDF5File_OpenGroup(this, name, group, status)` |
| SUBROUTINE | `HDF5File_CreateDataset` | 1371 | `subroutine HDF5File_CreateDataset(this, name, dataset, status)` |
| SUBROUTINE | `HDF5File_OpenDataset` | 1382 | `subroutine HDF5File_OpenDataset(this, name, dataset, status)` |
| FUNCTION | `HDF5File_IsOpen` | 1393 | `function HDF5File_IsOpen(this) result(is_open)` |
| FUNCTION | `HDF5File_GetGroup` | 1399 | `function HDF5File_GetGroup(this, name) result(group)` |
| FUNCTION | `HDF5File_GetDataset` | 1406 | `function HDF5File_GetDataset(this, name) result(dataset)` |
| SUBROUTINE | `HDF5Group_Init` | 1416 | `subroutine HDF5Group_Init(this, name, parent_id)` |
| SUBROUTINE | `HDF5Group_Destroy` | 1428 | `subroutine HDF5Group_Destroy(this)` |
| SUBROUTINE | `HDF5Group_Open` | 1439 | `subroutine HDF5Group_Open(this, status)` |
| SUBROUTINE | `HDF5Group_Close` | 1448 | `subroutine HDF5Group_Close(this, status)` |
| SUBROUTINE | `HDF5Group_CreateSubgroup` | 1457 | `subroutine HDF5Group_CreateSubgroup(this, name, subgroup, status)` |
| SUBROUTINE | `HDF5Group_OpenSubgroup` | 1468 | `subroutine HDF5Group_OpenSubgroup(this, name, subgroup, status)` |
| SUBROUTINE | `HDF5Group_CreateDataset` | 1479 | `subroutine HDF5Group_CreateDataset(this, name, dataset, status)` |
| SUBROUTINE | `HDF5Group_OpenDataset` | 1490 | `subroutine HDF5Group_OpenDataset(this, name, dataset, status)` |
| FUNCTION | `HDF5Group_IsOpen` | 1501 | `function HDF5Group_IsOpen(this) result(is_open)` |
| SUBROUTINE | `HDF5Dataset_Init` | 1510 | `subroutine HDF5Dataset_Init(this, name, parent_id)` |
| SUBROUTINE | `HDF5Dataset_Destroy` | 1522 | `subroutine HDF5Dataset_Destroy(this)` |
| SUBROUTINE | `HDF5Dataset_Open` | 1534 | `subroutine HDF5Dataset_Open(this, status)` |
| SUBROUTINE | `HDF5Dataset_Close` | 1543 | `subroutine HDF5Dataset_Close(this, status)` |
| SUBROUTINE | `HDF5Dataset_ReadInt1` | 1552 | `subroutine HDF5Dataset_ReadInt1(this, vals, status)` |
| SUBROUTINE | `HDF5Dataset_ReadInt4` | 1571 | `subroutine HDF5Dataset_ReadInt4(this, vals, status)` |
| SUBROUTINE | `HDF5Dataset_ReadDP` | 1590 | `subroutine HDF5Dataset_ReadDP(this, vals, status)` |
| SUBROUTINE | `HDF5Dataset_WriteInt1` | 1609 | `subroutine HDF5Dataset_WriteInt1(this, vals, status)` |
| SUBROUTINE | `HDF5Dataset_WriteInt4` | 1627 | `subroutine HDF5Dataset_WriteInt4(this, vals, status)` |
| SUBROUTINE | `HDF5Dataset_WriteDP` | 1645 | `subroutine HDF5Dataset_WriteDP(this, vals, status)` |
| SUBROUTINE | `HDF5Dataset_GetDims` | 1663 | `subroutine HDF5Dataset_GetDims(this, dims)` |
| FUNCTION | `HDF5Dataset_IsOpen` | 1674 | `function HDF5Dataset_IsOpen(this) result(is_open)` |
| SUBROUTINE | `XMLDocument_Init` | 1683 | `subroutine XMLDocument_Init(this, filename)` |
| SUBROUTINE | `XMLDocument_Destroy` | 1696 | `subroutine XMLDocument_Destroy(this)` |
| SUBROUTINE | `XMLDocument_Load` | 1711 | `subroutine XMLDocument_Load(this, filename, status)` |
| SUBROUTINE | `XMLDocument_Save` | 1735 | `subroutine XMLDocument_Save(this, filename, status)` |
| FUNCTION | `XMLDocument_GetRoot` | 1779 | `function XMLDocument_GetRoot(this) result(root)` |
| SUBROUTINE | `XMLDocument_SetRoot` | 1785 | `subroutine XMLDocument_SetRoot(this, root)` |
| FUNCTION | `XMLDocument_FindElement` | 1798 | `function XMLDocument_FindElement(this, name) result(Element)` |
| FUNCTION | `XMLDocument_FindElements` | 1808 | `function XMLDocument_FindElements(this, name) result(elements)` |
| SUBROUTINE | `XMLElement_Init` | 1823 | `subroutine XMLElement_Init(this, name)` |
| SUBROUTINE | `XMLElement_Destroy` | 1834 | `subroutine XMLElement_Destroy(this)` |
| SUBROUTINE | `XMLElement_SetName` | 1853 | `subroutine XMLElement_SetName(this, name)` |
| SUBROUTINE | `XMLElement_SetText` | 1859 | `subroutine XMLElement_SetText(this, text)` |
| SUBROUTINE | `XMLElement_AddAttribute` | 1865 | `subroutine XMLElement_AddAttribute(this, name, value)` |
| FUNCTION | `XMLElement_GetAttribute` | 1880 | `function XMLElement_GetAttribute(this, name) result(value)` |
| SUBROUTINE | `XMLElement_AddChild` | 1895 | `subroutine XMLElement_AddChild(this, child)` |
| FUNCTION | `XMLElement_GetChild` | 1910 | `function XMLElement_GetChild(this, index) result(child)` |
| FUNCTION | `XMLElement_GetChildren` | 1920 | `function XMLElement_GetChildren(this) result(children)` |
| FUNCTION | `XMLElement_FindChild` | 1931 | `function XMLElement_FindChild(this, name) result(child)` |
| FUNCTION | `XMLElement_FindChildren` | 1946 | `function XMLElement_FindChildren(this, name) result(children)` |
| FUNCTION | `XMLElement_ToString` | 1969 | `recursive function XMLElement_ToString(this) result(xml_str)` |
| SUBROUTINE | `resize_attributes` | 1999 | `subroutine resize_attributes(this)` |
| SUBROUTINE | `resize_children` | 2013 | `subroutine resize_children(this)` |
| SUBROUTINE | `RW_Serialize_Int1` | 2028 | `subroutine RW_Serialize_Int1(serializer, v, status)` |
| SUBROUTINE | `RW_Serialize_Int2` | 2036 | `subroutine RW_Serialize_Int2(serializer, v, status)` |
| SUBROUTINE | `RW_Serialize_Int4` | 2044 | `subroutine RW_Serialize_Int4(serializer, v, status)` |
| SUBROUTINE | `RW_Serialize_Int8` | 2052 | `subroutine RW_Serialize_Int8(serializer, v, status)` |
| SUBROUTINE | `RW_Serialize_DP` | 2060 | `subroutine RW_Serialize_DP(serializer, v, status)` |
| SUBROUTINE | `RW_Serialize_String` | 2068 | `subroutine RW_Serialize_String(serializer, str, status)` |
| SUBROUTINE | `RW_Serialize_ArrayInt1` | 2080 | `subroutine RW_Serialize_ArrayInt1(serializer, a, status)` |
| SUBROUTINE | `RW_Serialize_ArrayInt4` | 2092 | `subroutine RW_Serialize_ArrayInt4(serializer, a, status)` |
| SUBROUTINE | `RW_Serialize_ArrayDP` | 2104 | `subroutine RW_Serialize_ArrayDP(serializer, a, status)` |
| SUBROUTINE | `RW_Deserialize_Int1` | 2116 | `subroutine RW_Deserialize_Int1(deserializer, v, status)` |
| SUBROUTINE | `RW_Deserialize_Int2` | 2124 | `subroutine RW_Deserialize_Int2(deserializer, v, status)` |
| SUBROUTINE | `RW_Deserialize_Int4` | 2132 | `subroutine RW_Deserialize_Int4(deserializer, v, status)` |
| SUBROUTINE | `RW_Deserialize_Int8` | 2140 | `subroutine RW_Deserialize_Int8(deserializer, v, status)` |
| SUBROUTINE | `RW_Deserialize_DP` | 2148 | `subroutine RW_Deserialize_DP(deserializer, v, status)` |
| SUBROUTINE | `RW_Deserialize_String` | 2156 | `subroutine RW_Deserialize_String(deserializer, str, status)` |
| SUBROUTINE | `RW_Deserialize_ArrayInt1` | 2168 | `subroutine RW_Deserialize_ArrayInt1(deserializer, a, status)` |
| SUBROUTINE | `RW_Deserialize_ArrayInt4` | 2180 | `subroutine RW_Deserialize_ArrayInt4(deserializer, a, status)` |
| SUBROUTINE | `RW_Deserialize_ArrayDP` | 2192 | `subroutine RW_Deserialize_ArrayDP(deserializer, a, status)` |
| SUBROUTINE | `RW_SymbolTable_Init` | 2204 | `subroutine RW_SymbolTable_Init(this)` |
| SUBROUTINE | `RW_SymbolTable_Destroy` | 2211 | `subroutine RW_SymbolTable_Destroy(this)` |
| SUBROUTINE | `RW_SymbolTable_Reg` | 2216 | `subroutine RW_SymbolTable_Reg(this, var_id, name, dType, rank, shape, status)` |
| FUNCTION | `RW_SymbolTable_Find` | 2271 | `function RW_SymbolTable_Find(this, name) result(idx)` |
| FUNCTION | `RW_SymbolTable_Get` | 2286 | `function RW_SymbolTable_Get(this, idx) result(entry)` |
| SUBROUTINE | `RW_SymbolTable_Set` | 2297 | `subroutine RW_SymbolTable_Set(this, idx, is_allocated)` |
| SUBROUTINE | `RW_SymbolTable_Clear` | 2306 | `subroutine RW_SymbolTable_Clear(this)` |
| FUNCTION | `RW_SymbolTable_GetTotalSize` | 2320 | `function RW_SymbolTable_GetTotalSize(this) result(total_size)` |
| FUNCTION | `RW_Get_Variable` | 2326 | `function RW_Get_Variable(table, name, entry, status) result(found)` |
| SUBROUTINE | `RW_Set_Variable` | 2347 | `subroutine RW_Set_Variable(table, name, is_allocated, status)` |
| SUBROUTINE | `RW_Clear_SymbolTable` | 2365 | `subroutine RW_Clear_SymbolTable(table)` |
| SUBROUTINE | `RW_Serializer_Init` | 2370 | `subroutine RW_Serializer_Init(this, filename, status)` |
| SUBROUTINE | `RW_Serializer_Destroy` | 2380 | `subroutine RW_Serializer_Destroy(this)` |
| SUBROUTINE | `RW_Serializer_Open` | 2387 | `subroutine RW_Serializer_Open(this, status)` |
| SUBROUTINE | `RW_Serializer_Close` | 2395 | `subroutine RW_Serializer_Close(this, status)` |
| SUBROUTINE | `RW_Serializer_Flush` | 2403 | `subroutine RW_Serializer_Flush(this, status)` |
| SUBROUTINE | `RW_Serializer_Serialize` | 2410 | `subroutine RW_Serializer_Serialize(this, data, status)` |
| SUBROUTINE | `RW_Deserializer_Init` | 2435 | `subroutine RW_Deserializer_Init(this, filename, status)` |
| SUBROUTINE | `RW_Deserializer_Destroy` | 2445 | `subroutine RW_Deserializer_Destroy(this)` |
| SUBROUTINE | `RW_Deserializer_Open` | 2452 | `subroutine RW_Deserializer_Open(this, status)` |
| SUBROUTINE | `RW_Deserializer_Close` | 2460 | `subroutine RW_Deserializer_Close(this, status)` |
| SUBROUTINE | `RW_Deserializer_Deserialize` | 2468 | `subroutine RW_Deserializer_Deserialize(this, data, status)` |
| SUBROUTINE | `RW_MemMgr_Alloc` | 2497 | `subroutine RW_MemMgr_Alloc(this, size, status)` |
| SUBROUTINE | `RW_MemMgr_Dealloc` | 2509 | `subroutine RW_MemMgr_Dealloc(this, size, status)` |
| SUBROUTINE | `RW_MemMgr_Realloc` | 2521 | `subroutine RW_MemMgr_Realloc(this, old_size, new_size, status)` |
| SUBROUTINE | `RW_MemMgr_GetStats` | 2534 | `subroutine RW_MemMgr_GetStats(this, total_allocated, total_freed, &` |
| SUBROUTINE | `RW_MemMgr_Reset` | 2548 | `subroutine RW_MemMgr_Reset(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 475–483 | `interface RW_Serialize` |
| 485–493 | `interface RW_Deserialize` |
