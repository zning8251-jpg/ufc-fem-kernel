# KeyWord Domain Design

## 概述
KeyWord域用于实现关键字驱动的输入解析能力，支持Abaqus风格的关键字语法。

## 域结构
```
KeyWord/
├── MaterialKeyword/      # 材料关键字
│   ├── MD_KeyWord_Material.f90
│   ├── MD_KeyWord_Elastic.f90
│   ├── MD_KeyWord_Hyperelastic.f90
│   ├── MD_KeyWord_Plastic.f90
│   ├── MD_KeyWord_Foam.f90
│   ├── MD_KeyWord_Composite.f90
│   └── CONTRACT.md
├── SectionKeyword/       # 截面关键字
│   ├── MD_KeyWord_Section.f90
│   ├── MD_KeyWord_SolidSection.f90
│   ├── MD_KeyWord_ShellSection.f90
│   ├── MD_KeyWord_BeamSection.f90
│   └── CONTRACT.md
├── StepKeyword/          # 分析步关键字
│   ├── MD_KeyWord_Step.f90
│   ├── MD_KeyWord_Static.f90
│   ├── MD_KeyWord_Dynamic.f90
│   ├── MD_KeyWord_Frequency.f90
│   └── CONTRACT.md
├── OutputKeyword/        # 输出关键字
│   ├── MD_KeyWord_Output.f90
│   ├── MD_KeyWord_FieldOutput.f90
│   ├── MD_KeyWord_HistoryOutput.f90
│   └── CONTRACT.md
├── ElementKeyword/       # 单元关键字
│   ├── MD_KeyWord_Element.f90
│   ├── MD_KeyWord_SolidElement.f90
│   ├── MD_KeyWord_ShellElement.f90
│   ├── MD_KeyWord_BeamElement.f90
│   └── CONTRACT.md
├── ContactKeyword/       # 接触关键字
│   ├── MD_KeyWord_Contact.f90
│   ├── MD_KeyWord_SurfaceContact.f90
│   ├── MD_KeyWord_NodeContact.f90
│   └── CONTRACT.md
├── LoadKeyword/          # 载荷关键字
│   ├── MD_KeyWord_Load.f90
│   ├── MD_KeyWord_ConcentratedLoad.f90
│   ├── MD_KeyWord_PressureLoad.f90
│   └── CONTRACT.md
├── BoundaryKeyword/      # 边界条件关键字
│   ├── MD_KeyWord_Boundary.f90
│   ├── MD_KeyWord_DisplacementBC.f90
│   ├── MD_KeyWord_VelocityBC.f90
│   └── CONTRACT.md
└── Parser/               # 解析器
    ├── MD_KeyWord_Lexer.f90
    ├── MD_KeyWord_Parser.f90
    ├── MD_KeyWord_SyntaxValidator.f90
    ├── MD_KeyWord_ParameterParser.f90
    └── CONTRACT.md
```

## 关键字类型

### 1. MaterialKeyword (材料关键字)
- **功能**：定义材料属性
- **参考**：Abaqus *Material
- **语法**：
  ```
  *Material, name=Steel
  *Elastic
  200000., 0.3
  *Hyperelastic, model=NeoHookean
  10.0, 0.45
  ```
- **子关键字**：
  - *Elastic - 弹性材料
  - *Hyperelastic - 超弹性材料
  - *Plastic - 塑性材料
  - *Foam - 泡沫材料
  - *Composite - 复合材料

### 2. SectionKeyword (截面关键字)
- **功能**：定义截面属性
- **参考**：Abaqus *Solid Section, *Shell Section
- **语法**：
  ```
  *Solid Section, elset=E1, material=Steel
  1.0,
  *Shell Section, elset=S1, material=Steel
  0.01
  ```
- **子关键字**：
  - *Solid Section - 实体截面
  - *Shell Section - 壳截面
  - *Beam Section - 梁截面

### 3. StepKeyword (分析步关键字)
- **功能**：定义分析步
- **参考**：Abaqus *Step
- **语法**：
  ```
  *Step, name=Step-1
  *Static
  1., 1., 1e-05, 1.
  *End Step
  ```
- **子关键字**：
  - *Static - 静态分析
  - *Dynamic, Implicit - 隐式动力分析
  - *Dynamic, Explicit - 显式动力分析
  - *Frequency - 频率分析

### 4. OutputKeyword (输出关键字)
- **功能**：定义输出请求
- **参考**：Abaqus *Output, *Field Output, *History Output
- **语法**：
  ```
  *Output, field
  *Node Output
  U, RF
  *Element Output
  S, E
  ```
- **子关键字**：
  - *Output - 输出控制
  - *Field Output - 场输出
  - *History Output - 历史输出

