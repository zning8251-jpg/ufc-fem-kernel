# UFC 部署指南

> **版本**: v1.0
> **创建日期**: 2026-03-06
> **最后更新**: 2026-03-06
> **适用范围**: UFC 项目部署与安装
> **上级参考**: UFC_架构设计总纲_六层四类四链三步三级两图一体.md（v2.0）

---

## 📋 文档说明

本文档提供 UFC 项目的完整部署指南，包括：

- 系统要求
- 依赖库安装
- 编译配置
- 安装步骤
- 多平台支持（Linux/Windows）
- 环境变量配置
- 配置文件说明
- 验证安装

---

## 目录

1. [系统要求](#1-系统要求)
2. [依赖库安装](#2-依赖库安装)
3. [编译配置](#3-编译配置)
4. [安装步骤](#4-安装步骤)
5. [多平台支持](#5-多平台支持)
6. [环境变量配置](#6-环境变量配置)
7. [配置文件说明](#7-配置文件说明)
8. [验证安装](#8-验证安装)
9. [常见问题](#9-常见问题)

---

## 1. 系统要求

### 1.1 硬件要求

**最低配置**:

- CPU: 2 核心
- 内存: 4 GB RAM
- 磁盘: 10 GB 可用空间

**推荐配置**:

- CPU: 8+ 核心（支持并行计算）
- 内存: 16+ GB RAM
- 磁盘: 50+ GB 可用空间（SSD 推荐）

### 1.2 软件要求

**操作系统**:

- Linux: Ubuntu 20.04+, CentOS 7+, RHEL 8+
- Windows: Windows 10+, Windows Server 2016+

**编译器**:

- **gfortran**: 9.0+（推荐 11.0+）
- **ifort**: 19.0+（Intel 编译器，可选）
- **flang**: 12.0+（LLVM Fortran，可选）

**构建工具**:

- **CMake**: 3.15+
- **Make**: 4.0+（Linux）
- **Ninja**: 1.10+（可选，更快构建）

**其他工具**:

- **Git**: 2.20+
- **pkg-config**: 0.29+（Linux）

---

## 2. 依赖库安装

### 2.1 基础依赖（必需）

#### Linux (Ubuntu/Debian)

```bash
sudo apt-get update
sudo apt-get install -y \
  build-essential \
  gfortran \
  cmake \
  git \
  pkg-config \
  libblas-dev \
  liblapack-dev \
  libopenmpi-dev \
  libnuma-dev
```

#### Linux (CentOS/RHEL)

```bash
sudo yum install -y \
  gcc-gfortran \
  cmake \
  git \
  pkgconfig \
  blas-devel \
  lapack-devel \
  openmpi-devel \
  numactl-devel
```

#### Windows

**使用 vcpkg**:

```powershell
vcpkg install blas lapack openmpi
```

**或使用 MSYS2**:

```bash
pacman -S mingw-w64-x86_64-gcc-fortran \
          mingw-w64-x86_64-cmake \
          mingw-w64-x86_64-openblas \
          mingw-w64-x86_64-lapack \
          mingw-w64-x86_64-openmpi
```

### 2.2 可选依赖

#### MUMPS（稀疏矩阵求解器）

**Linux**:

```bash
# 下载 MUMPS
wget http://mumps.enseeiht.fr/MUMPS_5.5.1.tar.gz
tar -xzf MUMPS_5.5.1.tar.gz
cd MUMPS_5.5.1

# 编译
make -j4

# 设置环境变量
export MUMPS_ROOT=/path/to/MUMPS_5.5.1
```

#### METIS（图划分）

**Linux**:

```bash
sudo apt-get install -y libmetis-dev
```

#### HDF5（数据存储）

**Linux**:

```bash
sudo apt-get install -y libhdf5-dev
```

---

## 3. 编译配置

### 3.1 CMake 配置选项

**基本配置**:

```bash
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/opt/ufc \
      -DBUILD_SHARED_LIBS=ON \
      ..
```

**完整配置**:

```bash
cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/opt/ufc \
  -DCMAKE_Fortran_COMPILER=gfortran \
  -DBUILD_SHARED_LIBS=ON \
  -DENABLE_OPENMP=ON \
  -DENABLE_MPI=ON \
  -DENABLE_MUMPS=ON \
  -DENABLE_METIS=ON \
  -DENABLE_HDF5=ON \
  -DENABLE_CUDA=OFF \
  -DCMAKE_Fortran_FLAGS="-O3 -march=native" \
  ..
```

### 3.2 配置选项说明

| 选项                       | 默认值         | 说明                         |
| -------------------------- | -------------- | ---------------------------- |
| `CMAKE_BUILD_TYPE`       | `Release`    | Debug/Release/RelWithDebInfo |
| `CMAKE_INSTALL_PREFIX`   | `/usr/local` | 安装路径                     |
| `CMAKE_Fortran_COMPILER` | `gfortran`   | Fortran 编译器               |
| `BUILD_SHARED_LIBS`      | `ON`         | 构建共享库                   |
| `ENABLE_OPENMP`          | `ON`         | 启用 OpenMP 并行             |
| `ENABLE_MPI`             | `OFF`        | 启用 MPI 并行                |
| `ENABLE_MUMPS`           | `OFF`        | 启用 MUMPS 求解器            |
| `ENABLE_METIS`           | `OFF`        | 启用 METIS 图划分            |
| `ENABLE_HDF5`            | `OFF`        | 启用 HDF5 数据存储           |
| `ENABLE_CUDA`            | `OFF`        | 启用 CUDA GPU 加速           |

### 3.3 编译器特定选项

**gfortran**:

```bash
cmake -DCMAKE_Fortran_FLAGS="-O3 -march=native -fopenmp" ..
```

**ifort**:

```bash
cmake -DCMAKE_Fortran_COMPILER=ifort \
      -DCMAKE_Fortran_FLAGS="-O3 -xHost -qopenmp" ..
```

---

## 4. 安装步骤

### 4.1 从源码安装

**步骤 1: 获取源码**

```bash
git clone https://github.com/your-org/ufc.git
cd ufc
```

**步骤 2: 创建构建目录**

```bash
mkdir build && cd build
```

**步骤 3: 配置 CMake**

```bash
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/opt/ufc \
      ..
```

**步骤 4: 编译**

```bash
make -j$(nproc)
```

**步骤 5: 运行测试（可选）**

```bash
ctest --output-on-failure
```

**步骤 6: 安装**

```bash
sudo make install
```

### 4.2 从预编译包安装

#### Linux (Debian/Ubuntu)

```bash
# 下载 .deb 包
wget https://github.com/your-org/ufc/releases/download/v1.0.0/ufc_1.0.0_amd64.deb

# 安装
sudo dpkg -i ufc_1.0.0_amd64.deb
sudo apt-get install -f  # 解决依赖
```

#### Linux (RPM)

```bash
# 下载 .rpm 包
wget https://github.com/your-org/ufc/releases/download/v1.0.0/ufc-1.0.0-1.x86_64.rpm

# 安装
sudo rpm -ivh ufc-1.0.0-1.x86_64.rpm
```

#### Windows

```powershell
# 下载安装包
Invoke-WebRequest -Uri "https://github.com/your-org/ufc/releases/download/v1.0.0/ufc-1.0.0-windows-x64.msi" -OutFile "ufc.msi"

# 安装
msiexec /i ufc.msi /quiet
```

---

## 5. 多平台支持

### 5.1 Linux

**推荐发行版**:

- Ubuntu 20.04 LTS / 22.04 LTS
- CentOS 7 / 8
- RHEL 8 / 9

**安装验证**:

```bash
ufc_solver --version
```

### 5.2 Windows

**支持版本**:

- Windows 10 (64-bit)
- Windows 11 (64-bit)
- Windows Server 2016+ (64-bit)

**安装路径**:

- 默认: `C:\Program Files\UFC\`
- 用户: `%LOCALAPPDATA%\UFC\`

**PATH 配置**:
安装程序会自动添加 `C:\Program Files\UFC\bin` 到 PATH。

### 5.3 macOS

**支持版本**:

- macOS 11.0+ (Big Sur)
- macOS 12.0+ (Monterey)
- macOS 13.0+ (Ventura)

**使用 Homebrew**:

```bash
brew install ufc
```

---

## 6. 环境变量配置

### 6.1 Linux/macOS

**添加到 `~/.bashrc` 或 `~/.zshrc`**:

```bash
# UFC 安装路径
export UFC_ROOT=/opt/ufc

# 添加到 PATH
export PATH=$UFC_ROOT/bin:$PATH

# 添加到 LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$UFC_ROOT/lib:$LD_LIBRARY_PATH

# 添加到 PKG_CONFIG_PATH
export PKG_CONFIG_PATH=$UFC_ROOT/lib/pkgconfig:$PKG_CONFIG_PATH
```

**应用配置**:

```bash
source ~/.bashrc
```

### 6.2 Windows

**PowerShell**:

```powershell
# 设置环境变量（当前会话）
$env:UFC_ROOT = "C:\Program Files\UFC"
$env:PATH += ";$env:UFC_ROOT\bin"

# 永久设置（需要管理员权限）
[System.Environment]::SetEnvironmentVariable("UFC_ROOT", "C:\Program Files\UFC", "Machine")
```

**CMD**:

```cmd
setx UFC_ROOT "C:\Program Files\UFC" /M
setx PATH "%PATH%;C:\Program Files\UFC\bin" /M
```

### 6.3 环境变量列表

| 变量名              | 说明           | 默认值                                                    |
| ------------------- | -------------- | --------------------------------------------------------- |
| `UFC_ROOT`        | UFC 安装根目录 | `/opt/ufc` (Linux) / `C:\Program Files\UFC` (Windows) |
| `UFC_DATA_DIR`    | 数据目录       | `$UFC_ROOT/data`                                        |
| `UFC_CONFIG_FILE` | 配置文件路径   | `$UFC_ROOT/etc/ufc.conf`                                |
| `UFC_LOG_LEVEL`   | 日志级别       | `INFO`                                                  |
| `OMP_NUM_THREADS` | OpenMP 线程数  | `1`                                                     |

---

## 7. 配置文件说明

### 7.1 配置文件位置

**Linux/macOS**: `/opt/ufc/etc/ufc.conf`
**Windows**: `C:\Program Files\UFC\etc\ufc.conf`

### 7.2 配置文件格式

**示例配置** (`ufc.conf`):

```ini
[General]
# 日志级别: DEBUG, INFO, WARNING, ERROR
log_level = INFO

# 日志文件路径
log_file = /var/log/ufc/ufc.log

# 数据目录
data_dir = /opt/ufc/data

[Memory]
# 内存池大小 (GB)
pool_size = 16

# NUMA 感知
numa_aware = true

[Solver]
# 默认求解器类型
default_solver = LU

# 最大迭代次数
max_iterations = 1000

# 收敛容差
tolerance = 1.0e-6

[Parallel]
# OpenMP 线程数 (0 = 自动)
omp_threads = 0

# MPI 进程数
mpi_procs = 1
```

### 7.3 配置文件验证

```bash
ufc_config --validate
```

---

## 8. 验证安装

### 8.1 基本验证

**检查版本**:

```bash
ufc_solver --version
```

**预期输出**:

```
UFC Solver v1.0.0
Built with: gfortran 11.2.0
OpenMP: enabled
MPI: disabled
```

### 8.2 功能验证

**运行测试示例**:

```bash
cd $UFC_ROOT/examples
ufc_solver cantilever_beam.inp
```

**检查输出**:

- 应生成 `cantilever_beam.odb` 文件
- 无错误信息

### 8.3 性能验证

**运行基准测试**:

```bash
ufc_benchmark --test=all
```

**预期结果**:

- 所有测试通过
- 性能指标在预期范围内

---

## 9. 常见问题

### Q1: 编译失败，提示找不到 BLAS/LAPACK

**解决方案**:

```bash
# Ubuntu/Debian
sudo apt-get install libblas-dev liblapack-dev

# CentOS/RHEL
sudo yum install blas-devel lapack-devel

# 指定 BLAS/LAPACK 路径
cmake -DBLAS_LIBRARIES=/usr/lib/libblas.so \
      -DLAPACK_LIBRARIES=/usr/lib/liblapack.so \
      ..
```

### Q2: 运行时提示找不到共享库

**解决方案**:

```bash
# Linux
export LD_LIBRARY_PATH=$UFC_ROOT/lib:$LD_LIBRARY_PATH

# 或添加到 /etc/ld.so.conf.d/ufc.conf
echo "/opt/ufc/lib" | sudo tee /etc/ld.so.conf.d/ufc.conf
sudo ldconfig
```

### Q3: OpenMP 并行不工作

**解决方案**:

```bash
# 检查 OpenMP 支持
gfortran -fopenmp --version

# 设置线程数
export OMP_NUM_THREADS=4

# 验证
ufc_solver --test-parallel
```

### Q4: Windows 上找不到 gfortran

**解决方案**:

```powershell
# 使用 MSYS2
pacman -S mingw-w64-x86_64-gcc-fortran

# 或使用 MinGW-w64
# 下载并安装 MinGW-w64，添加到 PATH
```

### Q5: 安装后无法找到 ufc_solver 命令

**解决方案**:

```bash
# 检查安装路径
ls -la $UFC_ROOT/bin

# 添加到 PATH
export PATH=$UFC_ROOT/bin:$PATH

# 验证
which ufc_solver
```

---

## 附录

### A.1 安装检查清单

- [ ] 系统要求满足（CPU、内存、磁盘）
- [ ] 编译器已安装（gfortran/ifort）
- [ ] CMake 已安装（3.15+）
- [ ] 依赖库已安装（BLAS、LAPACK、OpenMPI）
- [ ] 源码已获取（Git clone）
- [ ] CMake 配置成功
- [ ] 编译成功（无错误）
- [ ] 测试通过（ctest）
- [ ] 安装成功（make install）
- [ ] 环境变量已配置
- [ ] 配置文件已设置
- [ ] 验证安装成功

### A.2 相关文档

- `UFC_OPERATIONS_MANUAL.md` - 运维手册
- `UFC_PERFORMANCE_GUIDE.md` - 性能优化指南
- `UFC_DEVELOPER_GUIDE.md` - 开发者指南

---

**文档状态**: Draft v1.0
**最后更新**: 2026-03-06
**维护者**: UFC 开发团队
