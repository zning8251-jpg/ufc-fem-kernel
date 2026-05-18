# L3_MD 材料域详细设计说明

## 概述
L3_MD Material Domain是UFC的材料计算核心，负责材料模型实现、材料状态管理、材料参数处理等。

---

## Analysis/ - 分析模块域

### 功能描述
分析模块域提供材料分析接口和状态初始化。

### 参考文档
- Abaqus Analysis User's Manual - Material Models
- Simo, J.C., Hughes, T.J.R. - Computational Inelasticity
- Holzapfel, G.A. - Nonlinear Solid Mechanics

### 材料状态初始化
```fortran
module MD_Analysis_StateInit
    type :: MaterialState
        real(wp), allocatable :: stress(:)         ! 应力（6分量）
        real(wp), allocatable :: strain(:)         ! 应变（6分量）
        real(wp), allocatable :: plasticStrain(:)  ! 塑性应变
        real(wp), allocatable :: historyVars(:)    ! 历史变量
        real(wp), allocatable :: stateVars(:)      ! 状态变量
        real(wp) :: equivalentStrain               ! 等效应变
        real(wp) :: equivalentStress               ! 等效应力
        integer :: nHistoryVars
        integer :: nStateVars
        logical :: converged
    end type MaterialState
    
    subroutine initializeMaterialState(state, nHistoryVars, nStateVars)
        type(MaterialState), intent(out) :: state
        integer, intent(in) :: nHistoryVars, nStateVars
        
        allocate(state%stress(6))
        allocate(state%strain(6))
        allocate(state%plasticStrain(6))
        allocate(state%historyVars(nHistoryVars))
        allocate(state%stateVars(nStateVars))
        
        state%stress = 0.0_wp
        state%strain = 0.0_wp
        state%plasticStrain = 0.0_wp
        state%historyVars = 0.0_wp
        state%stateVars = 0.0_wp
        state%equivalentStrain = 0.0_wp
        state%equivalentStress = 0.0_wp
        state%nHistoryVars = nHistoryVars
        state%nStateVars = nStateVars
        state%converged = .false.
    end subroutine
end module
```

### 应力计算接口
```fortran
module MD_Analysis_Stress
    subroutine computeStress(state, params, dt)
        type(MaterialState), intent(inout) :: state
        real(wp), intent(in) :: params(:)
        real(wp), intent(in) :: dt
        
        ! 根据材料类型调用相应的应力计算
        integer :: materialType
        
        materialType = int(params(1))
        
        select case (materialType)
            case (1)  ! 线性弹性
                call linearElasticStress(state, params)
            case (2)  ! 超弹性
                call hyperelasticStress(state, params)
            case (3)  ! 塑性
                call plasticStress(state, params, dt)
        end select
    end subroutine
end module
```

### 切线模量计算
```fortran
module MD_Analysis_TangentModulus
    subroutine computeTangentModulus(state, params, tangent)
        type(MaterialState), intent(in) :: state
        real(wp), intent(in) :: params(:)
        real(wp), intent(out) :: tangent(6,6)
        
        ! 计算材料切线模量
        tangent = 0.0_wp
        
        ! 根据材料类型计算
        select case (int(params(1)))
            case (1)  ! 线性弹性
                call linearElasticTangent(params, tangent)
            case (2)  ! 超弹性
                call hyperelasticTangent(state, params, tangent)
            case (3)  ! 塑性
                call plasticTangent(state, params, tangent)
        end select
    end subroutine
end module
```

---

## Assembly/ - 组装模块域

### 功能描述
组装模块域负责材料矩阵组装和数值积分。

### 参考文档
- Zienkiewicz, O.C., Taylor, R.L. - The Finite Element Method
- Bathe, K.J. - Finite Element Procedures (Chapter 6)
- Cook, R.D., et al. - Concepts and Applications of Finite Element Analysis

