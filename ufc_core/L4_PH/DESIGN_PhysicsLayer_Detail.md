# L4_PH 物理层详细设计说明

## 概述
L4_PH Physics Layer是UFC的物理计算核心，负责单元计算、接触处理、载荷应用等物理场计算。

---

## Bridge/ - 桥接模块域

### 功能描述
桥接模块域提供物理层与运行时层的数据接口和适配。

### 参考文档
- Abaqus User Subroutines Reference Manual
- Design Patterns - Bridge Pattern
- Software Engineering - Interface Design

### 数据结构转换
```fortran
module PH_Bridge_DataConversion
    ! 物理层数据结构
    type :: PhysicsData
        real(wp), allocatable :: displacement(:)
        real(wp), allocatable :: velocity(:)
        real(wp), allocatable :: acceleration(:)
        real(wp), allocatable :: stress(:)
        real(wp), allocatable :: strain(:)
        real(wp), allocatable :: internalForce(:)
    end type PhysicsData
    
    ! 运行时层数据结构
    type :: RuntimeData
        real(wp), allocatable :: u(:)      ! 位移
        real(wp), allocatable :: v(:)      ! 速度
        real(wp), allocatable :: a(:)      ! 加速度
        real(wp), allocatable :: F(:)      ! 力
        real(wp), allocatable :: R(:)      ! 残差
    end type RuntimeData
    
    ! 数据转换接口
    subroutine physicsToRuntime(physicsData, runtimeData)
        type(PhysicsData), intent(in) :: physicsData
        type(RuntimeData), intent(out) :: runtimeData
        
        runtimeData%u = physicsData%displacement
        runtimeData%v = physicsData%velocity
        runtimeData%a = physicsData%acceleration
        runtimeData%F = physicsData%internalForce
    end subroutine
end module
```

### 接口适配
```fortran
module PH_Bridge_InterfaceAdapter
    ! 单元接口适配
    interface
        subroutine elementBridge(elemData, solverData)
            type(ElementData), intent(inout) :: elemData
            type(SolverData), intent(inout) :: solverData
        end subroutine
    end interface
    
    ! 材料接口适配
    interface
        subroutine materialBridge(matData, physicsData)
            type(MaterialData), intent(inout) :: matData
            type(PhysicsData), intent(inout) :: physicsData
        end subroutine
    end interface
    
    ! 接触接口适配
    interface
        subroutine contactBridge(contactData, physicsData)
            type(ContactData), intent(inout) :: contactData
            type(PhysicsData), intent(inout) :: physicsData
        end subroutine
    end interface
end module
```

### 版本兼容
- 数据格式版本控制
- 接口版本控制
- 向后兼容处理
- 迁移工具

### 错误传播
- 错误码映射
- 错误消息转换
- 错误处理策略
- 错误恢复机制

---

## Constraint/ - 约束模块域

### 功能描述
约束模块域处理各种约束条件，包括多点约束、耦合约束、刚体约束等。

### 参考文档
- Abaqus Analysis User's Manual - Constraints
- Belytschko, T., et al. - Nonlinear Finite Elements for Continua and Structures
- Cook, R.D., et al. - Concepts and Applications of Finite Element Analysis

### 多点约束（MPC）
```fortran
module PH_Constraint_MPC
    type :: MPCConstraint
        integer :: nNodes
        integer, allocatable :: nodeIds(:)
        integer, allocatable :: dofIds(:)
        real(wp), allocatable :: coefficients(:)
        real(wp) :: rhsValue
    end type MPCConstraint
    
    subroutine applyMPC(constraint, displacement, residual)
        type(MPCConstraint), intent(in) :: constraint
        real(wp), intent(inout) :: displacement(:)
        real(wp), intent(inout) :: residual(:)
        
        ! 应用多点约束
        ! sum(coefficients * u) = rhsValue
        real(wp) :: constraintValue
        
        constraintValue = sum(constraint%coefficients * displacement(constraint%nodeIds))
        
        ! 修正残差
        residual(constraint%nodeIds) = residual(constraint%nodeIds) + &
            constraint%coefficients * (constraintValue - constraint%rhsValue)
    end subroutine
end module
```

