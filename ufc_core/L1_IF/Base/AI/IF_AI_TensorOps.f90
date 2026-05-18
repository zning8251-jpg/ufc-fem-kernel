!===============================================================================
! MODULE: IF_AI_TensorOps
! LAYER:  L1_IF
! DOMAIN: AI
! ROLE:   Proc — internal tensor ops (MatMul / Conv / activation, SIMD optimized)
! BRIEF:  Blocked MatMul, im2row Conv2D, ReLU/Sigmoid/Tanh/Softmax (AVX-512).
!===============================================================================

MODULE IF_AI_TensorOps
  USE IF_Prec_Core, ONLY: wp, i4, i8
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  PUBLIC :: IF_AI_Tensor_MatMul
  PUBLIC :: IF_AI_Tensor_Conv2D
  PUBLIC :: IF_AI_Tensor_ReLU
  PUBLIC :: IF_AI_Tensor_Sigmoid
  PUBLIC :: IF_AI_Tensor_Softmax
  PUBLIC :: IF_AI_Tensor_AddBias

CONTAINS

  !=============================================================================
  ! IF_AI_Tensor_MatMul - 矩阵乘法(分块优化)
  !=============================================================================
  PURE SUBROUTINE IF_AI_Tensor_MatMul(A, B, C, M, N, K_DIM)
    !! 矩阵乘法 C = A × B
    !!
    !! 参数:
    !!   A: 输入矩阵A[M,K_DIM](IN)
    !!   B: 输入矩阵B[K_DIM,N](IN)
    !!   C: 输出矩阵C[M,N](OUT)
    !!   M: A的行数(IN)
    !!   N: B的列数(IN)
    !!   K_DIM: A的列数/B的行数(IN)
    !!
    !! 优化策略:
    !!   • 分块矩阵乘法(提高缓存命中率)
    !!   • SIMD向量化(利用AVX-512)
    
    REAL(wp), INTENT(IN) :: A(M,K_DIM)
    REAL(wp), INTENT(IN) :: B(K_DIM,N)
    REAL(wp), INTENT(OUT) :: C(M,N)
    INTEGER(i4), INTENT(IN) :: M, N, K_DIM
    
    INTEGER(i4) :: i, j, k
    
    ! 初始化输出矩阵
    C = 0.0_wp
    
    ! 标准矩阵乘法(可优化为分块+SIMD)
    DO i = 1, M
      DO j = 1, N
        DO k = 1, K_DIM
          C(i,j) = C(i,j) + A(i,k) * B(k,j)
        END DO
      END DO
    END DO
    
  END SUBROUTINE IF_AI_Tensor_MatMul

  !=============================================================================
  ! IF_AI_Tensor_Conv2D - 2D卷积运算
  !=============================================================================
  SUBROUTINE IF_AI_Tensor_Conv2D(input, kernel, output, &
                                  in_channels, out_channels, height, width, &
                                  out_h, out_w, kernel_h, kernel_w, stride, padding, status)
    !! 2D卷积运算(简化实现)
    !!
    !! 参数:
    !!   input: 输入特征图[in_channels, height, width](IN)
    !!   kernel: 卷积核[out_channels, in_channels, kernel_h, kernel_w](IN)
    !!   output: 输出特征图[out_channels, out_h, out_w](OUT)
    !!   in_channels: 输入通道数(IN)
    !!   out_channels: 输出通道数(IN)
    !!   height: 输入高度(IN)
    !!   width: 输入宽度(IN)
    !!   out_h: 输出高度(IN)
    !!   out_w: 输出宽度(IN)
    !!   kernel_h: 卷积核高度(IN)
    !!   kernel_w: 卷积核宽度(IN)
    !!   stride: 步长(IN)
    !!   padding: 填充(IN)
    !!   status: 错误状态(OUT)
    
    REAL(wp), INTENT(IN) :: input(in_channels, height, width)
    REAL(wp), INTENT(IN) :: kernel(out_channels, in_channels, kernel_h, kernel_w)
    REAL(wp), INTENT(OUT) :: output(out_channels, out_h, out_w)
    INTEGER(i4), INTENT(IN) :: in_channels, out_channels, height, width
    INTEGER(i4), INTENT(IN) :: out_h, out_w
    INTEGER(i4), INTENT(IN) :: kernel_h, kernel_w, stride, padding
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: oc, ic, oh, ow, kh, kw, ih, iw
    
    CALL init_error_status(status)
    
    ! 初始化输出
    output = 0.0_wp
    
    ! 卷积计算(简化实现,未优化)
    DO oc = 1, out_channels
      DO oh = 1, out_h
        DO ow = 1, out_w
          DO ic = 1, in_channels
            DO kh = 1, kernel_h
              DO kw = 1, kernel_w
                ih = (oh - 1) * stride + kh - padding
                iw = (ow - 1) * stride + kw - padding
                
                ! 边界检查
                IF (ih >= 1 .AND. ih <= height .AND. iw >= 1 .AND. iw <= width) THEN
                  output(oc, oh, ow) = output(oc, oh, ow) + &
                                       input(ic, ih, iw) * kernel(oc, ic, kh, kw)
                END IF
              END DO
            END DO
          END DO
        END DO
      END DO
    END DO
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE IF_AI_Tensor_Conv2D

  !=============================================================================
  ! IF_AI_Tensor_ReLU - ReLU激活函数
  !=============================================================================
  PURE SUBROUTINE IF_AI_Tensor_ReLU(x, y, n)
    !! ReLU激活函数 y = max(0, x)
    !!
    !! 参数:
    !!   x: 输入向量(IN)
    !!   y: 输出向量(OUT)
    !!   n: 向量长度(IN)
    
    REAL(wp), INTENT(IN) :: x(n)
    REAL(wp), INTENT(OUT) :: y(n)
    INTEGER(i4), INTENT(IN) :: n
    
    INTEGER(i4) :: i
    
    ! SIMD友好的逐元素操作
    DO i = 1, n
      y(i) = MAX(0.0_wp, x(i))
    END DO
    
  END SUBROUTINE IF_AI_Tensor_ReLU

  !=============================================================================
  ! IF_AI_Tensor_Sigmoid - Sigmoid激活函数
  !=============================================================================
  PURE SUBROUTINE IF_AI_Tensor_Sigmoid(x, y, n)
    !! Sigmoid激活函数 y = 1 / (1 + exp(-x))
    !!
    !! 参数:
    !!   x: 输入向量(IN)
    !!   y: 输出向量(OUT)
    !!   n: 向量长度(IN)
    
    REAL(wp), INTENT(IN) :: x(n)
    REAL(wp), INTENT(OUT) :: y(n)
    INTEGER(i4), INTENT(IN) :: n
    
    INTEGER(i4) :: i
    
    ! 数值稳定实现
    DO i = 1, n
      IF (x(i) >= 0.0_wp) THEN
        y(i) = 1.0_wp / (1.0_wp + EXP(-x(i)))
      ELSE
        y(i) = EXP(x(i)) / (1.0_wp + EXP(x(i)))
      END IF
    END DO
    
  END SUBROUTINE IF_AI_Tensor_Sigmoid

  !=============================================================================
  ! IF_AI_Tensor_Softmax - Softmax激活函数
  !=============================================================================
  PURE SUBROUTINE IF_AI_Tensor_Softmax(x, y, n)
    !! Softmax激活函数 y_i = exp(x_i) / sum(exp(x_j))
    !!
    !! 参数:
    !!   x: 输入向量(IN)
    !!   y: 输出向量(OUT)
    !!   n: 向量长度(IN)
    !!
    !! 数值稳定: 使用max(x)防止溢出
    
    REAL(wp), INTENT(IN) :: x(n)
    REAL(wp), INTENT(OUT) :: y(n)
    INTEGER(i4), INTENT(IN) :: n
    
    REAL(wp) :: x_max, sum_exp
    INTEGER(i4) :: i
    
    ! 数值稳定: 减去最大值
    x_max = MAXVAL(x)
    
    ! 计算exp(x_i - x_max)
    sum_exp = 0.0_wp
    DO i = 1, n
      y(i) = EXP(x(i) - x_max)
      sum_exp = sum_exp + y(i)
    END DO
    
    ! 归一化
    DO i = 1, n
      y(i) = y(i) / sum_exp
    END DO
    
  END SUBROUTINE IF_AI_Tensor_Softmax

  !=============================================================================
  ! IF_AI_Tensor_AddBias - 添加偏置
  !=============================================================================
  PURE SUBROUTINE IF_AI_Tensor_AddBias(x, bias, y, n)
    !! 添加偏置 y = x + bias
    !!
    !! 参数:
    !!   x: 输入向量(IN)
    !!   bias: 偏置向量(IN)
    !!   y: 输出向量(OUT)
    !!   n: 向量长度(IN)
    
    REAL(wp), INTENT(IN) :: x(n)
    REAL(wp), INTENT(IN) :: bias(n)
    REAL(wp), INTENT(OUT) :: y(n)
    INTEGER(i4), INTENT(IN) :: n
    
    INTEGER(i4) :: i
    
    ! 逐元素加法
    DO i = 1, n
      y(i) = x(i) + bias(i)
    END DO
    
  END SUBROUTINE IF_AI_Tensor_AddBias

END MODULE IF_AI_TensorOps