### 材料刚度矩阵组装
```fortran
module MD_Assembly_Stiffness
    subroutine assembleMaterialStiffness(state, tangent, B, J, w, Ke)
        type(MaterialState), intent(in) :: state
        real(wp), intent(in) :: tangent(6,6)
        real(wp), intent(in) :: B(:,:)          ! 应变-位移矩阵
        real(wp), intent(in) :: J               ! 雅可比行列式
        real(wp), intent(in) :: w               ! 高斯权重
        real(wp), intent(out) :: Ke(:,:)        ! 单元刚度矩阵
        
        ! Ke = B^T * D * B * J * w
        real(wp) :: temp(size(B,1), size(tangent,2))
        
        temp = matmul(transpose(B), matmul(tangent, B))
        Ke = temp * J * w
    end subroutine
end module
```

### 材料质量矩阵组装
```fortran
module MD_Assembly_Mass
    subroutine assembleMaterialMass(density, N, J, w, Me)
        real(wp), intent(in) :: density
        real(wp), intent(in) :: N(:)             ! 形函数
        real(wp), intent(in) :: J               ! 雅可比行列式
        real(wp), intent(in) :: w               ! 高斯权重
        real(wp), intent(out) :: Me(:,:)        ! 单元质量矩阵
        
        ! Me = density * N^T * N * J * w
        Me = density * outer_product(N, N) * J * w
    end subroutine
end module
```

### 数值积分点处理
```fortran
module MD_Assembly_IntegrationPoint
    type :: IntegrationPoint
        real(wp) :: xi, eta, zeta
        real(wp) :: weight
        real(wp) :: J
        real(wp) :: detJ
        real(wp), allocatable :: stress(:)
        real(wp), allocatable :: strain(:)
        real(wp), allocatable :: historyVars(:)
    end type IntegrationPoint
    
    subroutine processIntegrationPoints(elemData, materialData, nGauss)
        type(ElementData), intent(inout) :: elemData
        type(MaterialData), intent(in) :: materialData
        integer, intent(in) :: nGauss
        
        type(IntegrationPoint), allocatable :: gaussPoints(:)
        integer :: i
        
        allocate(gaussPoints(nGauss))
        
        ! 获取高斯点和权重
        call getGaussPoints(nGauss, gaussPoints)
        
        ! 在每个积分点计算材料响应
        do i = 1, nGauss
            call computeMaterialResponse(gaussPoints(i), materialData)
            call assembleContribution(gaussPoints(i), elemData)
        end do
    end subroutine
end module
```

---

## Boundary/ - 边界条件域

### 功能描述
边界条件域处理材料边界条件。

### 参考文档
- Abaqus Analysis User's Manual - Boundary Conditions
- Cook, R.D., et al. - Concepts and Applications of Finite Element Analysis

### 位移边界条件
```fortran
module MD_Boundary_Displacement
    type :: MaterialBoundaryCondition
        integer :: boundaryType  ! 1=位移, 2=应力, 3=温度
        integer :: faceId
        real(wp), allocatable :: values(:)
        real(wp), allocatable :: timeFunction(:)
    end type MaterialBoundaryCondition
    
    subroutine applyMaterialBC(bc, materialState, time)
        type(MaterialBoundaryCondition), intent(in) :: bc
        type(MaterialState), intent(inout) :: materialState
        real(wp), intent(in) :: time
        
        select case (bc%boundaryType)
            case (1)  ! 位移边界条件
                materialState%strain = bc%values * bc%timeFunction(time)
            case (2)  ! 应力边界条件
                materialState%stress = bc%values * bc%timeFunction(time)
        end select
    end subroutine
end module
```

---

## Bridge/ - 桥接模块域

### 功能描述
桥接模块域提供材料域与物理层的接口。

### 参考文档
- Abaqus User Subroutines Reference Manual
- Design Patterns - Bridge Pattern