### 耦合约束
```fortran
module PH_Constraint_Coupling
    type :: CouplingConstraint
        integer :: refNodeId          ! 参考点
        integer, allocatable :: coupledNodes(:)  ! 耦合节点
        integer :: couplingType       ! 耦合类型
        real(wp) :: couplingWeight    ! 耦合权重
    end type CouplingConstraint
    
    subroutine applyCoupling(constraint, displacement)
        type(CouplingConstraint), intent(in) :: constraint
        real(wp), intent(inout) :: displacement(:)
        
        ! 运动耦合
        ! u_coupled = u_ref * weight
        displacement(constraint%coupledNodes) = &
            displacement(constraint%refNodeId) * constraint%couplingWeight
    end subroutine
end module
```

### 刚体约束
```fortran
module PH_Constraint_RigidBody
    type :: RigidBodyConstraint
        integer :: refNodeId          ! 参考点
        integer, allocatable :: rigidNodes(:)    ! 刚体节点
        real(wp) :: totalMass         ! 总质量
        real(wp) :: momentOfInertia(3,3)  ! 惯性张量
    end type RigidBodyConstraint
    
    subroutine applyRigidBody(constraint, displacement, rotation)
        type(RigidBodyConstraint), intent(in) :: constraint
        real(wp), intent(inout) :: displacement(:)
        real(wp), intent(in) :: rotation(3)
        
        ! 刚体运动
        ! u_rigid = u_ref + R * (x - x_ref)
        integer :: i
        real(wp) :: r(3), u_rigid(3)
        
        do i = 1, size(constraint%rigidNodes)
            r = getNodePosition(constraint%rigidNodes(i)) - &
                getNodePosition(constraint%refNodeId)
            u_rigid = displacement(constraint%refNodeId) + matmul(rotation, r)
            displacement(constraint%rigidNodes(i)) = u_rigid
        end do
    end subroutine
end module
```

### 约束求解
```fortran
module PH_Constraint_Solver
    subroutine solveConstraints(constraints, displacement, residual)
        type(ConstraintArray), intent(in) :: constraints
        real(wp), intent(inout) :: displacement(:)
        real(wp), intent(inout) :: residual(:)
        
        ! 拉格朗日乘子法
        call lagrangeMultiplier(constraints, displacement, residual)
        
        ! 罚函数法
        call penaltyMethod(constraints, displacement, residual)
        
        ! 增广拉格朗日法
        call augmentedLagrangian(constraints, displacement, residual)
    end subroutine
end module
```

---

## Contact/ - 接触模块域

### 功能描述
接触模块域处理各种接触算法，包括面面接触、点面接触、自接触等。

### 参考文档
- Abaqus Analysis User's Manual - Contact
- Wriggers, P. - Computational Contact Mechanics
- Laursen, T.A. - Computational Contact and Impact Mechanics

### 面面接触
```fortran
module PH_Contact_SurfaceToSurface
    type :: SurfaceToSurfaceContact
        integer :: masterSurfaceId
        integer :: slaveSurfaceId
        real(wp) :: penaltyStiffness
        real(wp) :: frictionCoeff
        integer :: contactAlgorithm  ! 1=罚函数, 2=拉格朗日
    end type SurfaceToSurfaceContact
    
    subroutine detectSurfaceToSurface(contact, meshData, contactPairs)
        type(SurfaceToSurfaceContact), intent(in) :: contact
        type(MeshData), intent(in) :: meshData
        type(ContactPair), intent(out) :: contactPairs(:)
        
        ! 接触检测算法
        ! 1. 包围盒检测
        ! 2. 近邻搜索
        ! 3. 精确检测
        
        call boundingBoxDetection(contact, meshData, contactPairs)
        call nearestNeighborSearch(contact, meshData, contactPairs)
        call exactDetection(contact, meshData, contactPairs)
    end subroutine
end module
```

### 点面接触
```fortran
module PH_Contact_NodeToSurface
    type :: NodeToSurfaceContact
        integer, allocatable :: nodeIds(:)
        integer :: surfaceId
        real(wp) :: penaltyStiffness
        real(wp) :: frictionCoeff
    end type NodeToSurfaceContact
    
    subroutine detectNodeToSurface(contact, meshData, contactPairs)
        type(NodeToSurfaceContact), intent(in) :: contact
        type(MeshData), intent(in) :: meshData
        type(ContactPair), intent(out) :: contactPairs(:)
        
        ! 点面接触检测
        ! 计算节点到面的距离
        ! 判断是否穿透
    end subroutine
end module
```

