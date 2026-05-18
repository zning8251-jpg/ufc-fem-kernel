# UFC CI/CD 流程文档

> **版本**: v1.0  
> **创建日期**: 2026-03-06  
> **最后更新**: 2026-03-06  
> **适用范围**: UFC 项目持续集成与持续部署  
> **上级参考**: UFC_架构设计总纲_六层四类四链三步三级两图一体.md（v2.0）

---

## 📋 文档说明

本文档定义 UFC 项目的 CI/CD 流程，包括：

- CI/CD 流程设计
- 自动化测试流程
- 代码质量检查流程
- 自动化部署流程
- 版本发布流程
- 回滚策略

---

## 目录

1. [CI/CD 流程概述](#1-cicd-流程概述)
2. [持续集成（CI）流程](#2-持续集成ci流程)
3. [持续部署（CD）流程](#3-持续部署cd流程)
4. [代码质量门禁](#4-代码质量门禁)
5. [GitHub Actions 配置](#5-github-actions-配置)
6. [版本发布流程](#6-版本发布流程)
7. [回滚策略](#7-回滚策略)

---

## 1. CI/CD 流程概述

### 1.1 流程总览

```
代码提交 → 自动编译 → 单元测试 → 集成测试 → 代码质量检查
   ↓
性能测试 → 文档生成 → 构建产物 → 部署 → 生产环境
```

### 1.2 触发条件

**CI 触发**:

- Push 到主分支
- Pull Request 创建/更新
- 手动触发（workflow_dispatch）

**CD 触发**:

- 主分支合并（通过所有检查）
- 标签推送（v*.*.*）
- 手动触发（生产部署）

---

## 2. 持续集成（CI）流程

### 2.1 阶段 1: 代码检出与环境准备

**步骤**:

1. 检出代码
2. 设置编译环境（编译器、依赖库）
3. 缓存依赖（加速后续构建）

**GitHub Actions 配置**:

```yaml
- name: Checkout code
  uses: actions/checkout@v3

- name: Set up Fortran environment
  uses: fortran-lang/setup-fortran@v2
  with:
    compiler: gfortran
    version: '11'

- name: Install dependencies
  run: |
    sudo apt-get update
    sudo apt-get install -y libblas-dev liblapack-dev libopenmpi-dev
```

### 2.2 阶段 2: 编译

**步骤**:

1. Debug 模式编译
2. Release 模式编译
3. 检查编译警告（< 50 个）

**配置**:

```yaml
- name: Build Debug
  run: |
    mkdir build_debug && cd build_debug
    cmake -DCMAKE_BUILD_TYPE=Debug ..
    make -j4

- name: Build Release
  run: |
    mkdir build_release && cd build_release
    cmake -DCMAKE_BUILD_TYPE=Release ..
    make -j4

- name: Check warnings
  run: |
    # 统计编译警告数量
    warnings=$(grep -c "warning:" build_debug/compile.log || true)
    if [ $warnings -gt 50 ]; then
      echo "Too many warnings: $warnings"
      exit 1
    fi
```

### 2.3 阶段 3: 单元测试

**步骤**:

1. 运行单元测试套件
2. 生成覆盖率报告
3. 检查覆盖率（> 80%）

**配置**:

```yaml
- name: Run unit tests
  run: |
    cd build_debug
    ctest --output-on-failure

- name: Generate coverage report
  run: |
    cd build_debug
    lcov --capture --directory . --output-file coverage.info
    lcov --remove coverage.info '/usr/*' --output-file coverage.info
    genhtml coverage.info --output-directory coverage_html

- name: Upload coverage
  uses: codecov/codecov@v3
  with:
    file: build_debug/coverage.info
```

### 2.4 阶段 4: 集成测试

**步骤**:

1. 运行集成测试
2. 运行端到端测试
3. 验证测试结果

**配置**:

```yaml
- name: Run integration tests
  run: |
    cd build_release
    ./bin/ufc_solver tests/data/input/cantilever_beam.inp
    ./bin/ufc_solver tests/data/input/cooks_membrane.inp
```

### 2.5 阶段 5: 代码质量检查

**步骤**:

1. 命名规范检查
2. 层级依赖检查
3. TYPE 分类检查
4. 注释质量检查

**配置**:

```yaml
- name: Code quality checks
  run: |
    python tools/check_naming_standard.py
    python tools/verify_layer_dependency.py
    python tools/verify_type_categories.py
    python tools/check_comments.py
```

### 2.6 阶段 6: 性能测试

**步骤**:

1. 运行性能基准测试
2. 对比历史性能数据
3. 检查性能退化（< 5%）

**配置**:

```yaml
- name: Performance tests
  run: |
    cd build_release
    python tools/benchmark_performance.py --compare-baseline
```

---

## 3. 持续部署（CD）流程

### 3.1 阶段 1: 构建发布版本

**步骤**:

1. 构建 Release 版本
2. 生成发布包（tar.gz, zip）
3. 生成文档（API 文档、用户手册）

**配置**:

```yaml
- name: Build release package
  run: |
    mkdir -p dist
    tar -czf dist/ufc-${VERSION}.tar.gz bin/ lib/ include/
    zip -r dist/ufc-${VERSION}.zip bin/ lib/ include/

- name: Generate documentation
  run: |
    python tools/generate_api_docs.py
    python tools/generate_user_manual.py
```

### 3.2 阶段 2: 部署到测试环境

**步骤**:

1. 部署到测试服务器
2. 运行冒烟测试
3. 验证功能正常

**配置**:

```yaml
- name: Deploy to test environment
  run: |
    scp dist/ufc-${VERSION}.tar.gz test-server:/opt/ufc/
    ssh test-server "cd /opt/ufc && tar -xzf ufc-${VERSION}.tar.gz"
    ssh test-server "/opt/ufc/bin/ufc_solver --version"
```

### 3.3 阶段 3: 部署到生产环境

**步骤**:

1. 人工审批（可选）
2. 部署到生产服务器
3. 验证部署成功

**配置**:

```yaml
- name: Deploy to production
  if: github.ref == 'refs/heads/main'
  run: |
    # 需要人工审批
    echo "Deploying to production..."
    # 部署脚本
```

---

## 4. 代码质量门禁

### 4.1 必须通过的检查

**P0 级（阻塞）**:

- 编译零错误
- 所有单元测试通过（100%）
- 所有集成测试通过（100%）
- 代码覆盖率 > 80%
- 命名规范检查通过
- 层级依赖检查通过

**P1 级（警告）**:

- 编译警告 < 50
- 性能无退化（< 5%）
- 内存泄漏检查通过（Valgrind）

**P2 级（可选）**:

- 文档完整性检查
- 代码审查通过

### 4.2 质量门禁配置

**GitHub Actions**:

```yaml
- name: Quality gates
  run: |
    # P0 checks
    if [ $test_failures -gt 0 ]; then
      echo "P0 FAIL: Unit tests failed"
      exit 1
    fi
    
    if [ $coverage -lt 80 ]; then
      echo "P0 FAIL: Coverage < 80%"
      exit 1
    fi
    
    # P1 checks
    if [ $warnings -gt 50 ]; then
      echo "P1 WARNING: Too many warnings"
    fi
```

---

## 5. GitHub Actions 配置

### 5.1 完整 workflow 文件

**文件**: `.github/workflows/ci.yml`

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Set up Fortran
        uses: fortran-lang/setup-fortran@v2
        with:
          compiler: gfortran
          version: '11'
      
      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y libblas-dev liblapack-dev libopenmpi-dev
      
      - name: Build
        run: |
          mkdir build && cd build
          cmake ..
          make -j4
      
      - name: Run tests
        run: |
          cd build
          ctest --output-on-failure
      
      - name: Code quality checks
        run: |
          python tools/check_naming_standard.py
          python tools/verify_layer_dependency.py
      
      - name: Generate coverage
        run: |
          cd build
          lcov --capture --directory . --output-file coverage.info
          genhtml coverage.info --output-directory coverage_html
      
      - name: Upload coverage
        uses: codecov/codecov@v3
        with:
          file: build/coverage.info
```

### 5.2 多平台测试

**配置**: `.github/workflows/multi-platform.yml`

```yaml
strategy:
  matrix:
    os: [ubuntu-latest, windows-latest, macos-latest]
    compiler: [gfortran, ifort]
    
jobs:
  test:
    runs-on: ${{ matrix.os }}
    steps:
      - name: Build with ${{ matrix.compiler }}
        run: |
          # 编译命令
```

---

## 6. 版本发布流程

### 6.1 版本号规则

**语义化版本**: `主版本号.次版本号.修订号`

- **主版本号**: 不兼容的 API 变更
- **次版本号**: 向后兼容的功能新增
- **修订号**: 向后兼容的问题修复

**示例**:

- `v1.0.0` - 初始发布
- `v1.1.0` - 新增功能（向后兼容）
- `v1.1.1` - 问题修复
- `v2.0.0` - 重大变更（不兼容）

### 6.2 发布步骤

**步骤**:

1. 更新版本号（`VERSION` 文件）
2. 更新 CHANGELOG.md
3. 创建 Git 标签: `git tag v1.0.0`
4. 推送标签: `git push origin v1.0.0`
5. GitHub Actions 自动构建发布包
6. 创建 GitHub Release
7. 发布公告

### 6.3 发布检查清单

**发布前检查**:

- 所有测试通过
- 文档更新完成
- CHANGELOG 更新
- 版本号更新
- 向后兼容性验证

---

## 7. 回滚策略

### 7.1 自动回滚条件

**触发条件**:

- 部署后测试失败
- 生产环境错误率 > 5%
- 性能退化 > 10%

### 7.2 回滚步骤

**步骤**:

1. 停止当前版本服务
2. 恢复上一版本
3. 验证回滚成功
4. 通知团队

**配置**:

```yaml
- name: Rollback on failure
  if: failure()
  run: |
    echo "Deployment failed, rolling back..."
    ssh production-server "/opt/ufc/rollback.sh"
```

---

## 附录

### A.1 CI/CD 工具链


| 工具                 | 用途       | 状态    |
| ------------------ | -------- | ----- |
| **GitHub Actions** | CI/CD 平台 | ✅ 推荐  |
| **Jenkins**        | CI/CD 平台 | ⚠️ 备选 |
| **GitLab CI**      | CI/CD 平台 | ⚠️ 备选 |
| **Codecov**        | 覆盖率报告    | ✅ 已集成 |
| **Valgrind**       | 内存检查     | ✅ 已集成 |


### A.2 相关文档

- `UFC_TEST_STRATEGY.md` - 测试策略
- `UFC_TOOLCHAIN_MANUAL.md` - 工具链使用手册
- `UFC_DEVELOPER_GUIDE.md` - 开发者指南

---

**文档状态**: Draft v1.0  
**最后更新**: 2026-03-06  
**维护者**: UFC 开发团队