### UMAT接口桥接
```fortran
module MD_Bridge_UMAT
    ! Abaqus UMAT接口
    subroutine umat(stress, statev, ddsdde, sse, spd, scd, rpl, ddsddt, drpldt, drpldt, &
                     stran, dstran, time, dtime, temp, dtemp, predef, dpred, cmname, &
                     ndi, nshr, nstatv, props, nprops, coords, rot, pnewdt, celent, dfgrd0, &
                     dfgrd1, noel, npt, layer, kspt, kstep, kinc)
        ! 标准UMAT接口
        ! 应力更新
        ! 切线模量计算
        ! 状态变量更新
    end subroutine
    
    ! UFC内部UMAT桥接
    subroutine bridgeToUMAT(materialState, materialParams, strain, stress, tangent, dt)
        type(MaterialState), intent(inout) :: materialState
        real(wp), intent(in) :: materialParams(:)
        real(wp), intent(in) :: strain(:)
        real(wp), intent(out) :: stress(:)
        real(wp), intent(out) :: tangent(:,:)
        real(wp), intent(in) :: dt
        
        ! 转换为UMAT格式
        call convertToUMATFormat(materialState, materialParams, strain, dt)
        
        ! 调用UMAT
        call umat(...)
        
        ! 转换回UFC格式
        call convertFromUMATFormat(stress, tangent)
    end subroutine
end module
```

---

## Constraint/ - 约束模块域

### 功能描述
约束模块域处理材料约束条件。

### 参考文档
- Abaqus Analysis User's Manual - Constraints
- Belytschko, T., et al. - Nonlinear Finite Elements

### 不可压缩性约束
```fortran
module MD_Constraint_Incompressibility
    subroutine enforceIncompressibility(strain, stress, pressure, bulkModulus)
        real(wp), intent(in) :: strain(:)
        real(wp), intent(inout) :: stress(:)
        real(wp), intent(inout) :: pressure
        real(wp), intent(in) :: bulkModulus
        
        ! 体积应变
        real(wp) :: volStrain
        volStrain = strain(1) + strain(2) + strain(3)
        
        ! 压力更新
        pressure = pressure + bulkModulus * volStrain
        
        ! 应力修正
        stress(1) = stress(1) - pressure
        stress(2) = stress(2) - pressure
        stress(3) = stress(3) - pressure
    end subroutine
end module
```

---

## Field/ - 场变量域

### 功能描述
场变量域管理材料场变量。

### 参考文档
- Abaqus Analysis User's Manual - Fields
- Bathe, K.J. - Finite Element Procedures

### 温度场
```fortran
module MD_Field_Temperature
    type :: MaterialTemperatureField
        real(wp), allocatable :: temperature(:)
        real(wp), allocatable :: temperatureGradient(:)
        real(wp) :: referenceTemperature
        real(wp) :: thermalExpansionCoeff
    end type MaterialTemperatureField
    
    subroutine computeThermalStrain(tempField, thermalStrain)
        type(MaterialTemperatureField), intent(in) :: tempField
        real(wp), intent(out) :: thermalStrain(:)
        
        real(wp) :: deltaT
        deltaT = tempField%temperature(1) - tempField%referenceTemperature
        
        ! 热膨胀应变
        thermalStrain(1) = tempField%thermalExpansionCoeff * deltaT
        thermalStrain(2) = tempField%thermalExpansionCoeff * deltaT
        thermalStrain(3) = tempField%thermalExpansionCoeff * deltaT
        thermalStrain(4:6) = 0.0_wp
    end subroutine
end module
```

---

## Interaction/ - 相互作用域

### 功能描述
相互作用域处理材料间的相互作用。

### 参考文档
- Abaqus Analysis User's Manual - Interactions
- Wriggers, P. - Computational Contact Mechanics