### 自接触
```fortran
module PH_Contact_SelfContact
    type :: SelfContact
        integer :: surfaceId
        real(wp) :: penaltyStiffness
        real(wp) :: minDistance  ! 最小距离阈值
    end type SelfContact
    
    subroutine detectSelfContact(contact, meshData, contactPairs)
        type(SelfContact), intent(in) :: contact
        type(MeshData), intent(in) :: meshData
        type(ContactPair), intent(out) :: contactPairs(:)
        
        ! 自接触检测
        ! 检测面的自相交
        ! 基于曲率的检测
    end subroutine
end module
```

### 摩擦接触
```fortran
module PH_Contact_Friction
    type :: FrictionContact
        real(wp) :: mu  ! 摩擦系数
        integer :: frictionModel  ! 1=库仑, 2=罚函数, 3=指数
        real(wp) :: viscousFriction  ! 粘性摩擦系数
    end type FrictionContact
    
    subroutine computeFrictionForce(contact, contactPairs, frictionForce)
        type(FrictionContact), intent(in) :: contact
        type(ContactPair), intent(in) :: contactPairs(:)
        real(wp), intent(out) :: frictionForce(:)
        
        ! 计算摩擦力
        select case (contact%frictionModel)
            case (1)
                call coulombFriction(contact, contactPairs, frictionForce)
            case (2)
                call penaltyFriction(contact, contactPairs, frictionForce)
            case (3)
                call exponentialFriction(contact, contactPairs, frictionForce)
        end select
    end subroutine
end module
```

### 接触力计算
```fortran
module PH_Contact_Force
    subroutine computeContactForce(contact, contactPairs, contactForce, contactStiffness)
        type(ContactData), intent(in) :: contact
        type(ContactPair), intent(in) :: contactPairs(:)
        real(wp), intent(out) :: contactForce(:)
        real(wp), intent(out) :: contactStiffness(:,:)
        
        ! 罚函数法
        contactForce = contact%penaltyStiffness * penetration
        
        ! 拉格朗日乘子法
        call lagrangeMultiplier(contact, contactPairs, contactForce)
        
        ! 组装接触刚度
        call assembleContactStiffness(contact, contactPairs, contactStiffness)
    end subroutine
end module
```

---

## Element/ - 单元库域

### 功能描述
单元库域实现各种单元类型，包括实体单元、壳单元、梁单元等。

### 参考文档
- Abaqus Analysis User's Manual - Element Library
- Bathe, K.J. - Finite Element Procedures (Chapter 5)
- Zienkiewicz, O.C., Taylor, R.L. - The Finite Element Method
- Cook, R.D., et al. - Concepts and Applications of Finite Element Analysis

### 实体单元（Solid）
```fortran
module PH_Element_Solid
    ! C3D8单元实现
    subroutine PH_Element_C3D8(elemData, meshData, dt)
        type(ElementData), intent(inout) :: elemData
        type(MeshData), intent(in) :: meshData
        real(wp), intent(in) :: dt
        
        ! 1. 形函数计算
        call computeShapeFunction(elemData, meshData)
        
        ! 2. 雅可比计算
        call computeJacobian(elemData, meshData)
        
        ! 3. 应变-位移矩阵（B矩阵）
        call computeBMatrix(elemData)
        
        ! 4. 刚度矩阵组装
        call assembleStiffness(elemData, meshData)
        
        ! 5. 质量矩阵组装
        call assembleMass(elemData, meshData)
        
        ! 6. 残差计算
        call computeResidual(elemData, meshData)
        
        ! 7. 应力计算
        call computeStress(elemData, meshData)
    end subroutine
    
    subroutine computeShapeFunction(elemData, meshData)
        type(ElementData), intent(inout) :: elemData
        type(MeshData), intent(in) :: meshData
        
        ! C3D8形函数
        ! N1 = (1-xi)(1-eta)(1-zeta)/8
        ! N2 = (1+xi)(1-eta)(1-zeta)/8
        ! ...
    end subroutine
end module
```

