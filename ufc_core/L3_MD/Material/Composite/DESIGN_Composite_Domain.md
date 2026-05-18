# Composite Domain Design

## 概述

Composite域用于实现复合材料模型，包括层合板、编织复合材料和短纤维复合材料。

## 域结构

```
Composite/
├── Laminate/           # 层合板
│   ├── MD_Comp_Laminate.f90
│   └── CONTRACT.md
├── Woven/              # 编织复合材料
│   ├── MD_Comp_Woven.f90
│   └── CONTRACT.md
└── ShortFiber/         # 短纤维复合材料
    ├── MD_Comp_ShortFiber.f90
    └── CONTRACT.md
```

## 材料模型

### 1. Laminate (层合板)

- **功能**：模拟层合板复合材料，考虑层间应力和失效
- **参考**：Abaqus *Laminate
- **参数**：
  - 单层材料属性（E1, E2, ν12, G12, G23, G13）
  - 层厚度
  - 层方向角
  - 层间强度
  - 失效准则（Hashin, Tsai-Wu, Puck）
- **接口**：
  ```fortran
  subroutine MD_Comp_Laminate(state, params, dt)
    type(MaterialState), intent(inout) :: state
    real(8), intent(in) :: params(:)
    real(8), intent(in) :: dt
  end subroutine
  ```

### 2. Woven (编织复合材料)

- **功能**：模拟编织复合材料的各向异性行为
- **参考**：Abaqus *Woven Composite
- **参数**：
  - 经向弹性模量 E1
  - 纬向弹性模量 E2
  - 泊松比 ν12
  - 剪切模量 G12, G23, G13
  - 编织角度
  - 失效参数
- **接口**：
  ```fortran
  subroutine MD_Comp_Woven(state, params, dt)
    type(MaterialState), intent(inout) :: state
    real(8), intent(in) :: params(:)
    real(8), intent(in) :: dt
  end subroutine
  ```

### 3. ShortFiber (短纤维复合材料)

- **功能**：模拟短纤维增强复合材料的非均匀性
- **参考**：Abaqus *Short Fiber
- **参数**：
  - 基体材料属性
  - 纤维材料属性
  - 纤维体积分数
  - 纤维取向分布
  - 界面强度
- **接口**：
  ```fortran
  subroutine MD_Comp_ShortFiber(state, params, dt)
    type(MaterialState), intent(inout) :: state
    real(8), intent(in) :: params(:)
    real(8), intent(in) :: dt
  end subroutine
  ```

## 命名规范

- 域名：Composite
- 子域名：Laminate, Woven, ShortFiber
- 算法文件：MD_Comp_[Type].f90（三段式命名）
- 参数命名：compModulus1, compModulus2, compPoisson, fiberVolume, layerAngle

## 状态变量

- 层应力
- 层应变
- 失效指标
- 纤维取向
- 损伤变量

## 接口规范

- 输入：MaterialState, params, dt
- 输出：更新的应力、切线模量、状态变量
- 遵循L3_MD Material域通用接口
- 支持多层数据结构

## 失效准则

- Hashin失效准则
- Tsai-Wu失效准则
- Puck失效准则
- 最大应力准则
- 最大应变准则

## 测试计划

- 单轴拉伸/压缩测试
- 剪切测试
- 层间剪切测试
- 失效分析测试
- 纤维取向测试（ShortFiber）

## 参考文献

- Abaqus Analysis User's Manual - Composite Materials
- Hashin, Z. (1980). "Failure criteria for unidirectional fiber composites"
- Puck, A., and Schürmann, H. (1998). "Failure analysis of FRP laminates by means of physically based phenomenological models"