### 界面相互作用
```fortran
module MD_Interaction_Interface
    type :: MaterialInterface
        integer :: material1Id
        integer :: material2Id
        real(wp) :: interfaceStiffness
        real(wp) :: interfaceFriction
        real(wp) :: interfaceCohesion
    end type MaterialInterface
    
    subroutine computeInterfaceForce(interface, displacement1, displacement2, interfaceForce)
        type(MaterialInterface), intent(in) :: interface
        real(wp), intent(in) :: displacement1(:), displacement2(:)
        real(wp), intent(out) :: interfaceForce(:)
        
        real(wp) :: relativeDisp(size(displacement1))
        real(wp) :: normalDisp, tangentDisp
        
        relativeDisp = displacement2 - displacement1
        
        ! 法向位移
        normalDisp = relativeDisp(1)
        
        ! 切向位移
        tangentDisp = sqrt(sum(relativeDisp(2:3)**2))
        
        ! 界面力
        interfaceForce(1) = interface%interfaceStiffness * normalDisp
        interfaceForce(2:3) = interface%interfaceFriction * relativeDisp(2:3)
    end subroutine
end module
```

---

## KeyWord/ - 关键字解析域

### 功能描述
关键字解析域处理材料关键字解析。

### 参考文档
- Abaqus Keywords Reference Manual
- Aho, A.V., et al. - Compilers: Principles, Techniques, and Tools

### 材料关键字解析
```fortran
module MD_KeyWord_Material
    subroutine parseMaterialKeyword(keywordLine, materialData)
        character(len=*), intent(in) :: keywordLine
        type(MaterialData), intent(out) :: materialData
        
        ! 解析关键字
        if (index(keywordLine, '*Material') > 0) then
            call parseMaterialHeader(keywordLine, materialData)
        else if (index(keywordLine, '*Elastic') > 0) then
            call parseElasticParams(keywordLine, materialData)
        else if (index(keywordLine, '*Hyperelastic') > 0) then
            call parseHyperelasticParams(keywordLine, materialData)
        else if (index(keywordLine, '*Plastic') > 0) then
            call parsePlasticParams(keywordLine, materialData)
        end if
    end subroutine
end module
```

---

## Material/ - 材料模型域

### 功能描述
材料模型域实现各种材料模型。

### 参考文档
- Abaqus Analysis User's Manual - Material Models
- Simo, J.C., Hughes, T.J.R. - Computational Inelasticity
- Holzapfel, G.A. - Nonlinear Solid Mechanics

### 超弹性材料
```fortran
module MD_Material_Hyperelastic
    ! Neo-Hookean模型
    subroutine neoHookean(strain, params, stress, tangent)
        real(wp), intent(in) :: strain(6)
        real(wp), intent(in) :: params(:)
        real(wp), intent(out) :: stress(6)
        real(wp), intent(out) :: tangent(6,6)
        
        real(wp) :: mu, lambda, J, J23
        real(wp) :: B(6)  ! 左Cauchy-Green张量
        
        mu = params(2)      ! 剪切模量
        lambda = params(3)   ! 拉梅常数
        
        ! 变形梯度
        call computeLeftCauchyGreen(strain, B)
        
        ! 体积J
        J = computeJacobian(strain)
        J23 = J**(-2.0_wp/3.0_wp)
        
        ! 应力
        stress = mu * B * J23
        
        ! 切线模量
        call computeNeoHookeanTangent(mu, lambda, B, J, tangent)
    end subroutine
    
    ! Mooney-Rivlin模型
    subroutine mooneyRivlin(strain, params, stress, tangent)
        real(wp), intent(in) :: strain(6)
        real(wp), intent(in) :: params(:)
        real(wp), intent(out) :: stress(6)
        real(wp), intent(out) :: tangent(6,6)
        
        real(wp) :: C10, C01, D1, J, B(6), I1, I2
        
        C10 = params(2)
        C01 = params(3)
        D1 = params(4)
        
        call computeInvariants(B, I1, I2, J)
        
        ! 应力
        stress = 2.0_wp * (C10 + C01 * I1) * B - 2.0_wp * C01 * B * B - &
                2.0_wp / D1 * (J - 1.0_wp) * J * identity
        
        ! 切线模量
        call computeMooneyRivlinTangent(C10, C01, D1, B, J, tangent)
    end subroutine
end module
```