### 壳单元（Shell）
```fortran
module PH_Element_Shell
    ! S4单元实现
    subroutine PH_Element_S4(elemData, meshData, dt)
        type(ElementData), intent(inout) :: elemData
        type(MeshData), intent(in) :: meshData
        real(wp), intent(in) :: dt
        
        ! 1. 形函数计算
        call computeShellShapeFunction(elemData)
        
        ! 2. 厚度方向处理
        call handleThicknessDirection(elemData)
        
        ! 3. 膜应变计算
        call computeMembraneStrain(elemData)
        
        ! 4. 弯曲应变计算
        call computeBendingStrain(elemData)
        
        ! 5. 剪切应变计算
        call computeShearStrain(elemData)
        
        ! 6. 刚度矩阵组装
        call assembleShellStiffness(elemData)
        
        ! 7. 沙漏控制
        call hourglassControl(elemData)
    end subroutine
end module
```

### 梁单元（Beam）
```fortran
module PH_Element_Beam
    ! B31单元实现
    subroutine PH_Element_B31(elemData, meshData, dt)
        type(ElementData), intent(inout) :: elemData
        type(MeshData), intent(in) :: meshData
        real(wp), intent(in) :: dt
        
        ! 1. 形函数计算
        call computeBeamShapeFunction(elemData)
        
        ! 2. 局部坐标系
        call computeLocalCoordinateSystem(elemData)
        
        ! 3. 轴向应变计算
        call computeAxialStrain(elemData)
        
        ! 4. 弯曲应变计算
        call computeBendingStrain(elemData)
        
        ! 5. 扭转应变计算
        call computeTorsionalStrain(elemData)
        
        ! 6. 剪切变形计算
        call computeShearDeformation(elemData)
        
        ! 7. 刚度矩阵组装
        call assembleBeamStiffness(elemData)
    end subroutine
end module
```

### 形函数库
```fortran
module PH_Element_ShapeFunction
    ! 线性形函数
    subroutine linearShapeFunction(xi, eta, zeta, N)
        real(wp), intent(in) :: xi, eta, zeta
        real(wp), intent(out) :: N(:)
        
        N(1) = (1.0_wp - xi) * (1.0_wp - eta) * (1.0_wp - zeta) / 8.0_wp
        N(2) = (1.0_wp + xi) * (1.0_wp - eta) * (1.0_wp - zeta) / 8.0_wp
        ! ...
    end subroutine
    
    ! 二次形函数
    subroutine quadraticShapeFunction(xi, eta, zeta, N)
        real(wp), intent(in) :: xi, eta, zeta
        real(wp), intent(out) :: N(:)
        
        ! Serendipity单元形函数
    end subroutine
    
    ! 形函数导数
    subroutine shapeFunctionDerivatives(xi, eta, zeta, dN)
        real(wp), intent(in) :: xi, eta, zeta
        real(wp), intent(out) :: dN(:,:)
        
        ! 计算形函数对局部坐标的导数
    end subroutine
end module
```

### 高斯积分
```fortran
module PH_Element_GaussIntegration
    ! 高斯点和权重
    subroutine getGaussPointsAndWeights(order, gaussPoints, weights)
        integer, intent(in) :: order
        real(wp), intent(out) :: gaussPoints(:,:)
        real(wp), intent(out) :: weights(:)
        
        select case (order)
            case (2)
                ! 2点高斯积分
                gaussPoints(1,:) = [-1.0_wp/sqrt(3.0_wp), -1.0_wp/sqrt(3.0_wp)]
                gaussPoints(2,:) = [1.0_wp/sqrt(3.0_wp), 1.0_wp/sqrt(3.0_wp)]
                weights = [1.0_wp, 1.0_wp]
            case (3)
                ! 3点高斯积分
                ! ...
        end select
    end subroutine
    
    ! 数值积分
    subroutine numericalIntegration(integrand, gaussPoints, weights, result)
        interface
            real(wp) function integrand(xi, eta)
                real(wp), intent(in) :: xi, eta
            end function
        end interface
        real(wp), intent(in) :: gaussPoints(:,:), weights(:)
        real(wp), intent(out) :: result
        
        integer :: i
        result = 0.0_wp
        do i = 1, size(weights)
            result = result + weights(i) * integrand(gaussPoints(i,1), gaussPoints(i,2))
        end do
    end subroutine
end module
```

---

## Field/ - 场变量域

### 功能描述
场变量域管理各种物理场变量，包括位移场、速度场、温度场等。

### 参考文档
- Abaqus Analysis User's Manual - Fields
- Bathe, K.J. - Finite Element Procedures (Chapter 6)
- Hughes, T.J.R. - The Finite Element Method