### 5. ElementKeyword (单元关键字)
- **功能**：定义单元类型
- **参考**：Abaqus *Element
- **语法**：
  ```
  *Element, type=C3D8, elset=E1
  1, 2, 3, 4, 5, 6, 7, 8
  ```
- **子关键字**：
  - *Element - 单元定义
  - *Element Type - 单元类型

### 6. ContactKeyword (接触关键字)
- **功能**：定义接触
- **参考**：Abaqus *Contact Pair, *Contact
- **语法**：
  ```
  *Contact Pair, interaction=Int-1
  Surf1, Surf2
  *Surface Interaction, name=Int-1
  *Friction
  0.3
  ```
- **子关键字**：
  - *Contact Pair - 接触对
  - *Contact - 接触定义
  - *Surface Interaction - 表面相互作用

### 7. LoadKeyword (载荷关键字)
- **功能**：定义载荷
- **参考**：Abaqus *Cload, *Dload, *Dsload
- **语法**：
  ```
  *Cload
  1, 1, 1000.
  *Dsload
  Surf1, P, 1000.
  ```
- **子关键字**：
  - *Cload - 集中载荷
  - *Dload - 分布载荷
  - *Dsload - 压力载荷

### 8. BoundaryKeyword (边界条件关键字)
- **功能**：定义边界条件
- **参考**：Abaqus *Boundary
- **语法**：
  ```
  *Boundary
  1, 1, 1, 0.
  1, 2, 2, 0.
  ```
- **子关键字**：
  - *Boundary - 边界条件
  - *Boundary, Type=Velocity - 速度边界条件
  - *Boundary, Type=Acceleration - 加速度边界条件

## 解析器组件

### 1. Lexer (词法分析器)
- **功能**：将输入文本转换为标记流
- **实现**：MD_KeyWord_Lexer.f90
- **功能**：
  - 识别关键字（*开头）
  - 识别参数（name=value）
  - 识别数据行
  - 识别注释（**开头）

### 2. Parser (语法分析器)
- **功能**：根据语法规则解析标记流
- **实现**：MD_KeyWord_Parser.f90
- **功能**：
  - 语法树构建
  - 关键字匹配
  - 参数解析
  - 数据解析

### 3. SyntaxValidator (语法验证器)
- **功能**：验证语法正确性
- **实现**：MD_KeyWord_SyntaxValidator.f90
- **功能**：
  - 关键字顺序验证
  - 参数类型验证
  - 数据数量验证
  - 范围验证

### 4. ParameterParser (参数解析器)
- **功能**：解析关键字参数
- **实现**：MD_KeyWord_ParameterParser.f90
- **功能**：
  - 参数名解析
  - 参数值解析
  - 参数类型转换
  - 默认值处理

## 命名规范
- 域名：KeyWord
- 子域名：MaterialKeyword, SectionKeyword, StepKeyword等
- 算法文件：MD_KeyWord_[Type].f90（三段式命名）
- 参数命名：materialName, elasticModulus, poissonRatio, stepName, timeIncrement

## 接口规范
```fortran
subroutine MD_KeyWord_Material(keywordData, materialData)
  type(KeywordData), intent(in) :: keywordData
  type(MaterialData), intent(out) :: materialData
end subroutine

subroutine MD_KeyWord_Lexer(inputText, tokenStream)
  character(len=*), intent(in) :: inputText
  type(TokenStream), intent(out) :: tokenStream
end subroutine

subroutine MD_KeyWord_Parser(tokenStream, syntaxTree)
  type(TokenStream), intent(in) :: tokenStream
  type(SyntaxTree), intent(out) :: syntaxTree
end subroutine
```

## 关键字语法规则
- 关键字以*开头
- 参数用逗号分隔：name=value
- 数据行按行提供
- 注释以**开头
- 关键字块以*End结束
- 参数值可以是数字、字符串、逻辑值

## 数据结构
```fortran
type :: Keyword
  character(len=50) :: name
  type(Param), allocatable :: params(:)
  real(8), allocatable :: data(:)
end type Keyword

type :: Param
  character(len=50) :: name
  character(len=100) :: value
  integer :: type  ! 1=integer, 2=real, 3=string, 4=logical
end type Param
```

## 测试计划
- 词法分析测试
- 语法分析测试
- 参数解析测试
- 材料关键字测试
- 截面关键字测试
- 分析步关键字测试
- 输出关键字测试
- 错误处理测试

## 参考文献
- Abaqus Analysis User's Manual - Input Syntax
- Abaqus Keywords Reference Manual
- Aho, A.V., et al. - Compilers: Principles, Techniques, and Tools