### 塑性材料
```fortran
module MD_Material_Plastic
    ! J2塑性模型
    subroutine j2Plastic(strain, params, dt, stress, plasticStrain, tangent)
        real(wp), intent(in) :: strain(:)
        real(wp), intent(in) :: params(:)
        real(wp), intent(in) :: dt
        real(wp), intent(inout) :: stress(:)
        real(wp), intent(inout) :: plasticStrain(:)
        real(wp), intent(out) :: tangent(6,6)
        
        real(wp) :: yieldStress, hardeningModulus, elasticModulus
        real(wp) :: trialStress(6), devTrialStress(6)
        real(wp) :: equivalentStress, plasticIncrement
        real(wp) :: flowDirection(6)
        
        yieldStress = params(2)
        hardeningModulus = params(3)
        elasticModulus = params(4)
        
        ! 弹性预测
        trialStress = elasticModulus * (strain - plasticStrain)
        
        ! 偏应力
        devTrialStress = trialStress - (1.0_wp/3.0_wp) * sum(trialStress(1:3)) * [1,1,1,0,0,0]
        
        ! 等效应力
        equivalentStress = sqrt(1.5_wp * sum(devTrialStress**2))
        
        ! 屈服判定
        if (equivalentStress > yieldStress) then
            ! 塑性流动
            plasticIncrement = (equivalentStress - yieldStress) / (elasticModulus + hardeningModulus)
            flowDirection = 1.5_wp * devTrialStress / equivalentStress
            
            ! 更新塑性应变
            plasticStrain = plasticStrain + plasticIncrement * flowDirection
            
            ! 更新应力
            stress = trialStress - elasticModulus * plasticIncrement * flowDirection
        else
            stress = trialStress
        end if
        
        ! 切线模量
        call computeJ2Tangent(elasticModulus, hardeningModulus, flowDirection, tangent)
    end subroutine
end module
```

### 泡沫材料
```fortran
module MD_Material_Foam
    ! 可压溃泡沫模型
    subroutine crushableFoam(strain, params, stress, tangent)
        real(wp), intent(in) :: strain(6)
        real(wp), intent(in) params(:)
        real(wp), intent(out) :: stress(:)
        real(wp), intent(out) :: tangent(6,6)
        
        real(wp) :: E, nu, sigma_c, epsilon_c
        real(wp) :: volStrain, hydroStress
        
        E = params(2)
        nu = params(3)
        sigma_c = params(4)
        epsilon_c = params(5)
        
        ! 体积应变
        volStrain = strain(1) + strain(2) + strain(3)
        
        ! 静水应力
        hydroStress = E / (3.0_wp * (1.0_wp - 2.0_wp * nu)) * volStrain
        
        ! 压溃应力
        if (volStrain < epsilon_c) then
            stress = hydroStress * [1,1,1,0,0,0]
        else
            stress = sigma_c * [1,1,1,0,0,0]
        end if
        
        ! 切线模量
        call computeFoamTangent(E, nu, volStrain, tangent)
    end subroutine
end module
```

---

## Mesh/ - 网格管理域

### 功能描述
网格管理域处理材料相关的网格操作。

### 参考文档
- Abaqus Analysis User's Manual - Meshing
- Zienkiewicz, O.C., Taylor, R.L. - The Finite Element Method

### 网格质量评估
```fortran
module MD_Mesh_Quality
    type :: MeshQuality
        real(wp) :: aspectRatio
        real(wp) :: skewness
        real(wp) :: jacobianRatio
        real(wp) :: orthogonality
    end type MeshQuality
    
    subroutine evaluateMeshQuality(elemData, quality)
        type(ElementData), intent(in) :: elemData
        type(MeshQuality), intent(out) :: quality
        
        ! 计算纵横比
        call computeAspectRatio(elemData, quality%aspectRatio)
        
        ! 计算歪斜度
        call computeSkewness(elemData, quality%skewness)
        
        ! 计算雅可比比
        call computeJacobianRatio(elemData, quality%jacobianRatio)
        
        ! 计算正交性
        call computeOrthogonality(elemData, quality%orthogonality)
    end subroutine
end module
```