### 位移场
```fortran
module PH_Field_Displacement
    type :: DisplacementField
        integer :: nNodes
        integer :: nDof
        real(wp), allocatable :: u(:)      ! 位移向量
        real(wp), allocatable :: du(:)     ! 位移增量
        real(wp), allocatable :: u_old(:)  ! 旧位移
        real(wp), allocatable :: u_new(:)  ! 新位移
    end type DisplacementField
    
    subroutine updateDisplacement(field, du)
        type(DisplacementField), intent(inout) :: field
        real(wp), intent(in) :: du(:)
        
        field%u_old = field%u
        field%u = field%u + du
        field%du = du
    end subroutine
end module
```

### 速度场
```fortran
module PH_Field_Velocity
    type :: VelocityField
        integer :: nNodes
        integer :: nDof
        real(wp), allocatable :: v(:)      ! 速度向量
        real(wp), allocatable :: v_old(:)  ! 旧速度
        real(wp), allocatable :: v_new(:)  ! 新速度
    end type VelocityField
    
    subroutine updateVelocity(field, dv, dt)
        type(VelocityField), intent(inout) :: field
        real(wp), intent(in) :: dv(:)
        real(wp), intent(in) :: dt
        
        field%v_old = field%v
        field%v = field%v + dv / dt
    end subroutine
end module
```

### 温度场
```fortran
module PH_Field_Temperature
    type :: TemperatureField
        integer :: nNodes
        real(wp), allocatable :: T(:)      ! 温度向量
        real(wp), allocatable :: T_old(:)  ! 旧温度
        real(wp), allocatable :: T_new(:)  ! 新温度
        real(wp) :: referenceTemperature  ! 参考温度
    end type TemperatureField
    
    subroutine updateTemperature(field, dT)
        type(TemperatureField), intent(inout) :: field
        real(wp), intent(in) :: dT(:)
        
        field%T_old = field%T
        field%T = field%T + dT
    end subroutine
end module
```

### 场插值
```fortran
module PH_Field_Interpolation
    subroutine interpolateField(field, gaussPoint, interpolatedValue)
        type(FieldData), intent(in) :: field
        real(wp), intent(in) :: gaussPoint(:)
        real(wp), intent(out) :: interpolatedValue
        
        ! 使用形函数插值
        real(wp) :: N(size(field%values))
        
        call computeShapeFunction(gaussPoint, N)
        interpolatedValue = dot_product(N, field%values)
    end subroutine
end module
```

---

## LoadBC/ - 载荷边界条件域

### 功能描述
载荷边界条件域处理各种载荷类型和边界条件。

### 参考文档
- Abaqus Analysis User's Manual - Loads and Boundary Conditions
- Cook, R.D., et al. - Concepts and Applications of Finite Element Analysis

### 载荷类型
```fortran
module PH_LoadBC_Load
    type :: ConcentratedLoad
        integer :: nodeId
        integer :: dofId
        real(wp) :: magnitude
        real(wp) :: direction(3)
        real(wp), allocatable :: timeFunction(:)  ! 时间函数
    end type ConcentratedLoad
    
    type :: PressureLoad
        integer :: surfaceId
        real(wp) :: pressure
        real(wp) :: direction(3)
        real(wp), allocatable :: timeFunction(:)
    end type PressureLoad
    
    type :: GravityLoad
        real(wp) :: gravity(3)
        real(wp) :: density
    end type GravityLoad
    
    subroutine applyLoad(load, meshData, forceVector, time)
        class(LoadBase), intent(in) :: load
        type(MeshData), intent(in) :: meshData
        real(wp), intent(inout) :: forceVector(:)
        real(wp), intent(in) :: time
        
        select type (load)
            type is (ConcentratedLoad)
                call applyConcentratedLoad(load, forceVector, time)
            type is (PressureLoad)
                call applyPressureLoad(load, meshData, forceVector, time)
            type is (GravityLoad)
                call applyGravityLoad(load, meshData, forceVector)
        end select
    end subroutine
end module
```