---

## Model/ - 模型管理域

### 功能描述
模型管理域管理材料模型参数和版本。

### 参考文档
- Abaqus Analysis User's Manual - Model Management

### 材料参数管理
```fortran
module MD_Model_Parameter
    type :: MaterialModel
        integer :: modelId
        character(len=50) :: modelName
        character(len=50) :: modelType
        real(wp), allocatable :: parameters(:)
        integer :: nParameters
        integer :: version
        character(len=100) :: description
    end type MaterialModel
    
    subroutine registerMaterialModel(model, modelDatabase)
        type(MaterialModel), intent(in) :: model
        type(ModelDatabase), intent(inout) :: modelDatabase
        
        ! 注册材料模型到数据库
        call addToDatabase(model, modelDatabase)
    end subroutine
end module
```

---

## Output/ - 输出模块域

### 功能描述
输出模块域处理材料结果输出。

### 参考文档
- Abaqus Analysis User's Manual - Output
- Bathe, K.J. - Finite Element Procedures (Chapter 12)

### 应力输出
```fortran
module MD_Output_Stress
    subroutine outputStress(state, outputFile, format)
        type(MaterialState), intent(in) :: state
        character(len=*), intent(in) :: outputFile
        integer, intent(in) :: format
        
        select case (format)
            case (1)  ! ASCII
                write(outputFile, '(6E15.7)') state%stress
            case (2)  ! Binary
                write(outputFile) state%stress
            case (3)  ! HDF5
                call writeHDF5(outputFile, state%stress)
        end select
    end subroutine
end module
```

---

## Part/ - 部件管理域

### 功能描述
部件管理域管理材料部件。

### 参考文档
- Abaqus Analysis User's Manual - Parts

### 部件定义
```fortran
module MD_Part_Definition
    type :: MaterialPart
        integer :: partId
        character(len=50) :: partName
        integer :: materialId
        integer, allocatable :: elementIds(:)
        integer, allocatable :: nodeIds(:)
        real(wp) :: volume
        real(wp) :: mass
    end type MaterialPart
    
    subroutine createPart(partId, partName, materialId, part)
        integer, intent(in) :: partId
        character(len=*), intent(in) :: partName
        integer, intent(in) :: materialId
        type(MaterialPart), intent(out) :: part
        
        part%partId = partId
        part%partName = trim(partName)
        part%materialId = materialId
    end subroutine
end module
```

---

## Section/ - 截面属性域

### 功能描述
截面属性域定义材料截面属性。

### 参考文档
- Abaqus Analysis User's Manual - Sections
- Bathe, K.J. - Finite Element Procedures (Chapter 5)

### 实体截面
```fortran
module MD_Section_Solid
    type :: SolidSection
        integer :: sectionId
        character(len=50) :: sectionName
        integer :: materialId
        real(wp) :: thickness  ! 对于2D问题
        logical :: planeStress  ! 平面应力/平面应变
    end type SolidSection
    
    subroutine defineSolidSection(sectionId, sectionName, materialId, thickness, planeStress, section)
        integer, intent(in) :: sectionId
        character(len=*), intent(in) :: sectionName
        integer, intent(in) :: materialId
        real(wp), intent(in) :: thickness
        logical, intent(in) :: planeStress
        type(SolidSection), intent(out) :: section
        
        section%sectionId = sectionId
        section%sectionName = trim(sectionName)
        section%materialId = materialId
        section%thickness = thickness
        section%planeStress = planeStress
    end subroutine
end module
```