### 边界条件
```fortran
module PH_LoadBC_BoundaryCondition
    type :: DisplacementBC
        integer :: nodeId
        integer :: dofId
        real(wp) :: displacement
        real(wp), allocatable :: timeFunction(:)
    end type DisplacementBC
    
    type :: VelocityBC
        integer :: nodeId
        integer :: dofId
        real(wp) :: velocity
        real(wp), allocatable :: timeFunction(:)
    end type VelocityBC
    
    subroutine applyBC(bc, displacement, time)
        class(BCBase), intent(in) :: bc
        real(wp), intent(inout) :: displacement(:)
        real(wp), intent(in) :: time
        
        select type (bc)
            type is (DisplacementBC)
                displacement(bc%nodeId * 3 + bc%dofId) = bc%displacement * bc%timeFunction(time)
            type is (VelocityBC)
                ! 速度边界条件处理
        end select
    end subroutine
end module
```

### 载荷随时间变化
```fortran
module PH_LoadBC_TimeFunction
    real(wp) function timeFunction(time, functionType, parameters)
        real(wp), intent(in) :: time
        integer, intent(in) :: functionType
        real(wp), intent(in) :: parameters(:)
        
        select case (functionType)
            case (1)  ! 阶跃函数
                timeFunction = parameters(1)
            case (2)  ! 线性函数
                timeFunction = parameters(1) + parameters(2) * time
            case (3)  ! 正弦函数
                timeFunction = parameters(1) * sin(parameters(2) * time + parameters(3))
            case (4)  ! 表格插值
                timeFunction = interpolateTable(time, parameters)
        end select
    end function
end module
```

---

## Material/ - 材料接口域

### 功能描述
材料接口域提供物理层与材料层的接口。

### 参考文档
- Abaqus Analysis User's Manual - Material Models
- Simo, J.C., Hughes, T.J.R. - Computational Inelasticity

### 材料模型调用
```fortran
module PH_Mat_Interface
    subroutine callMaterialModel(materialId, strain, dt, stress, tangent)
        integer, intent(in) :: materialId
        real(wp), intent(in) :: strain(:)
        real(wp), intent(in) :: dt
        real(wp), intent(out) :: stress(:)
        real(wp), intent(out) :: tangent(:,:)
        
        ! 根据材料ID调用相应的材料模型
        select case (materialId)
            case (1)
                call neoHookean(strain, dt, stress, tangent)
            case (2)
                call mooneyRivlin(strain, dt, stress, tangent)
            case (3)
                call arrudaBoyce(strain, dt, stress, tangent)
        end select
    end subroutine
end module
```

### 材料参数传递
```fortran
module PH_Mat_ParameterPassing
    type :: MaterialParameters
        integer :: materialId
        character(len=50) :: materialName
        real(wp), allocatable :: params(:)
        integer :: nParams
    end type MaterialParameters
    
    subroutine passParametersToMaterial(materialParams, materialData)
        type(MaterialParameters), intent(in) :: materialParams
        type(MaterialData), intent(out) :: materialData
        
        materialData%materialId = materialParams%materialId
        materialData%materialName = materialParams%materialName
        materialData%params = materialParams%params
        materialData%nParams = materialParams%nParams
    end subroutine
end module
```

### 材料状态传递
```fortran
module PH_Mat_StatePassing
    type :: MaterialState
        real(wp), allocatable :: stress(:)
        real(wp), allocatable :: strain(:)
        real(wp), allocatable :: historyVars(:)
        real(wp), allocatable :: stateVars(:)
        integer :: nHistoryVars
        integer :: nStateVars
    end type MaterialState
    
    subroutine updateMaterialState(materialState, newStress, newStrain, newHistoryVars)
        type(MaterialState), intent(inout) :: materialState
        real(wp), intent(in) :: newStress(:), newStrain(:)
        real(wp), intent(in) :: newHistoryVars(:)
        
        materialState%stress = newStress
        materialState%strain = newStrain
        materialState%historyVars = newHistoryVars
    end subroutine
end module
```

---

## 总结

L4_PH物理层包含7个主要域：
1. **Bridge/** - 桥接模块域：数据结构转换、接口适配、版本兼容、错误传播
2. **Constraint/** - 约束模块域：MPC、耦合约束、刚体约束、约束求解
3. **Contact/** - 接触模块域：面面接触、点面接触、自接触、摩擦接触
4. **Element/** - 单元库域：实体单元、壳单元、梁单元、形函数库、高斯积分
5. **Field/** - 场变量域：位移场、速度场、温度场、场插值
6. **LoadBC/** - 载荷边界条件域：载荷类型、边界条件、时间函数
7. **Material/** - 材料接口域：材料模型调用、参数传递、状态传递

每个模块都有详细的算法实现、接口定义和参考文档。