### 壳截面
```fortran
module MD_Section_Shell
    type :: ShellSection
        integer :: sectionId
        character(len=50) :: sectionName
        integer :: materialId
        real(wp) :: thickness
        integer :: numLayers
        real(wp), allocatable :: layerThickness(:)
        integer, allocatable :: layerMaterialId(:)
        real(wp), allocatable :: layerOrientation(:)
    end type ShellSection
    
    subroutine defineShellSection(sectionId, sectionName, materialId, thickness, numLayers, section)
        integer, intent(in) :: sectionId
        character(len=*), intent(in) :: sectionName
        integer, intent(in) :: materialId
        real(wp), intent(in) :: thickness
        integer, intent(in) :: numLayers
        type(ShellSection), intent(out) :: section
        
        section%sectionId = sectionId
        section%sectionName = trim(sectionName)
        section%materialId = materialId
        section%thickness = thickness
        section%numLayers = numLayers
        
        allocate(section%layerThickness(numLayers))
        allocate(section%layerMaterialId(numLayers))
        allocate(section%layerOrientation(numLayers))
    end subroutine
end module
```

---

## WriteBack/ - 写回模块域

### 功能描述
写回模块域处理材料状态写回。

### 参考文档
- Abaqus Analysis User's Manual - State Storage
- Database Design Patterns

### 状态存储
```fortran
module MD_WriteBack_StateStorage
    subroutine saveMaterialState(state, stateFile)
        type(MaterialState), intent(in) :: state
        character(len=*), intent(in) :: stateFile
        
        ! 保存状态到文件
        open(unit=10, file=stateFile, status='replace', action='write')
        write(10) state%stress
        write(10) state%strain
        write(10) state%plasticStrain
        write(10) state%historyVars
        write(10) state%stateVars
        write(10) state%equivalentStrain
        write(10) state%equivalentStress
        close(10)
    end subroutine
    
    subroutine restoreMaterialState(state, stateFile)
        type(MaterialState), intent(out) :: state
        character(len=*), intent(in) :: stateFile
        
        ! 从文件恢复状态
        open(unit=10, file=stateFile, status='old', action='read')
        read(10) state%stress
        read(10) state%strain
        read(10) state%plasticStrain
        read(10) state%historyVars
        read(10) state%stateVars
        read(10) state%equivalentStrain
        read(10) state%equivalentStress
        close(10)
    end subroutine
end module
```

### 重启动文件
```fortran
module MD_WriteBack_Restart
    subroutine writeRestartFile(state, restartFile)
        type(MaterialState), intent(in) :: state
        character(len=*), intent(in) :: restartFile
        
        ! 写入重启动文件
        call saveMaterialState(state, restartFile)
        
        ! 写入附加信息
        open(unit=10, file=trim(restartFile)//'.info', status='replace', action='write')
        write(10, *) state%nHistoryVars
        write(10, *) state%nStateVars
        write(10, *) state%converged
        close(10)
    end subroutine
end module
```

---

## 总结

L3_MD材料域包含13个主要域：
1. **Analysis/** - 分析模块域：状态初始化、应力计算、切线模量
2. **Assembly/** - 组装模块域：刚度矩阵、质量矩阵、积分点
3. **Boundary/** - 边界条件域：位移边界、应力边界
4. **Bridge/** - 桥接模块域：UMAT接口、数据转换
5. **Constraint/** - 约束模块域：不可压缩性约束
6. **Field/** - 场变量域：温度场、热膨胀
7. **Interaction/** - 相互作用域：界面相互作用
8. **KeyWord/** - 关键字解析域：材料关键字解析
9. **Material/** - 材料模型域：超弹性、塑性、泡沫材料
10. **Mesh/** - 网格管理域：网格质量评估
11. **Model/** - 模型管理域：参数管理、版本控制
12. **Output/** - 输出模块域：应力输出、应变输出
13. **Part/** - 部件管理域：部件定义、部件关联
14. **Section/** - 截面属性域：实体截面、壳截面
15. **WriteBack/** - 写回模块域：状态存储、重启动文件

每个模块都有详细的算法实现、接口定义和参考文档。
