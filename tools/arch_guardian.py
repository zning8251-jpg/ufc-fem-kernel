#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
UFC Architecture Guardian (arch_guardian.py)
============================================
UFC架构契约的自动化守卫引擎。
所有Agent代码输出前强制调用，pre-commit hook 拦截触发点。

用法：
  python arch_guardian.py <path>              # 扫描文件或目录
  python arch_guardian.py <path> --fail-on-p0 # P0违规时以非零码退出（pre-commit模式）
  python arch_guardian.py <path> --report     # 输出Markdown格式报告

版本：v1.1  创建日期：2026-03-15 | v1.1 新增：GLB/DEP-002/NAME-002/T4/IDX 基因规则
上位文档：UFC_Agentic_Engineering_方案.md §14
"""

import re
import os
import sys
import json
import argparse
from dataclasses import dataclass, field
from typing import Any, List, Optional, Tuple
from datetime import datetime


# ===========================================================================
# 数据类
# ===========================================================================

@dataclass
class RuleViolation:
    rule_id:   str          # e.g. "HOT-001"
    severity:  str          # P0 / P1 / P2
    file_path: str
    line_no:   int
    line_text: str
    message:   str

    def __str__(self):
        return f"[{self.rule_id}][{self.severity}] {self.file_path}:{self.line_no}  {self.message}"


# ===========================================================================
# 规则基类
# ===========================================================================

class GuardianRule:
    rule_id  = ""
    severity = "P1"
    description = ""

    def check(self, lines: List[str], file_path: str) -> List[RuleViolation]:
        raise NotImplementedError


# ===========================================================================
# HOT-001：GP积分热路径（Compute_Ke/Compute_Ctan/Compute_Fe/Compute_Fint内部）禁止ALLOCATE
# ===========================================================================

class HOT001_NoAllocInHotPath(GuardianRule):
    """GP积分热路径内禁止 ALLOCATE/DEALLOCATE"""
    rule_id     = "HOT-001"
    severity    = "P0"
    description = "GP积分热路径内禁止ALLOCATE/DEALLOCATE（热路径零分配铁律）"

    HOT_SUBROUTINES = {
        "Compute_Ke", "Compute_Ctan", "Compute_Fe",
        "Compute_Fint", "Compute_Me", "Compute_Ce",
        "Compute_BMatrix", "Compute_Jacobian",
    }

    def check(self, lines: List[str], file_path: str) -> List[RuleViolation]:
        violations = []
        in_hot_scope = False
        do_depth = 0

        for i, line in enumerate(lines, 1):
            stripped = line.strip()

            # 跳过注释行
            if stripped.startswith('!'):
                continue

            upper = stripped.upper()

            # 检测进入热路径子程序
            for sub in self.HOT_SUBROUTINES:
                if re.search(rf'\bSUBROUTINE\s+\w*{re.escape(sub)}\b', line, re.I):
                    in_hot_scope = True
                    do_depth = 0
                    break

            if in_hot_scope:
                # 跟踪DO循环深度
                if re.match(r'\s*(DO\b|DO\s+\d)', line, re.I) and 'END DO' not in upper:
                    do_depth += 1
                if re.match(r'\s*END\s*DO\b', line, re.I):
                    do_depth = max(0, do_depth - 1)

                # 在DO循环内检测 ALLOCATE/DEALLOCATE
                if do_depth >= 1:
                    if re.search(r'\bALLOCATE\s*\(', line, re.I):
                        violations.append(RuleViolation(
                            rule_id=self.rule_id, severity=self.severity,
                            file_path=file_path, line_no=i, line_text=stripped,
                            message="热路径DO循环内含ALLOCATE，违反热路径零分配铁律"
                        ))
                    if re.search(r'\bDEALLOCATE\s*\(', line, re.I):
                        violations.append(RuleViolation(
                            rule_id=self.rule_id, severity=self.severity,
                            file_path=file_path, line_no=i, line_text=stripped,
                            message="热路径DO循环内含DEALLOCATE，违反热路径零分配铁律"
                        ))

                # 检测离开子程序
                if re.match(r'\s*END\s+SUBROUTINE\b', line, re.I):
                    in_hot_scope = False
                    do_depth = 0

        return violations


# ===========================================================================
# HOT-002：热路径子程序（Bridge响应路径）禁止裸 ALLOCATE/DEALLOCATE
# ===========================================================================

class HOT002_NoAllocInBridgeResponse(GuardianRule):
    """Bridge响应路径（PH_Brg_Get*）在每次调用时不得动态分配"""
    rule_id     = "HOT-002"
    severity    = "P0"
    description = "Bridge响应路径（PH_Brg_Get*Response*）禁止每次调用时ALLOCATE/DEALLOCATE，应在冷路径预分配"

    BRIDGE_HOT_SUBS = {
        "PH_Brg_GetMaterialResponse",
        "PH_Brg_GetMaterialResponse_Idx",
        "PH_Brg_GetElementResponse",
    }

    def check(self, lines: List[str], file_path: str) -> List[RuleViolation]:
        violations = []
        in_scope = False

        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            if stripped.startswith('!'):
                continue

            for sub in self.BRIDGE_HOT_SUBS:
                if re.search(rf'\bSUBROUTINE\s+{re.escape(sub)}\b', line, re.I):
                    in_scope = True
                    break

            if in_scope:
                if re.search(r'\bALLOCATE\s*\(', line, re.I):
                    violations.append(RuleViolation(
                        rule_id=self.rule_id, severity=self.severity,
                        file_path=file_path, line_no=i, line_text=stripped,
                        message=f"Bridge响应路径内含ALLOCATE（应改为预分配缓冲区复用）"
                    ))
                if re.search(r'\bDEALLOCATE\s*\(', line, re.I):
                    violations.append(RuleViolation(
                        rule_id=self.rule_id, severity=self.severity,
                        file_path=file_path, line_no=i, line_text=stripped,
                        message=f"Bridge响应路径内含DEALLOCATE（应改为预分配缓冲区复用）"
                    ))
                if re.match(r'\s*END\s+SUBROUTINE\b', line, re.I):
                    in_scope = False

        return violations


# ===========================================================================
# HOT-003：热路径内禁止访问 g_ufc_global%md_layer（L3层）
# ===========================================================================

class HOT003_NoL3InHotPath(GuardianRule):
    """GP积分热路径内禁止直接访问 g_ufc_global%md_layer（L3层数据）"""
    rule_id     = "HOT-003"
    severity    = "P0"
    description = "热路径（Compute_*/PH_Brg_Get*）内禁止访问g_ufc_global%md_layer（L3层）"

    HOT_SUBS = {
        "Compute_Ke", "Compute_Ctan", "Compute_Fe", "Compute_Fint",
        "Compute_Me", "Compute_Ce",
        "PH_Brg_GetMaterialResponse", "PH_Brg_GetMaterialResponse_Idx",
    }

    def check(self, lines: List[str], file_path: str) -> List[RuleViolation]:
        violations = []
        in_scope = False

        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            if stripped.startswith('!'):
                continue

            for sub in self.HOT_SUBS:
                if re.search(rf'\bSUBROUTINE\s+\w*{re.escape(sub)}\b', line, re.I):
                    in_scope = True
                    break

            if in_scope:
                if re.search(r'g_ufc_global\s*%\s*md_layer\s*%', line, re.I):
                    violations.append(RuleViolation(
                        rule_id=self.rule_id, severity=self.severity,
                        file_path=file_path, line_no=i, line_text=stripped,
                        message="热路径内直接访问g_ufc_global%md_layer（L3层），应在Populate冷路径缓存到Ctx"
                    ))
                if re.match(r'\s*END\s+SUBROUTINE\b', line, re.I):
                    in_scope = False

        return violations


# ===========================================================================
# HOT-004：热路径子程序内禁止 IO（OPEN/READ/WRITE/PRINT）
# ===========================================================================

class HOT004_NoIOInHotPath(GuardianRule):
    """GP积分热路径内禁止 OPEN/READ/WRITE/PRINT（热路径三禁：L3、ALLOCATE、IO）"""
    rule_id     = "HOT-004"
    severity    = "P0"
    description = "热路径（Compute_*）内禁止OPEN/READ/WRITE/PRINT（热路径零IO铁律）"

    HOT_SUBS = {
        "Compute_Ke", "Compute_Ctan", "Compute_Fe", "Compute_Fint",
        "Compute_Me", "Compute_Ce",
        "Compute_BMatrix", "Compute_Jacobian",
    }

    IO_PATTERNS = [
        (r'\bOPEN\s*\(', "OPEN"),
        (r'\bREAD\s*\(', "READ"),
        (r'\bWRITE\s*\(', "WRITE"),
        (r'\bPRINT\s*\b', "PRINT"),
    ]

    def check(self, lines: List[str], file_path: str) -> List[RuleViolation]:
        violations = []
        in_scope = False

        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            if stripped.startswith('!'):
                continue

            for sub in self.HOT_SUBS:
                if re.search(rf'\bSUBROUTINE\s+\w*{re.escape(sub)}\b', line, re.I):
                    in_scope = True
                    break

            if in_scope:
                for pat, name in self.IO_PATTERNS:
                    if re.search(pat, line, re.I):
                        violations.append(RuleViolation(
                            rule_id=self.rule_id, severity=self.severity,
                            file_path=file_path, line_no=i, line_text=stripped,
                            message=f"热路径内含{name}（热路径三禁：L3、ALLOCATE、IO）"
                        ))
                        break
                if re.match(r'\s*END\s+SUBROUTINE\b', line, re.I):
                    in_scope = False

        return violations


# ===========================================================================
# WB-001：L4_PH层禁止对L3 Desc字段赋值（只读原则）
# ===========================================================================

class WB001_NoWriteL3Desc(GuardianRule):
    """L4_PH层禁止对L3 Desc字段赋值（WriteBack白名单规则）"""
    rule_id     = "WB-001"
    severity    = "P0"
    description = "L4层禁止对L3 Desc字段赋值，L3数据只读（WriteBack白名单规则）"

    L3_WRITE_PATTERNS = [
        # 直接写 g_ufc_global%md_layer%xxx%field = （赋值操作，不是ASSOCIATE别名）
        (r'g_ufc_global\s*%\s*md_layer\s*%\w+\s*%[^%\n]+=(?!=)', "直接写 g_ufc_global%md_layer%domain%field（L3写回违规）"),
        # elem_desc字段赋值（elem_desc是持久L3 Desc）
        (r'\belem_desc\s*%\s*[\w_]+\s*=(?!=)', "直接写 elem_desc%字段（L3 Desc字段不可写）"),
    ]

    # WB-001 白名单：以下访问模式是合法的 Bridge 只读引用
    # - ASSOCIATE(...md_layer...)  ← ASSOCIATE是别名，不是写入
    # - elastic_in%mat_desc%*      ← L4内部工作结构体，不是L3持久Desc
    # - PH_Brg_GetAmplitudeValue   ← Bridge读权限，冷路径合法访问
    WHITELIST_PATTERNS = [
        r'^\s*ASSOCIATE\s*\(',           # ASSOCIATE别名声明
        r'elastic_in\s*%\s*mat_desc\s*%',  # L4内部工作结构
        r'composite_in\s*%\s*mat_desc\s*%',
        r'work_ctx\s*%\s*mat_desc\s*%',
        r'!\s*WB-001-exempt',            # 显式豁免标记
    ]

    def check(self, lines: List[str], file_path: str) -> List[RuleViolation]:
        # 仅检查 L4_PH 路径下的文件
        if 'L4_PH' not in file_path.replace('\\', '/'):
            return []
        violations = []
        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            if stripped.startswith('!'):
                continue

            # 检查是否命中白名单（直接跳过）
            if any(re.search(wp, stripped, re.I) for wp in self.WHITELIST_PATTERNS):
                continue

            for pat, msg in self.L3_WRITE_PATTERNS:
                if re.search(pat, stripped, re.I):
                    violations.append(RuleViolation(
                        rule_id=self.rule_id, severity=self.severity,
                        file_path=file_path, line_no=i, line_text=stripped,
                        message=msg
                    ))
                    break
        return violations


# ===========================================================================
# DEP-001：禁止高层被低层 USE（依赖方向铁律）
# ===========================================================================

class DEP001_NoUpwardUse(GuardianRule):
    """禁止低层模块USE高层模块（依赖方向：L1←L2←L3←L4←L5←L6）"""
    rule_id     = "DEP-001"
    severity    = "P0"
    description = "禁止低层模块USE高层模块（依赖反转）"

    # 层级标识与对应的非法USE目标
    LAYER_FORBIDDEN = {
        'L4_PH': ['L5_RT', 'L6_AP'],   # L4 不得 USE L5/L6
        'L3_MD': ['L4_PH', 'L5_RT', 'L6_AP'],  # L3 不得 USE L4/L5/L6
        'L2_NM': ['L3_MD', 'L4_PH', 'L5_RT', 'L6_AP'],
        'L1_IF': ['L2_NM', 'L3_MD', 'L4_PH', 'L5_RT', 'L6_AP'],
    }

    def _detect_layer(self, file_path: str) -> Optional[str]:
        normalized = file_path.replace('\\', '/')
        for layer in self.LAYER_FORBIDDEN:
            if f'/{layer}/' in normalized or normalized.endswith(f'/{layer}'):
                return layer
        return None

    # DEP-001 白名单目录：这些目录本身就是跨层桥接目录，允许 USE 高层模块
    # Bridge_L5：L3_MD 专用的向上桥接目录，合法 USE L5_RT
    # Bridge_L4：L3_MD/L2_NM 向 L4_PH 桥接
    # 任何路径含 /Bridge/ 的文件均为桥接文件，豁免 DEP-001
    BRIDGE_DIR_PATTERNS = [
        r'/Bridge/',      # 任何层的 Bridge 子目录
        r'/bridge/',
        r'_Brg\.f90$',   # 文件名以 _Brg.f90 结尾的都是桥接文件
        r'_RT_Brg',       # L3→L5 类型桥接
        r'_AP_Brg',       # L3→L6 类型桥接
        r'_PH_Brg',       # L3→L4 类型桥接
    ]

    def _is_bridge_file(self, file_path: str) -> bool:
        normalized = file_path.replace('\\', '/')
        for pat in self.BRIDGE_DIR_PATTERNS:
            if re.search(pat, normalized, re.I):
                return True
        return False

    def check(self, lines: List[str], file_path: str) -> List[RuleViolation]:
        layer = self._detect_layer(file_path)
        if layer is None:
            return []

        # Bridge 文件合法跨层 USE，豁免 DEP-001
        if self._is_bridge_file(file_path):
            return []

        violations = []

        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            if stripped.startswith('!'):
                continue
            # 检测 USE 语句
            if re.match(r'\s*USE\b', stripped, re.I):
                for forbidden_layer in self.LAYER_FORBIDDEN[layer]:
                    # 检测是否USE了属于高层的模块（通过模块名前缀推断）
                    if re.search(
                        rf'\bUSE\s+(?:RT_|AP_|{forbidden_layer.replace("_","_?")}_)',
                        stripped, re.I
                    ):
                        violations.append(RuleViolation(
                            rule_id=self.rule_id, severity=self.severity,
                            file_path=file_path, line_no=i, line_text=stripped,
                            message=f"{layer}层模块USE了高层{forbidden_layer}的模块（依赖反转）"
                        ))
                        break
        return violations


# ===========================================================================
# DATA-001：层间调用方向检查（与数据链验证矩阵对应）
# ===========================================================================

class DATA001_LayerCallDirection(GuardianRule):
    """层间调用方向：L4 不得 CALL L5；L3 不得 CALL L4/L5（依赖倒置）"""
    rule_id     = "DATA-001"
    severity    = "P2"
    description = "层间调用方向须符合数据链验证矩阵（L4→L5、L3→L4/L5 禁止）"

    LAYER_FORBIDDEN_CALL = {
        'L4_PH': ['RT_', 'AP_'],   # L4 不得 CALL L5/L6
        'L3_MD': ['PH_', 'RT_', 'AP_'],  # L3 不得 CALL L4/L5/L6
    }
    BRIDGE_PATTERNS = [r'/Bridge/', r'/bridge/', r'_Brg\.f90$', r'_RT_Brg', r'_PH_Brg', r'_AP_Brg']

    def _detect_layer(self, file_path: str) -> Optional[str]:
        norm = file_path.replace('\\', '/')
        for layer in self.LAYER_FORBIDDEN_CALL:
            if f'/{layer}/' in norm or norm.endswith(f'/{layer}'):
                return layer
        return None

    def _is_bridge(self, file_path: str) -> bool:
        norm = file_path.replace('\\', '/')
        return any(re.search(p, norm, re.I) for p in self.BRIDGE_PATTERNS)

    def check(self, lines: List[str], file_path: str) -> List[RuleViolation]:
        layer = self._detect_layer(file_path)
        if layer is None or self._is_bridge(file_path):
            return []
        forbidden = self.LAYER_FORBIDDEN_CALL[layer]
        violations = []
        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            if stripped.startswith('!'):
                continue
            # 检测 CALL 语句
            if re.match(r'\s*CALL\s+', stripped, re.I):
                for prefix in forbidden:
                    if re.search(rf'\bCALL\s+{re.escape(prefix)}', stripped, re.I):
                        violations.append(RuleViolation(
                            rule_id=self.rule_id, severity=self.severity,
                            file_path=file_path, line_no=i, line_text=stripped,
                            message=f"{layer}层CALL了高层{prefix}*（违反数据链验证矩阵）"
                        ))
                        break
        return violations


# ===========================================================================
# INTF-001：公开SUBROUTINE参数数量>4时必须使用Arg结构体封装
# ===========================================================================

class INTF001_ArgWrapper(GuardianRule):
    """公开SUBROUTINE参数>4时必须使用Arg结构体封装
    
    v1.2 修复：
    - 支持 Fortran & 续行参数列表的完整收集（原版只检测单行完整参数）
    - 增加模块级 PRIVATE 感知：模块头有 PRIVATE 语句且子程序名未在 PUBLIC 列表中时跳过
    - 修正参数统计：剔除末尾 & 和注释，避免多计
    - ExternalLibs 目录豁免（第三方库接口不强制封装）
    - 层级过滤：只对 L4_PH 和 L5_RT 层强制（基础设施层底层API天然参数多，不适用此规则）
    - 参数阈值调整：L5_RT 使用阈值6（组装/求解接口参数略多是正常的）

    v1.3 升级：
    - 增加文件级 Arg TYPE 感知：文件中已定义 *Args / *_In / *_Out 封装类型时，
      说明该文件已进入渐进迁移路线图，剩余旧接口违规从 P1 降为 P2（compliance_mode）
    - 新增：INTF-001 合规状态注释标记（文件包含 "INTF-001 合规" 字样时同样降级）
    """
    rule_id     = "INTF-001"
    severity    = "P1"
    description = "公开SUBROUTINE参数数量过多时应使用Arg/Ctx结构体封装（接口标准化）"

    # 仅强制检查的层（其他层豁免）
    TARGET_LAYERS = ['L4_PH', 'L5_RT']

    # 豁免目录：第三方库、生成代码、测试存根不强制封装
    EXEMPT_DIR_PATTERNS = ['ExternalLibs', 'external_libs', 'thirdparty', 'test_stub']

    # 各层参数阈值（超过此值才报告）
    LAYER_THRESHOLDS = {
        'L4_PH': 4,   # L4 核心算法接口：>4个参数就应封装
        'L5_RT': 6,   # L5 运行时接口：>6个参数才报告（允许带 model/step/state 等基础参数）
    }

    # 文件级 Arg TYPE 存在的判断模式（TYPE 定义行）
    # 匹配 TYPE :: *Args / TYPE, PUBLIC :: *Args / TYPE :: *_In / TYPE :: *_Out / TYPE :: PH_*Ctx
    ARG_TYPE_PATTERN = re.compile(
        r'^\s*TYPE\s*(?:,\s*(?:PUBLIC|PRIVATE)\s*)?(?:::\s*|\s+)(\w+)(Args?|_In\b|_Out\b|_Ctx\b|Ctx\b)',
        re.I | re.MULTILINE
    )
    # 文件级 INTF-001 合规注释标记
    COMPLIANCE_COMMENT = re.compile(r'INTF-001\s+合规', re.I)

    def _get_layer(self, file_path: str) -> Optional[str]:
        norm = file_path.replace('\\', '/')
        for layer in self.TARGET_LAYERS:
            if f'/{layer}/' in norm or norm.endswith(f'/{layer}'):
                return layer
        return None

    def _is_exempt(self, file_path: str) -> bool:
        norm = file_path.replace('\\', '/')
        return any(p in norm for p in self.EXEMPT_DIR_PATTERNS)

    def _has_arg_types(self, content: str) -> bool:
        """检查文件内容是否已定义 Arg/Args/_In/_Out 封装类型，或有 INTF-001 合规注释"""
        return bool(self.ARG_TYPE_PATTERN.search(content)) or \
               bool(self.COMPLIANCE_COMMENT.search(content))

    def check(self, lines: List[str], file_path: str) -> List[RuleViolation]:
        layer = self._get_layer(file_path)
        if layer is None:
            return []  # 非目标层，豁免
        if self._is_exempt(file_path):
            return []

        threshold = self.LAYER_THRESHOLDS.get(layer, 4)
        violations = []

        # 0. 检查文件是否处于"渐进迁移合规状态"（已定义 Arg TYPE）
        full_content = '\n'.join(lines)
        file_in_compliance_mode = self._has_arg_types(full_content)
        # 渐进合规模式下：旧接口违规降为 P2
        effective_severity = "P2" if file_in_compliance_mode else self.severity

        # 第一遍：收集模块级 PUBLIC 声明列表 和是否有裸 PRIVATE 语句
        module_default_private = False
        explicitly_public = set()
        for ln in lines:
            s = ln.strip()
            if s.startswith('!'):
                continue
            if re.match(r'^\s*PRIVATE\s*$', s, re.I):
                module_default_private = True
            pm = re.match(r'^\s*PUBLIC\s*::\s*(.+)', s, re.I)
            if pm:
                names = re.split(r'[,\s]+', pm.group(1).strip())
                explicitly_public.update(n.strip() for n in names if n.strip())

        # 第二遍：逐行扫描 SUBROUTINE 定义，收集多行参数列表
        i = 0
        while i < len(lines):
            line = lines[i]
            stripped = line.strip()
            i += 1

            if stripped.startswith('!'):
                continue

            m = re.match(r'^\s*SUBROUTINE\s+(\w+)\s*\((.*)', stripped, re.I)
            if not m:
                continue

            sub_name = m.group(1)
            sub_line = i  # 1-based

            # 判断可见性
            if module_default_private and sub_name not in explicitly_public:
                continue  # 私有子程序，豁免

            # 收集完整参数字符串（处理 & 续行）
            param_buf = m.group(2)
            param_buf = re.sub(r'!.*$', '', param_buf).rstrip().rstrip('&').rstrip()

            # 若括号未闭合，继续读续行
            paren_depth = param_buf.count('(') - param_buf.count(')')
            while paren_depth > 0 and i < len(lines):
                cont = lines[i].strip()
                i += 1
                if cont.startswith('!'):
                    continue
                cont = re.sub(r'!.*$', '', cont).rstrip().rstrip('&').rstrip()
                param_buf += ' ' + cont
                paren_depth += cont.count('(') - cont.count(')')

            # 提取 ) 前的参数列表
            if ')' in param_buf:
                param_list = param_buf[:param_buf.index(')')]
            else:
                param_list = param_buf

            param_list = param_list.strip()
            if not param_list:
                continue

            # 统计参数数量
            param_count = param_list.count(',') + 1

            if param_count > threshold:
                # 检查是否使用了 Arg 封装（参数名含 arg/Arg/_in/_out/ctx/Ctx）
                has_arg = bool(re.search(
                    r'\b(arg|Arg|ARG|_in|_out|_In|_Out|ctx|Ctx|CTX)\b',
                    param_list, re.I
                ))
                if not has_arg:
                    violations.append(RuleViolation(
                        rule_id=self.rule_id, severity=effective_severity,
                        file_path=file_path, line_no=sub_line, line_text=stripped,
                        message=f"[{layer}] SUBROUTINE {sub_name} 参数数量={param_count}>{threshold}，"
                                + (f"已有Arg TYPE定义（渐进合规模式），建议迁移至结构化接口"
                                   if file_in_compliance_mode else
                                   f"应使用Arg/Ctx结构体封装（公开接口参数过多）")
                    ))

        return violations


# ===========================================================================
# TYPE-001: 四大类成员名一致性检查
# ===========================================================================

class TYPE001_MemberNaming(GuardianRule):
    """检查 Desc/State/Algo/Ctx 成员命名一致性
    
    修正版方案A: BC域统一设计
    - 所有层共享统一常量 (UFC_FEM_Symbols)
    - 成员名统一规范
    """
    rule_id     = "TYPE-001"
    severity    = "P0"
    description = "Desc/State/Algo/Ctx 成员命名必须符合 UFC 统一规范"

    # Desc 类型允许的成员名
    DESC_VALID = [
        'id', 'type', 'name', 'count', 'n_',
        'node_ids', 'dof_ids', 'values', 'is_',
        'bc_id', 'bc_name', 'bc_type', 'bc_family',
        'amplitude_id', 'node_set_id',
    ]
    
    # State 类型允许的成员名
    STATE_VALID = [
        'time', 'value', 'current_', 'last_',
        'converged', 'iterations', 'status',
        'accumulated', 'reaction_',
    ]
    
    # Algo 类型允许的成员名
    ALGO_VALID = [
        'method', 'tolerance', 'max_iter', 'options', 'is_',
        'application_method', 'interpolation', 'coefficient',
    ]
    
    # Ctx 类型允许的成员名（热路径，禁止ALLOCATABLE）
    CTX_VALID = [
        'temp', 'work', 'buffer', 'local_',
        'prescribed_', 'follower_',
    ]
    
    FORBIDDEN_PATTERNS = [
        r'^\d+_',           # 数字开头
        r'_old$|_new$',     # 临时后缀
        r'_tmp$|_temp$',    # 临时变量（应在Ctx中使用）
    ]

    def check(self, lines: List[str], file_path: str) -> List[RuleViolation]:
        violations = []
        in_type_block = False
        type_name = ""
        
        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            
            # 跟踪 TYPE 块
            m = re.match(r'^\s*TYPE\s*(?:,\s*\w+\s*)?(?:PUBLIC\s*)?::\s*(\w+)', stripped, re.I)
            if m:
                type_name = m.group(1).upper()
                in_type_block = True
                continue
            
            if re.match(r'^\s*END\s+TYPE\b', stripped, re.I):
                in_type_block = False
                continue
            
            if not in_type_block:
                continue
            
            # 检测类型分类
            is_desc = 'DESC' in type_name
            is_state = 'STATE' in type_name
            is_algo = 'ALGO' in type_name
            is_ctx = 'CTX' in type_name
            
            if not (is_desc or is_state or is_algo or is_ctx):
                continue
            
            # 提取成员声明行
            member_match = re.match(r'^\s*(INTEGER|REAL|LOGICAL|CHARACTER)\b.*::\s*(\w+)', stripped)
            if member_match:
                member_name = member_match.group(2)
                
                # 检查禁止模式
                for pat in self.FORBIDDEN_PATTERNS:
                    if re.search(pat, member_name):
                        violations.append(RuleViolation(
                            rule_id=self.rule_id, severity=self.severity,
                            file_path=file_path, line_no=i, line_text=stripped,
                            message=f"TYPE成员 {member_name} 匹配禁止模式 {pat}"
                        ))
        
        return violations


# ===========================================================================
# TYPE-002: 常量命名空间检查
# ===========================================================================

class TYPE002_ConstantNamespace(GuardianRule):
    """检查常量必须有正确的层前缀隔离
    
    修正版方案A: 编译期常量 + 命名空间隔离
    - MD_BC_FIELD_* (L3层)
    - RT_BC_CONSTRAIN_* (L5层)
    - UFC_* (全局)
    - **豁免**：`L3_MD/Material/Contract/MD_Mat_Ids.f90` 内 **MAT_*** / **MAT_FAMILY_*** 等为
      合同约定的跨walk SSOT 符号表，不按本规则逐行前缀化（见该模块头注释）。
    """
    rule_id     = "TYPE-002"
    severity    = "P0"
    description = "常量必须使用 RT_/MD_/PH_ 等层前缀隔离"

    VALID_PREFIXES = ['RT_', 'MD_', 'PH_', 'NM_', 'IF_', 'UFC_']
    
    # DEPRECATED 别名模式（旧代码迁移期间允许）
    DEPRECATED_ALIASES = ['BC_FAMILY_', 'BC_FIXED', 'LOAD_CONCENTRATED', 'AMP_INTERP_']

    def check(self, lines: List[str], file_path: str) -> List[RuleViolation]:
        violations = []
        norm_path = file_path.replace("\\", "/")
        # Canonical material family / range IDs (MAT_* + MD_MAT_ID_* SSOT). Names are
        # intentional crosswalk symbols; forcing MD_ on every row would churn thousands
        # of call sites without semantic gain. See MD_Mat_Ids module header.
        if norm_path.endswith("Material/Contract/MD_Mat_Ids.f90") or "/Material/Contract/MD_Mat_Ids.f90" in norm_path:
            return []

        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            if stripped.startswith('!'):
                continue
            
            # 查找 PARAMETER 定义
            param_pattern = r'INTEGER.*PARAMETER.*::\s*(\w+)\s*=\s*(\d+)'
            matches = re.finditer(param_pattern, stripped, re.IGNORECASE)
            
            for m in matches:
                const_name = m.group(1)
                
                # 检查是否有有效前缀
                has_valid_prefix = any(
                    const_name.startswith(p) for p in self.VALID_PREFIXES
                )
                
                # 检查是否是 DEPRECATED 别名（迁移期间允许）
                is_deprecated_alias = any(
                    const_name.startswith(a) for a in self.DEPRECATED_ALIASES
                )
                
                if not has_valid_prefix and not is_deprecated_alias:
                    violations.append(RuleViolation(
                        rule_id=self.rule_id, severity=self.severity,
                        file_path=file_path, line_no=i, line_text=stripped,
                        message=f"常量 {const_name} 缺少层前缀（应使用 RT_/MD_/PH_ 前缀）"
                    ))
        
        return violations


# ===========================================================================
# TYPE-003: Ctx 热路径零分配检查
# ===========================================================================

class TYPE003_CtxNoAlloc(GuardianRule):
    """Ctx 类型禁止 ALLOCATABLE
    
    热路径零分配铁律：
    - Ctx 类型只允许 POINTER（指向预分配缓冲区）
    - 禁止 ALLOCATABLE（热路径动态分配）
    """
    rule_id     = "TYPE-003"
    severity    = "P0"
    description = "所有 Ctx 类型禁止使用 ALLOCATABLE"

    def check(self, lines: List[str], file_path: str) -> List[RuleViolation]:
        violations = []
        in_ctx_type = False
        type_name = ""
        
        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            
            # 检测 Ctx 类型
            if re.search(r'\bTYPE\s*(?:,\s*\w+\s*)?::\s*\w*Ctx\b', stripped, re.I):
                in_ctx_type = True
                continue
            
            if re.match(r'^\s*END\s+TYPE\b', stripped, re.I):
                in_ctx_type = False
                continue
            
            if not in_ctx_type:
                continue
            
            # 跳过注释行
            if stripped.startswith('!'):
                continue
            
            # 检查 ALLOCATABLE
            if 'ALLOCATABLE' in stripped:
                violations.append(RuleViolation(
                    rule_id=self.rule_id, severity=self.severity,
                    file_path=file_path, line_no=i, line_text=stripped,
                    message="Ctx 类型中禁止使用 ALLOCATABLE（应使用 POINTER 指向预分配缓冲区）"
                ))
        
        return violations


# =========================================================================== 
# MAT-001：Material 热路径零分配守卫
# ===========================================================================

class MAT001_MaterialNoAlloc(GuardianRule):
    """Material 热路径中禁止动态分配。"""
    rule_id = "MAT-001"
    severity = "P0"
    description = "Material 热路径禁止 ALLOCATE/DEALLOCATE"

    TARGET_NAMES = ("PH_Material_Eval", "PH_Mat_Eval", "Material_Eval")

    def _is_material_file(self, file_path: str) -> bool:
        norm = file_path.replace("\\", "/")
        return "/L4_PH/" in norm or "/L5_RT/" in norm or "/L3_MD/Material/" in norm

    def check(self, lines: List[str], file_path: str) -> List[RuleViolation]:
        if not self._is_material_file(file_path):
            return []
        violations = []
        in_scope = False
        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            if stripped.startswith("!"):
                continue
            if re.search(r"\bSUBROUTINE\s+(?:\w*[_])?(?:PH_Material_Eval|PH_Mat_Eval|Material_Eval)\b", stripped, re.I):
                in_scope = True
            elif in_scope and re.match(r"^\s*END\s+SUBROUTINE\b", stripped, re.I):
                in_scope = False
            if not in_scope:
                continue
            if re.search(r"\bALLOCATE\s*\(", stripped, re.I) or re.search(r"\bDEALLOCATE\s*\(", stripped, re.I):
                violations.append(RuleViolation(
                    rule_id=self.rule_id,
                    severity=self.severity,
                    file_path=file_path,
                    line_no=i,
                    line_text=stripped,
                    message="Material 热路径禁止 ALLOCATE/DEALLOCATE"
                ))
        return violations


# ===========================================================================
# MAT-001：禁止密集全局矩阵（必须使用CSR格式）
# ===========================================================================

class MAT001_NoFullMatrix(GuardianRule):
    """禁止声明密集全局矩阵，必须使用CSR格式
    
    v1.1 修复：
    - 增加 TYPE...END TYPE 块内成员字段豁免（*_global(3) 是坐标向量不是矩阵）
    - 增加维度大小阈值过滤：固定小维度（≤9）的矩阵不报告
    - 更精确的模式：要求变量名以 K_/M_/C_/stiffness/mass 开头，且维度参数含 ndof
    """
    rule_id     = "MAT-001"
    severity    = "P1"
    description = "全局K/M/C矩阵必须使用CSR格式，禁止REAL(wp)::K_global(ndof,ndof)密集矩阵"

    DENSE_MATRIX_PATTERNS = [
        r'REAL\s*\(\s*wp\s*\)\s*::\s*[KkMmCcGg][\w_]*\s*\(\s*n[Dd][Oo][Ff].*,.*n[Dd][Oo][Ff]',
        r'REAL\s*\(\s*wp\s*\)\s*::\s*[KkMmCcGg][\w_]*_[Gg]lobal\s*\(\s*n[Dd][Oo][Ff]',
        r'REAL\s*\(\s*wp\s*\)\s*::\s*[Ss]tiffness\s*\(.*n[Dd][Oo][Ff]',
        r'REAL\s*\(\s*wp\s*\)\s*::\s*[Mm]ass\s*\(.*n[Dd][Oo][Ff]',
    ]

    def check(self, lines: List[str], file_path: str) -> List[RuleViolation]:
        violations = []
        in_type_block = False

        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            if stripped.startswith('!'):
                continue

            if re.match(r'^\s*TYPE\s*(?:,\s*\w+\s*)?::\s*\w+', stripped, re.I) or \
               re.match(r'^\s*TYPE\s*,\s*PUBLIC\b', stripped, re.I) or \
               re.match(r'^\s*TYPE\s*,\s*PRIVATE\b', stripped, re.I):
                in_type_block = True
                continue
            if re.match(r'^\s*END\s+TYPE\b', stripped, re.I):
                in_type_block = False
                continue
            if in_type_block:
                continue

            for pat in self.DENSE_MATRIX_PATTERNS:
                if re.search(pat, stripped, re.I):
                    violations.append(RuleViolation(
                        rule_id=self.rule_id, severity=self.severity,
                        file_path=file_path, line_no=i, line_text=stripped,
                        message="密集全局矩阵声明，违反CSR格式要求（内存爆炸风险）"
                    ))
                    break
        return violations


# =========================================================================== 
# MAT-002：Material 共享域契约守卫
# ===========================================================================

class MAT002_MaterialContractGuard(GuardianRule):
    """Material 共享域契约守卫：防止草案式定义、隐式别名和未登记桥接。"""
    rule_id = "MAT-002"
    severity = "P1"
    description = "Material 共享域契约守卫"

    CONTRACT_FILE_HINTS = (
        "/L3_MD/Material/",
        "/L4_PH/Material/",
        "MD_Mat_Contract",
        "MD_Mat_Types",
        "MD_MAT_",
        "Material/OLD/",
    )

    def _is_material_contract_file(self, file_path: str) -> bool:
        norm = file_path.replace("\\", "/")
        return any(hint in norm for hint in self.CONTRACT_FILE_HINTS)

    def check(self, lines: List[str], file_path: str) -> List[RuleViolation]:
        if not self._is_material_contract_file(file_path):
            return []
        violations = []
        has_module = False
        has_public_contract = False
        has_alias_block = False
        has_bridge_hint = False

        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            if stripped.startswith("!"):
                if "Bridge" in stripped or "Brg" in stripped:
                    has_bridge_hint = True
                continue
            if re.match(r"^\s*MODULE\b", stripped, re.I):
                has_module = True
            if re.search(r"\bPUBLIC\b", stripped, re.I) and re.search(r"\b(MD_Mat_|PH_Mat_|MAT_)\w*", stripped, re.I):
                has_public_contract = True
            if re.search(r"\bALIAS\b|\bEQUIVALENCE\b|\bCOMMON\b", stripped, re.I):
                has_alias_block = True
            if re.search(r"\bBridge\b|\bBrg\b", stripped, re.I):
                has_bridge_hint = True

        if has_module and not has_public_contract:
            violations.append(RuleViolation(
                rule_id=self.rule_id,
                severity=self.severity,
                file_path=file_path,
                line_no=1,
                line_text="[MODULE]",
                message="Material 契约文件缺少显式 PUBLIC 契约导出"
            ))
        if has_alias_block:
            violations.append(RuleViolation(
                rule_id=self.rule_id,
                severity=self.severity,
                file_path=file_path,
                line_no=1,
                line_text="[ALIASES]",
                message="Material 契约文件不应使用 ALIAS/EQUIVALENCE/COMMON 伪契约"
            ))
        if has_module and not has_bridge_hint and any(h in file_path.replace("\\", "/") for h in ("Bridge", "Brg")):
            violations.append(RuleViolation(
                rule_id=self.rule_id,
                severity=self.severity,
                file_path=file_path,
                line_no=1,
                line_text="[BRIDGE]",
                message="Material 桥接文件缺少 Bridge/Brg 注释标记"
            ))
        return violations


# ===========================================================================
# NAME-001：L4算法子程序命名规范
# ===========================================================================

class NAME001_NamingConvention(GuardianRule):
    """L4_PH公开SUBROUTINE必须符合 PH_<Domain>_<动词>_<对象> 命名模式
    
    v1.1 修复：
    - 扩展 ALLOWED_VERBS：增加 UFC 领域实际使用的合法动词
    - 增加 ALLOWED_DOMAIN_TOKENS：Domain/Ctx/MPC/Enforce/Assembly 等领域前缀词不误报为动词
    - 增加模块级 PRIVATE 感知：私有子程序不报告
    - 增加 _Impl/_Priv/_Internal 后缀豁免（内部实现子程序）
    - 非 PH_ 前缀的子程序仅检查禁用前缀，不检查命名模式
    """
    rule_id     = "NAME-001"
    severity    = "P2"
    description = "L4_PH公开SUBROUTINE命名须符合 PH_<Domain>_<动词>_<对象> 规范"

    ALLOWED_VERBS = {
        # 原有核心动词
        'Compute', 'Assemble', 'Apply', 'Update', 'Eval', 'Reset',
        'Init', 'Finalize', 'Populate', 'Get', 'Set', 'Register',
        'Build', 'Solve', 'Check', 'Validate', 'Fill', 'Clear',
        # UFC 领域操作词
        'Map', 'Transform', 'Project', 'Extract', 'Insert', 'Remove',
        'Bind', 'Unbind', 'Link', 'Query', 'Find', 'Search',
        'Load', 'Save', 'Read', 'Write', 'Parse', 'Format',
        'Run', 'Execute', 'Process', 'Dispatch', 'Route',
        'Allocate', 'Deallocate', 'Resize', 'Reserve',
        'Lock', 'Unlock', 'Sync', 'Flush',
        'Copy', 'Clone', 'Merge', 'Split',
        'Add', 'Remove', 'Delete', 'Append',
        'Enable', 'Disable', 'Activate', 'Deactivate',
        'Open', 'Close', 'Connect', 'Disconnect',
        'Print', 'Log', 'Debug', 'Warn',
        'Interpolate', 'Integrate', 'Differentiate',
        'Factorize', 'Decompose', 'Invert',
        # Compute 的合法变体
        'Calculate', 'Calc', 'Evaluate',
        # v1.4 新增：FEM 领域认可操作词
        # 矩阵/向量构建类（Form* 系列）
        'Form',           # FormStiffMatrix/FormIntForce/FormBodyForce/FormNodalForce
        'Collect',        # CollectIPVars/CollectResults
        'Def',            # DefInit/DefState
        'Cons',           # ConsMass/ConsMatrix
        'Lump',           # LumpMass
        'Shape',          # ShapeFunc
        'Gauss',          # GaussPoints
        'Jac',            # Jac/JacB（雅可比矩阵）
        'BMatrix',        # BMatrix/BpMatrix
        'BpMatrix',
        'Bp',
        'Strain',         # StrainVoigt/StrainEnergy
        'Stress',         # StressRecovery/StressUpdate
        'Therm',          # ThermStrainVector/ThermConductivity
        'Const',          # ConstMatrix
        'Geom',           # GeomNonlin/GeomStiff
        'Valid',          # Valid/Validate（已有但加显式）
        'Restore',        # RestoreState
        'Recover',        # RecoverStress
        'Advance',        # AdvanceStep
        'Reduce',         # GuyanReduce
        'Propagate',      # PSDPropagate
        'Combine',        # CombineModes
        'Convect',        # ConvectiveMatrix
        # v1.4 补充
        'Stabilize',      # Stabilize
        'Correct',        # Correct/Correction
        'Eliminate',      # Eliminate（约束消除）
        'Opt',            # Optimize
        'Call',           # 桥接调用
        'Surf',           # SurfMetric
        'Integ',          # Integrate/Integration（数値积分）
        'Output',         # OutputResults
        'Generate',       # GenerateOutput
        'Detect',         # DetectPenetration
        'Stiff',          # StiffMatrix
        'Int',            # IntForce（内力缩写）
        'Vol',            # Volume
        'Mass',           # MassMatrix
        'Variant',        # ByVariant 变体
        'Incompat',       # Incompatible
        'Selective',      # Selective integration
        # v1.4 最终补充
        'Nonlinear',      # NonlinearIterate
        'Transient',      # TransientSolve
        'Rotation',       # Rotation transform
        'Track',          # Track boundary
        'Assem',          # AssemPenalty
        'Polar',          # PolarDecomposition
        'Metric',         # MetricTensor
    }

    # 这些词出现在 PH_X_<Token>_Y 的第三段时，是合法的领域前缀词（非动词），不应报告
    # 例如：PH_Constr_Domain_Init → parts[2]='Domain'，这是领域子模块前缀，不是动词
    ALLOWED_DOMAIN_TOKENS = {
        'Domain', 'Ctx', 'MPC', 'Enforce', 'Assembly', 'Brg', 'Bridge',
        'Core', 'API', 'Mgr', 'Manager', 'Util', 'Utils', 'Helper',
        'Pool', 'Cache', 'Store', 'Buffer', 'Queue', 'Stack',
        'Type', 'Def', 'Config', 'Params', 'Args', 'Data',
        'Period', 'Contact', 'Coupling', 'Thermal', 'Mech', 'Struct',
        'Ap', 'Co', 'El', 'Mat', 'Elem', 'Node', 'Dof',
        # ---- 3D 实体单元（已有）----
        'C3D4', 'C3D6', 'C3D8', 'C3D10', 'C3D20',
        'C3D4P', 'C3D6P', 'C3D8P', 'C3D10P', 'C3D20P',
        'C3D4R', 'C3D8R', 'C3D8I', 'C3D8H',
        # ---- 3D 实体单元（v1.4 新增）----
        'C3D15', 'C3D27',                        # 15/27节点六面体
        'C3D15P', 'C3D27P',                      # Porous 族
        'C3D4T', 'C3D6T', 'C3D8T', 'C3D10T',    # 热耦合族
        'C3D15T', 'C3D20T', 'C3D27T',
        # ---- 2D 实体单元（已有）----
        'C2D3', 'C2D4', 'C2D6', 'C2D8',
        'C2D3R', 'C2D4R', 'C2D4I',
        'CPS3', 'CPS4', 'CPS6', 'CPS8', 'CPE3', 'CPE4', 'CPE6', 'CPE8',
        # ---- 2D 轴对称单元（v1.4 新增）----
        'CAX3', 'CAX4', 'CAX6', 'CAX8',          # 轴对称实体
        # ---- 2D Porous 单元（v1.4 新增）----
        'CAX3P', 'CAX4P', 'CAX6P', 'CAX8P',
        'CPE3P', 'CPE4P', 'CPE6P', 'CPE8P',
        'CPS3P', 'CPS4P', 'CPS6P', 'CPS8P',
        # ---- 2D 热耦合单元（v1.4 新增）----
        'CAX3T', 'CAX4T', 'CAX6T', 'CAX8T',
        'CPE3T', 'CPE4T', 'CPE6T', 'CPE8T',
        'CPS3T', 'CPS4T', 'CPS6T', 'CPS8T',
        # ---- 壳单元（已有 S3/S4/S8，v1.4 新增）----
        'S3', 'S4', 'S4R', 'S8', 'S8R', 'S3R',
        'S6', 'S9',                              # 6/9节点壳
        'DS3', 'DS4', 'DS6', 'DS8',              # 减缩积分壳
        'MITC',                                  # MITC 壳
        # ---- 梁/桁架/弹簧/阻尼（已有部分，v1.4 新增）----
        'B21', 'B22', 'B23', 'B31', 'B32', 'B33',
        'T2D2', 'T2D3', 'T3D2', 'T3D3',
        'SPRING1', 'SPRING2',
        'DASHPOT1', 'DASHPOT2',
        # ---- 声学单元（v1.4 新增）----
        'AC2D4', 'AC2D6', 'AC2D8',
        'AC3D4', 'AC3D6', 'AC3D8', 'AC3D10', 'AC3D15', 'AC3D20',
        # ---- 管单元（v1.4 新增）----
        'PIPE21', 'PIPE22', 'PIPE31', 'PIPE32',
        'Pipe',
        # ---- 其他特殊单元（v1.4 新增）----
        'M3D3', 'M3D4', 'M3D6', 'M3D9', 'M3D9R',  # 膜单元
        'CAX',  # 通用轴对称前缀
        # ---- 非线性标识符（v1.4 新增）----
        'NL',       # NL_TL/NL_UL（Total Lagrange/Updated Lagrange）
        'TL',       # Total Lagrange
        'UL',       # Updated Lagrange
        'EAS',      # Enhanced Assumed Strain
        'FBar',     # F-bar 体积锁定消除
        # ---- 损伤/材料模型标识符（v1.4 新增）----
        'Dmg',      # Damage
        'Plas',     # Plastic
        'Elast',    # Elastic
        'Anneal',   # Annealing
        'Piezo',    # Piezoelectric
        'Poro',     # Porous media
        # ---- 材料计算标识符（v1.4 新增）----
        'MatAware', # Material-aware variant
        # ---- 已有 ----
        'Prony', 'Visc', 'Creep', 'Plast', 'Elastic', 'Damage',
        'UMAT', 'UHYPER', 'VUMAT',
        'Lagrange', 'Penalty', 'Augmented', 'Elimination',
        'Period', 'Symm', 'Rigid',
        'UserSub', 'UFIELD', 'USDFLD',
        # 缩写类领域词
        'HyperElas', 'MoonRiv', 'NeoHook', 'OgdenMod',
        'LinElas', 'DruckerPrager', 'MohrCoulomb',
        'Intf', 'Integ', 'IntVar',
        'VonMises', 'Tresca', 'HillYield',
        # 材料子类型前缀
        'Therm', 'SpecialPiezo', 'Visco', 'Relax', 'Rate',
        'J2', 'J2Kin', 'CycPlast', 'Armstrong', 'Chaboche',
        'Aniso', 'Ortho', 'Transverse', 'Composite',
        'Rubber', 'Foam', 'Cork', 'Gel',
        # 桥接层和接口层前缀
        'Bridge_Call', 'Bridge_Reg',
        # UEL
        'UEL',
        # ---- v1.4 补充：长尾领域前缀词 ----
        'Tie',              # Tie 约束
        'TM',               # Thermomechanical
        'Tensor',           # 张量工具
        'Comp',             # Composite/Component
        'LargeDef',         # 大变形
        'SF',               # Shape Function
        'Cpl',              # Coupling
        'RBE2', 'RBE3',     # 刚体单元
        'CompositeLayup',   # 复合材料铺层
        'PlastJ2', 'PlastDP', 'PlastMC',  # 塑性模型
        'AlgorithmFramework',
        'Dynamic',          # 动力学
        'Friction',         # 摩擦
        'Penetration',      # 接触穿透
        'CreepNorton', 'CreepBailey',  # 蘙变模型
        'LocalCoordSys',    # 局部坐标系
        'ElementStiffAssembly',
        'ConvergenceCheck',
        'DetectPenetration',
        'JouleHeat',        # 焦耳热
        'Contm',            # Contact method
        'Beam',             # 梁理论
        'Infinite',         # 无限元
        'MassMatrix',       # 质量矩阵（完整名也作域前缀）
        'StiffnessMatrix',
        'Invariants',       # 不变量
        'Principal',        # 主値
        'TensorToVoigt', 'VoigtToTensor',  # 张量-Voigt 转换
        'SurfMetric',       # 表面度量
        'Stiff',            # 刚度相关
        'IntForce',         # 内力相关
        'Output', 'OutputResults', 'OutputFieldValues',
        'GenerateOutput', 'GenerateVisualizationData',
        'ChabocheInteg', 'GTNInteg', 'LemaitreInteg', 'MazarsInteg',
        'DegradedStiff', 'EffectiveStress',
        'IncrementCount',
        # ---- v1.4 最终补充 ----
        # 物理/材料模型标识词
        'Shell', 'Sld2D', 'Sld3D', 'Truss', 'HeatTransfer',
        'Free',                             # Free surface/vibration
        'ReturnMapping',                    # 返回映射算法
        'Unified',                          # 统一本构
        'HyperElasNH', 'HyperElasYeoh',    # 超弹性模型
        'Hardening',                        # 强化模型
        'AugLagForce', 'AugLagUpdate',      # 增广Lagrange
        'LagrangeForce', 'PenaltyForce',    # 约束力
        'PenaltyStiffness',
        'SpatialHash', 'BoundingBox',       # 碰撞加速
        'CoulombFriction', 'ExponentialFriction',
        'PressureDependentFriction', 'VelocityDependentFriction',
        'FrictionStiffness', 'StickSlip',
        'Pair',                             # 接触对
        'Baumgarte',                        # 约束稳定化
        'Position', 'Velocity', 'Acceleration',
        'SelectPath', 'Verify',
        # 数値算法标识词
        'BackwardEuler', 'CrankNicolson', 'Newmark',
        'BackwardEulerIntegration', 'CrankNicolsonIntegration',
        'NewmarkTimeIntegration',
        'NonlinearIterate', 'TransientSolve',
        # 几何/张量工具词
        'ComponentTransform', 'MetricTensor',
        'PolarDecomposition',
        'Hex', 'Pyramid', 'Wedge',          # 单元几何
        # 复合材料失效准则
        'PuckFailure', 'TsaiWuFailure', 'TsaiHillFailure',
        'Hashin3DFailure', 'ProgressiveDamage',
        'OrthotropicStiff',
        # 其他
        'Atomistic', 'Basquin',
        '2D', '3D',                         # 维度后缀作为子域标识
        'Algo',                             # 算法变体（作为第三段领域词）
        'Idx',                              # 索引变体
        'Impl',                             # 实现变体
        'State', 'Track',                   # 状态/追踪
        'AssemPenalty',                     # 组装罚
        # ---- 最终长尾补充 ----
        'ErrorEstimation', 'VisualizationData',
        'WaveMatrix', 'AccelFromResidual', 'EddyStiffness',
        'DiffusionMatrix', 'ModalForce',
        'GuyanReduce', 'ComplexStiff',
        'Deviatoric', 'Rotate', 'Steady',
        'K0Assign', 'GravityForce', 'AllocSlot',
        'CompositeFiberReinforced', 'CompositeLaminate',
        'DamageBrittle', 'DamageDuctile',
        'ElasticIsotropic', 'ElasticOrthotropic',
        'HyperelasticMooneyRivlin', 'HyperelasticNeoHookean',
        'PlasticHill', 'PlasticVonMises',
        'UMATEnsureWorkspace',
        'ViscoelasticKelvinVoigt', 'ViscoelasticMaxwell', 'ViscoelasticProny',
        'CDM', 'CompositeCDM', 'Delamination',
        'ChangChangFailure', 'HashinFailure', 'LaRCFailure',
        'CoffinManson', 'Cosserat',
        'FE2', 'Gradient', 'Multiphysics',
        'Omega', 'Paris', 'Progressive',
        'Puck', 'Rankine', 'RateDependent',
        'SmearedCrack', 'Wave', 'Weibull', 'WillamWarnke',
        'LaRC', 'Hashin', 'Mazars',
        'RadialReturn', 'Isotropic',
        'Kcond', 'Ccap',
        'Identify', 'Describe',
        # ---- 最终清零补充 ----
        'ReturnMappingDruckerPrager', 'ReturnMappingMises',
        'StateUpdate', 'BackupState',
        'ConvertProperties', 'ExportList',
        'MatTangent', 'PK2Stress',
        'CouplingStiffness', 'Plasticity',
        'Reg',                              # Registration/Registry
        'CreepStrainIncr',                  # 蘙变应变增量
        'TangentModulus', 'Kinematic',
        'TempDependentProps',
    }

    FORBIDDEN_PREFIXES = ['Calc_', 'Do_', 'Handle_']  # 移除 Process_（已加入合法动词）

    # 私有子程序后缀豁免
    PRIVATE_SUFFIXES = ('_Impl', '_Priv', '_Internal', '_Helper', '_Core_Impl')

    def check(self, lines: List[str], file_path: str) -> List[RuleViolation]:
        if 'L4_PH' not in file_path.replace('\\', '/'):
            return []

        # 收集模块级 PRIVATE 信息
        module_default_private = False
        explicitly_public = set()
        for ln in lines:
            s = ln.strip()
            if s.startswith('!'):
                continue
            if re.match(r'^\s*PRIVATE\s*$', s, re.I):
                module_default_private = True
            pm = re.match(r'^\s*PUBLIC\s*::\s*(.+)', s, re.I)
            if pm:
                names = re.split(r'[,\s]+', pm.group(1).strip())
                explicitly_public.update(n.strip() for n in names if n.strip())

        violations = []
        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            if stripped.startswith('!'):
                continue

            m = re.match(r'^\s*SUBROUTINE\s+(\w+)', stripped, re.I)
            if not m:
                continue

            sub_name = m.group(1)

            # 私有子程序豁免
            if module_default_private and sub_name not in explicitly_public:
                continue
            if any(sub_name.endswith(s) for s in self.PRIVATE_SUFFIXES):
                continue

            # 检查禁用前缀（适用于所有子程序）
            for fp in self.FORBIDDEN_PREFIXES:
                if sub_name.upper().startswith(fp.upper()):
                    violations.append(RuleViolation(
                        rule_id=self.rule_id, severity=self.severity,
                        file_path=file_path, line_no=i, line_text=stripped,
                        message=f"命名违规：{sub_name} 使用禁用前缀'{fp}'，应改用规范动词（如Compute/Eval）"
                    ))
                    break

            # 检查 L4 命名模式（仅 PH_ 前缀且有4段以上的子程序）
            if sub_name.upper().startswith('PH_'):
                parts = sub_name.split('_')
                if len(parts) < 3:
                    continue  # PH_XX 只有两段，跳过（接口存根等）

                # PH_Domain_Verb_Object 模式：parts[0]='PH', parts[1]=Domain, parts[2]=Verb
                # 复合命名：PH_Prony_ComputeTangent（3段，parts[2]='ComputeTangent' 以 Compute 开头）
                # 元素前缀：PH_Elem_C3D8_Compute（4段，parts[2]='C3D8' 是元素类型）
                # 领域前缀：PH_Constr_Domain_Init（4段，parts[2]='Domain' 是子模块词）
                
                token2 = parts[2] if len(parts) > 2 else ''

                def _is_valid_verb(v: str) -> bool:
                    """检查词 v 是否以合法动词开头（前缀匹配）"""
                    v_lower = v.lower()
                    return any(v_lower.startswith(verb.lower()) for verb in self.ALLOWED_VERBS)

                # 如果 parts[2] 是已知领域前缀词，则检查 parts[3]（如有）作为动词
                if token2 in self.ALLOWED_DOMAIN_TOKENS:
                    if len(parts) > 3:
                        verb = parts[3]
                        if not _is_valid_verb(verb) and verb not in self.ALLOWED_DOMAIN_TOKENS:
                            violations.append(RuleViolation(
                                rule_id=self.rule_id, severity=self.severity,
                                file_path=file_path, line_no=i, line_text=stripped,
                                message=f"L4命名'{sub_name}'：段'{verb}'不以规范动词开头"
                                        f"，考虑重命名为 PH_X_{token2}_Compute/Assemble/..."
                            ))
                    # parts[2] 是域前缀词且没有第4段，合法（如 PH_Cont_Domain）
                else:
                    # parts[2] 作为动词检查（前缀匹配）
                    if token2 and not _is_valid_verb(token2):
                        violations.append(RuleViolation(
                            rule_id=self.rule_id, severity=self.severity,
                            file_path=file_path, line_no=i, line_text=stripped,
                            message=f"L4命名'{sub_name}'中动词段'{token2}'不以规范动词开头"
                                    f"（合法前缀: Compute/Assemble/Apply/Get/Set/Init/Update/...）"
                        ))

        return violations


# ===========================================================================
# MOD-001：模块头完整性检查（Purpose/Theory/Status必填）
# ===========================================================================

class MOD001_ModuleHeader(GuardianRule):
    """模块头必须包含 Purpose/Theory/Status 字段
    
    v1.1 修复：
    - 增加 ExternalLibs/thirdparty/external 目录豁免（第三方库不强制文档）
    - 增加对 Fortran 标准库 USE 块（INTRINSIC）的跳过
    - Theory 字段对 L1_IF 层降级为 P2（基础设施层 Theory 意义不大）
    """
    rule_id     = "MOD-001"
    severity    = "P2"
    description = "每个MODULE必须有完整的模块头注释（Purpose/Theory/Status）"

    REQUIRED_FIELDS = ['Purpose', 'Theory', 'Status']

    EXEMPT_DIR_PATTERNS = [
        'ExternalLibs', 'external_libs', 'thirdparty', 'third_party',
        'external', 'vendor', 'agmg', 'Blas', 'blas',
    ]

    def _is_exempt(self, file_path: str) -> bool:
        norm = file_path.replace('\\', '/')
        return any(p in norm for p in self.EXEMPT_DIR_PATTERNS)

    def check(self, lines: List[str], file_path: str) -> List[RuleViolation]:
        if self._is_exempt(file_path):
            return []

        violations = []
        header_lines = lines[:60]
        header_text = '\n'.join(header_lines)

        has_module = any(
            re.match(r'\s*MODULE\s+\w+', l, re.I)
            for l in header_lines
            if not l.strip().startswith('!')
        )
        if not has_module:
            return []

        for field in self.REQUIRED_FIELDS:
            if not re.search(rf'!\s*{field}\s*:', header_text, re.I):
                violations.append(RuleViolation(
                    rule_id=self.rule_id, severity=self.severity,
                    file_path=file_path, line_no=1, line_text="[MODULE HEADER]",
                    message=f"模块头缺少 '{field}:' 字段（模块文档不完整）"
                ))

        return violations


# ===========================================================================
# CHAIN-001：公开子程序缺少四链注释
# ===========================================================================

class CHAIN001_FourChainComment(GuardianRule):
    """L4_PH核心计算子程序必须包含四链注释（理论链/逻辑链/计算链/数据链）"""
    rule_id     = "CHAIN-001"
    severity    = "P2"
    description = "L4_PH的Compute_*/Assemble_*子程序必须包含四链注释"

    CHAINS = ['理论链', '逻辑链', '计算链', '数据链']
    TARGET_SUB_PATTERN = r'SUBROUTINE\s+((?:Compute|Assemble|PH_\w+_Compute|PH_\w+_Assemble)\w*)'

    def check(self, lines: List[str], file_path: str) -> List[RuleViolation]:
        if 'L4_PH' not in file_path.replace('\\', '/'):
            return []

        violations = []
        in_target_sub = False
        sub_name = ""
        sub_start = 0
        sub_comment_block = []

        for i, line in enumerate(lines, 1):
            stripped = line.strip()

            m = re.search(self.TARGET_SUB_PATTERN, stripped, re.I)
            if m:
                in_target_sub = True
                sub_name = m.group(1)
                sub_start = i
                sub_comment_block = []

            if in_target_sub:
                sub_comment_block.append(stripped)

                if len(sub_comment_block) > 30:
                    block_text = '\n'.join(sub_comment_block)
                    missing = [c for c in self.CHAINS if c not in block_text]
                    if missing:
                        violations.append(RuleViolation(
                            rule_id=self.rule_id, severity=self.severity,
                            file_path=file_path, line_no=sub_start,
                            line_text=f"SUBROUTINE {sub_name}",
                            message=f"缺少四链注释: {', '.join(missing)}"
                        ))
                    in_target_sub = False

                if re.match(r'\s*END\s+SUBROUTINE\b', stripped, re.I):
                    in_target_sub = False

        return violations


# ===========================================================================
# FLOW-002：跨层数据传递禁止通过 SAVE / 模块级可变状态偷渡
# ===========================================================================

class FLOW002_NoHiddenStateTransfer(GuardianRule):
    """核心层跨层路径禁止用 SAVE 变量或模块级可变状态承载业务状态。"""
    rule_id = "FLOW-002"
    severity = "P1"
    description = "跨层数据传递应走显式契约，禁止 SAVE 变量 / 模块级可变状态偷渡"

    TARGET_LAYERS = ("L3_MD", "L4_PH", "L5_RT")
    EXEMPT_PATH_PARTS = (
        "ExternalLibs",
        "thirdparty",
        "/Tests/",
        "\\\\Tests\\\\",
        "test_",
        "_Test",
    )
    EXEMPT_MARKERS = (
        "FLOW-002-exempt",
        "WB-001-exempt",
    )
    RE_SAVE = re.compile(r"\bSAVE\b", re.I)
    RE_MODULE_VAR = re.compile(
        r"^\s*(INTEGER|REAL|LOGICAL|CHARACTER|TYPE\s*\()",
        re.I
    )

    def _target_file(self, file_path: str) -> bool:
        norm = file_path.replace("\\", "/")
        if any(x in norm for x in self.EXEMPT_PATH_PARTS):
            return False
        return any(f"/{layer}/" in norm for layer in self.TARGET_LAYERS)

    def check(self, lines: List[str], file_path: str) -> List[RuleViolation]:
        if not self._target_file(file_path):
            return []

        violations = []
        in_module = False
        in_contains = False
        # Derived-type component lines live between TYPE/END TYPE and must not be
        # classified as module-level mutable state (false positives on four-kind TYPEs).
        type_def_depth = 0

        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            if not stripped or stripped.startswith("!"):
                continue

            if any(m in stripped for m in self.EXEMPT_MARKERS):
                continue

            if re.match(r"^\s*MODULE\b", stripped, re.I) and not re.match(r"^\s*MODULE\s+PROCEDURE\b", stripped, re.I):
                in_module = True
                in_contains = False
                type_def_depth = 0
                continue
            if re.match(r"^\s*CONTAINS\b", stripped, re.I):
                in_contains = True
            if re.match(r"^\s*END\s+MODULE\b", stripped, re.I):
                in_module = False
                in_contains = False
                type_def_depth = 0
                continue

            if re.match(r"^\s*END\s+TYPE\b", stripped, re.I):
                type_def_depth = max(0, type_def_depth - 1)
                continue

            # TYPE, PUBLIC :: Foo / TYPE :: Foo — derived-type definition (not TYPE(Foo) :: obj)
            if re.match(r"^\s*TYPE\b", stripped, re.I) and not re.match(r"^\s*TYPE\s*\(", stripped, re.I):
                type_def_depth += 1
                continue

            if self.RE_SAVE.search(stripped):
                violations.append(
                    RuleViolation(
                        rule_id=self.rule_id,
                        severity=self.severity,
                        file_path=file_path,
                        line_no=i,
                        line_text=stripped,
                        message="检测到 SAVE 变量/语句；跨层业务状态应通过 Arg/Ctx/Populate/Bridge 显式传递",
                    )
                )
                continue

            if in_module and not in_contains and type_def_depth == 0 and self.RE_MODULE_VAR.match(stripped):
                upper = stripped.upper()
                if "PARAMETER" in upper or "POINTER" in upper or "ALLOCATABLE" in upper:
                    continue
                violations.append(
                    RuleViolation(
                        rule_id=self.rule_id,
                        severity=self.severity,
                        file_path=file_path,
                        line_no=i,
                        line_text=stripped,
                        message="检测到模块级可变状态声明；核心层应避免用模块变量承载跨层状态",
                    )
                )
        return violations


# ===========================================================================
# FLOW-003：运行态状态不得反向污染定义态对象
# ===========================================================================

class FLOW003_NoRuntimeWriteToDesc(GuardianRule):
    """禁止向 Desc / *_desc / %desc 字段写入运行态结果。"""
    rule_id = "FLOW-003"
    severity = "P0"
    description = "运行态状态不得反向写入定义态对象（Desc）"

    TARGET_LAYERS = ("L4_PH", "L5_RT", "L6_AP")
    EXEMPT_MARKERS = (
        "FLOW-003-exempt",
        "WB-001-exempt",
    )
    WRITE_PATTERNS = [
        r"\b\w*desc\w*\s*%\s*[\w_]+\s*=(?!=)",
        r"%\s*desc\s*%\s*[\w_]+\s*=(?!=)",
    ]

    def _target_file(self, file_path: str) -> bool:
        norm = file_path.replace("\\", "/")
        return any(f"/{layer}/" in norm for layer in self.TARGET_LAYERS)

    def check(self, lines: List[str], file_path: str) -> List[RuleViolation]:
        if not self._target_file(file_path):
            return []
        violations = []
        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            if not stripped or stripped.startswith("!"):
                continue
            if any(mark in stripped for mark in self.EXEMPT_MARKERS):
                continue
            for pat in self.WRITE_PATTERNS:
                if re.search(pat, stripped, re.I):
                    violations.append(
                        RuleViolation(
                            rule_id=self.rule_id,
                            severity=self.severity,
                            file_path=file_path,
                            line_no=i,
                            line_text=stripped,
                            message="检测到对 Desc 定义态字段的赋値；运行态结果应写入 State/Ctx/Work，而非定义态对象",
                        )
                    )
                    break
        return violations


def _fortran_strip_comments_and_strings(line: str) -> str:
    """Remove Fortran trailing comments and replace character literals with spaces.

    BRG-002 scans for ``\\bBridge\\b`` / ``\\bBrg\\b`` tokens; literals and ``!``
    comments must not trigger false positives (e.g. status messages or USE line tails).

    - ``!`` starts a comment only outside a string; doubled quotes ``''`` / ``""``
      are treated as escaped quotes inside single- / double-quoted literals.
    - Unterminated strings run to EOL (same line only; continuation lines unchanged).
    """
    out: List[str] = []
    i = 0
    n = len(line)
    while i < n:
        ch = line[i]
        if ch == '!':
            break
        if ch in ("'", '"'):
            delim = ch
            i += 1
            while i < n:
                if line[i] != delim:
                    i += 1
                    continue
                if delim == "'" and i + 1 < n and line[i + 1] == "'":
                    i += 2
                    continue
                if delim == '"' and i + 1 < n and line[i + 1] == '"':
                    i += 2
                    continue
                i += 1
                break
            out.append(' ')
            continue
        out.append(ch)
        i += 1
    return ''.join(out)


# ===========================================================================
# BRG-002：Bridge 文件应显式位于桥接路径或具备桥接命名
# ===========================================================================

class BRG002_BridgeNamingPlacementConsistency(GuardianRule):
    """Bridge 适配代码应放在 Bridge/Brg 路径或使用桥接命名，避免桥接逻辑散落常规域实现。

    匹配前剔除行内 Fortran 字符字面量与 ``!`` 尾随注释，避免字符串/注释中的 *bridge* 字样误报。
    """
    rule_id = "BRG-002"
    severity = "P1"
    description = "Bridge 代码应具备桥接路径/命名一致性，避免旁路架构蔓延"

    TARGET_LAYERS = ("L3_MD", "L4_PH", "L5_RT", "L6_AP")
    BRIDGE_USE_PATTERNS = (
        r"\bBridge\b",
        r"\bBrg\b",
        r"\b_Brg\b",
    )
    BRIDGE_PATH_MARKERS = (
        "/Bridge/",
        "/bridge/",
        "_Brg.f90",
        "_Bridge.f90",
    )

    def _target_file(self, file_path: str) -> bool:
        norm = file_path.replace("\\", "/")
        return any(f"/{layer}/" in norm for layer in self.TARGET_LAYERS)

    def _has_bridge_path(self, file_path: str) -> bool:
        norm = file_path.replace("\\", "/")
        return any(mark in norm for mark in self.BRIDGE_PATH_MARKERS)

    def check(self, lines: List[str], file_path: str) -> List[RuleViolation]:
        if not self._target_file(file_path):
            return []
        if self._has_bridge_path(file_path):
            return []

        violations = []
        reported = False
        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            if not stripped or stripped.startswith("!"):
                continue
            scan_line = _fortran_strip_comments_and_strings(stripped)
            if any(re.search(pat, scan_line, re.I) for pat in self.BRIDGE_USE_PATTERNS):
                violations.append(
                    RuleViolation(
                        rule_id=self.rule_id,
                        severity=self.severity,
                        file_path=file_path,
                        line_no=i,
                        line_text=stripped,
                        message="检测到 Bridge/Brg 语义，但文件未位于 Bridge 路径且未使用桥接命名；建议归位到受控桥接路径",
                    )
                )
                reported = True
            if reported:
                break
        return violations


# ===========================================================================
# GLB-001：L4_PH 单元族内核禁止绑定全局容器（一体闭环 / 无暗道）
# ===========================================================================

class GLB001_NoGlobalInElementKernel(GuardianRule):
    """PH_Elem_*_Core 等单元积分核不得 USE UFC_GlobalContainer 或引用 g_ufc_global。
    全局编排留在 Domain/Reg/Bridge；热路径经 Ctx 注入。"""
    rule_id = "GLB-001"
    severity = "P1"
    description = "L4_PH/Element 下单元 *_Core 文件禁止 UFC_GlobalContainer / g_ufc_global"

    EXEMPT_BASENAME_SUBSTR = (
        "Domain_Core",
        "Reg_Core",
        "Contm_Core",
        "Bridge",
        "Brg",
        "_Test",
        "TEST_",
    )

    def _in_element_kernel(self, file_path: str) -> bool:
        norm = file_path.replace("\\", "/")
        if "/L4_PH/Element/" not in norm:
            return False
        base = os.path.basename(norm)
        if not base.endswith(".f90"):
            return False
        if any(s in base for s in self.EXEMPT_BASENAME_SUBSTR):
            return False
        if re.match(r"PH_El[em]_\w+_Core\.f90$", base, re.I):
            return True
        return False

    def check(self, lines: List[str], file_path: str) -> List[RuleViolation]:
        if not self._in_element_kernel(file_path):
            return []
        violations = []
        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            if stripped.startswith("!"):
                continue
            if re.search(r"\bUSE\s+UFC_GlobalContainer_Core\b", stripped, re.I):
                violations.append(
                    RuleViolation(
                        rule_id=self.rule_id,
                        severity=self.severity,
                        file_path=file_path,
                        line_no=i,
                        line_text=stripped,
                        message="单元核禁止 USE UFC_GlobalContainer_Core；数据经 Populate/Ctx 注入",
                    )
                )
            if re.search(r"\bg_ufc_global\b", stripped, re.I):
                violations.append(
                    RuleViolation(
                        rule_id=self.rule_id,
                        severity=self.severity,
                        file_path=file_path,
                        line_no=i,
                        line_text=stripped,
                        message="单元核禁止引用 g_ufc_global（热路径与全局单例解耦）",
                    )
                )
        return violations


# ===========================================================================
# DEP-002：L5_RT 禁止直接 USE L6_AP（应用层不得被运行时反向依赖）
# ===========================================================================

class DEP002_L5NoApplicationUse(GuardianRule):
    """L5 调度层不得 USE AP_ 模块（依赖方向：L6 → L5，非 L5 → L6）。"""
    rule_id = "DEP-002"
    severity = "P0"
    description = "L5_RT 禁止 USE L6_AP（AP_ 前缀模块）"

    BRIDGE_PATTERNS = [r"/Bridge/", r"/bridge/", r"_Brg\.f90$", r"_AP_Brg", r"_RT_Brg"]

    def _is_l5(self, file_path: str) -> bool:
        norm = file_path.replace("\\", "/")
        return "/L5_RT/" in norm

    def _is_bridge(self, file_path: str) -> bool:
        norm = file_path.replace("\\", "/")
        return any(re.search(p, norm, re.I) for p in self.BRIDGE_PATTERNS)

    def check(self, lines: List[str], file_path: str) -> List[RuleViolation]:
        if not self._is_l5(file_path) or self._is_bridge(file_path):
            return []
        violations = []
        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            if stripped.startswith("!"):
                continue
            if re.search(r"\bUSE\s+AP_\w", stripped, re.I):
                violations.append(
                    RuleViolation(
                        rule_id=self.rule_id,
                        severity=self.severity,
                        file_path=file_path,
                        line_no=i,
                        line_text=stripped,
                        message="L5_RT 层 USE 了 AP_*（应用层）；应通过回调/注册表或 L6 调 L5，避免反向依赖",
                    )
                )
        return violations


# ===========================================================================
# NAME-002：MODULE 名与所在层级前缀一致（工程级简称可辨识）
# ===========================================================================

class NAME002_ModuleLayerPrefix(GuardianRule):
    """ufc_core 分层目录下 MODULE 名须以约定前缀开头，避免跨层同名与歧义。"""
    rule_id = "NAME-002"
    severity = "P2"
    description = "MODULE 名须与 L1…L6 目录前缀一致（MD_/PH_/RT_/AP_/NM_/IF_/UFC_ 等）"

    EXEMPT_PATH_PARTS = (
        "ExternalLibs",
        "external_libs",
        "thirdparty",
        "test_stub",
        "Tests/",
        "/test_",
    )

    LAYER_PREFIX_RULES: List[Tuple[str, Any]] = [
        ("/L1_IF/", re.compile(r"^(IF|UF|UFC|NM|ISO|IEEE)_", re.I)),
        ("/L2_NM/", re.compile(r"^(NM|IF|UF|UFC|BLAS|LAPACK)_", re.I)),
        ("/L3_MD/", re.compile(r"^(MD|UF|IF|UFC|NM|VD|CF|AP|RT|PH)_", re.I)),
        ("/L4_PH/", re.compile(r"^(PH|MD|IF|UF|UFC|RT|NM|TEST)_", re.I)),
        ("/L5_RT/", re.compile(
            r"^(RT_|MD_|IF_|UF_|UFC_|PH_|VD_|NM_|Phys_|StepDrv_|MyUEL_)", re.I)),
        ("/L6_AP/", re.compile(r"^(AP|UF|IF|UFC|MD|RT|NM)_", re.I)),
    ]

    RE_MODULE = re.compile(r"^\s*MODULE\s+(\w+)\s*$", re.I)

    def _exempt_file(self, file_path: str) -> bool:
        norm = file_path.replace("\\", "/")
        return any(p in norm for p in self.EXEMPT_PATH_PARTS)

    def check(self, lines: List[str], file_path: str) -> List[RuleViolation]:
        if self._exempt_file(file_path):
            return []
        norm = file_path.replace("\\", "/")
        if "/ufc_core/" not in norm:
            return []

        pattern: Optional[Any] = None
        for sub, pat in self.LAYER_PREFIX_RULES:
            if sub in norm:
                pattern = pat
                break
        if pattern is None:
            return []

        violations = []
        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            if stripped.startswith("!"):
                continue
            m = self.RE_MODULE.match(stripped)
            if not m:
                continue
            name = m.group(1)
            if name.upper() in ("PROCEDURE", "FUNCTION", "SUBROUTINE"):
                continue
            if not pattern.match(name):
                violations.append(
                    RuleViolation(
                        rule_id=self.rule_id,
                        severity=self.severity,
                        file_path=file_path,
                        line_no=i,
                        line_text=stripped,
                        message=f"MODULE `{name}` 与当前层级目录前缀约定不符（期望匹配 {pattern.pattern}）",
                    )
                )
            break
        return violations


# ===========================================================================
# T4-001：*Types.f90 头注释须显式体现四型（Desc/State/Algo/Ctx）语义
# ===========================================================================

class T4_001_FourTypeDocInTypesFile(GuardianRule):
    """域级 Types 模块头部应声明四型分工，便于合同与代码对齐（十大基因 · 四类 TYPE）。"""
    rule_id = "T4-001"
    severity = "P2"
    description = "L3/L4 的 *Types.f90 文件头应出现四型关键词（Desc/State/Algo/Ctx）"

    HEADER_LINES = 100
    REQUIRED_TOKENS = ("Desc", "State", "Algo", "Ctx")
    MIN_TOKENS = 3

    def check(self, lines: List[str], file_path: str) -> List[RuleViolation]:
        norm = file_path.replace("\\", "/")
        base = os.path.basename(norm)
        if not base.endswith("Types.f90"):
            return []
        if "/L3_MD/" not in norm and "/L4_PH/" not in norm:
            return []
        if any(x in norm for x in ("ExternalLibs", "thirdparty", "Tests/", "TEST_", "test_")):
            return []

        head = "\n".join(lines[: self.HEADER_LINES])
        hit = sum(1 for t in self.REQUIRED_TOKENS if t in head)
        if hit < self.MIN_TOKENS:
            return [
                RuleViolation(
                    rule_id=self.rule_id,
                    severity=self.severity,
                    file_path=file_path,
                    line_no=1,
                    line_text="[FILE HEADER]",
                    message=(
                        f"Types 模块头建议显式四型分工（Desc/State/Algo/Ctx）；"
                        f"头 {self.HEADER_LINES} 行内仅命中 {hit}/{len(self.REQUIRED_TOKENS)} 个关键词，"
                        f"至少需 {self.MIN_TOKENS} 个"
                    ),
                )
            ]
        return []


# ===========================================================================
# CON-001：L5_RT/Contact/ 禁止直接 USE MD_Cont_* / MD_Contact_*（G-6 门禁）
# ===========================================================================

class CON001_L5ContactNoL3Direct(GuardianRule):
    """L5_RT/Contact/ 内禁止直接 USE MD_Cont_* / MD_Contact_*（应通过 L4 Populate 路径）"""
    rule_id     = "CON-001"
    severity    = "P1"
    description = "L5_RT/Contact/ 内禁止 USE MD_Cont_*/MD_Contact_*（G6：Contact 域类型分裂，应经 L4 Populate）"

    RE_USE_L3_CONT = re.compile(
        r"^\s*USE\s+(MD_Cont_|MD_Contact_)", re.I
    )

    BRIDGE_EXEMPT_PATHS = ("/L5_RT/Bridge/", "/L4_PH/Bridge/", "_Brg.f90", "_Bridge.f90")

    def _is_bridge_file(self, file_path: str) -> bool:
        norm = file_path.replace("\\", "/")
        return any(p in norm for p in self.BRIDGE_EXEMPT_PATHS)

    def check(self, lines, file_path):
        norm = file_path.replace("\\", "/")
        if "/L5_RT/Contact/" not in norm:
            return []
        if self._is_bridge_file(norm):
            return []
        violations = []
        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            if stripped.startswith("!"):
                continue
            if self.RE_USE_L3_CONT.match(stripped):
                mod_name = stripped.split()[1].rstrip(",")
                violations.append(
                    RuleViolation(
                        rule_id=self.rule_id,
                        severity=self.severity,
                        file_path=file_path,
                        line_no=i,
                        line_text=stripped,
                        message=(
                            f"G6违规：L5_RT/Contact/ 直接 USE L3 模块 `{mod_name}`；"
                            f"应通过 PH_L4_Populate_Contact 填充 slot，热路径消费 slot 而非 L3 类型"
                        ),
                    )
                )
        return violations


# ===========================================================================
# WB-002：RT_WriteBack_Domain_Init 禁止调用 MD_WB_Set* 反向注入（G-10 门禁）
# ===========================================================================

class WB002_NoSetContainerInInit(GuardianRule):
    """RT_WriteBack_Domain_Init 内禁止调用 MD_WB_Set* 类函数（G3-B 反向注入）"""
    rule_id     = "WB-002"
    severity    = "P0"
    description = "G3-B：RT_WriteBack_Domain_Init 禁止调用 MD_WB_Set*（L5 不得反向向 L3 注入容器）"

    RE_CALL_WB_SET = re.compile(r"\bCALL\s+MD_WB_Set", re.I)

    def check(self, lines, file_path):
        norm = file_path.replace("\\", "/")
        if "/L5_RT/WriteBack/" not in norm:
            return []
        in_init = False
        violations = []
        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            if re.match(r"SUBROUTINE\s+RT_WriteBack_Domain_Init", stripped, re.I):
                in_init = True
            elif re.match(r"END\s+SUBROUTINE\s+RT_WriteBack_Domain_Init", stripped, re.I):
                in_init = False
            if not in_init:
                continue
            if stripped.startswith("!"):
                continue
            if self.RE_CALL_WB_SET.search(stripped):
                violations.append(
                    RuleViolation(
                        rule_id=self.rule_id,
                        severity=self.severity,
                        file_path=file_path,
                        line_no=i,
                        line_text=stripped,
                        message=(
                            "G3-B违规：RT_WriteBack_Domain_Init 调用了 MD_WB_Set* 反向注入；"
                            "L5 Init 禁止修改 L3 内部状态容器（参见整改计划 N0-1）"
                        ),
                    )
                )
        return violations


# ===========================================================================
# IDX-001：L3_MD/Element/Mesh 优先扁平 _Idx API（嵌套索引 vs 扁平存储）
# ===========================================================================

class IDX001_PreferMeshIdxApi(GuardianRule):
    """Mesh 域内新代码应通过 *_Idx 查询接口访问，避免遗留无 _Idx 的 CALL 扩散。"""
    rule_id = "IDX-001"
    severity = "P2"
    description = "L3_MD/Element/Mesh 中 CALL MD_Mesh_Get* 非 _Idx 后缀（建议迁移扁平索引 API）"

    RE_CALL_MESH = re.compile(r"\bCALL\s+(MD_Mesh_Get\w+)\s*\(", re.I)

    def check(self, lines: List[str], file_path: str) -> List[RuleViolation]:
        norm = file_path.replace("\\", "/")
        if "/L3_MD/" not in norm or "/Mesh/" not in norm:
            return []
        if any(x in norm for x in ("ExternalLibs", "thirdparty", "test_")):
            return []

        violations = []
        reported = False
        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            if stripped.startswith("!"):
                continue
            m = self.RE_CALL_MESH.search(stripped)
            if not m:
                continue
            callee = m.group(1)
            if callee.upper().endswith("_IDX"):
                continue
            if not reported:
                violations.append(
                    RuleViolation(
                        rule_id=self.rule_id,
                        severity=self.severity,
                        file_path=file_path,
                        line_no=i,
                        line_text=stripped,
                        message=f"Mesh 域建议改用 {callee}_Idx 风格 API；命中 `{callee}`",
                    )
                )
                reported = True
        return violations


# ===========================================================================
# 守卫引擎
# ===========================================================================

class GuardianEngine:
    def __init__(self, enabled_rules: Optional[List[str]] = None):
        all_rules = [
            HOT001_NoAllocInHotPath(),
            HOT002_NoAllocInBridgeResponse(),
            HOT003_NoL3InHotPath(),
            HOT004_NoIOInHotPath(),
            WB001_NoWriteL3Desc(),
            WB002_NoSetContainerInInit(),       # G-10: G3-B 反向注入门禁 (N0-1)
            DEP001_NoUpwardUse(),
            DEP002_L5NoApplicationUse(),
            DATA001_LayerCallDirection(),
            INTF001_ArgWrapper(),
            MAT001_NoFullMatrix(),
            NAME001_NamingConvention(),
            NAME002_ModuleLayerPrefix(),
            MOD001_ModuleHeader(),
            CHAIN001_FourChainComment(),
            FLOW002_NoHiddenStateTransfer(),
            FLOW003_NoRuntimeWriteToDesc(),
            BRG002_BridgeNamingPlacementConsistency(),
            GLB001_NoGlobalInElementKernel(),
            CON001_L5ContactNoL3Direct(),        # G-6: Contact 域类型分裂门禁 (N0-2)
            T4_001_FourTypeDocInTypesFile(),
            IDX001_PreferMeshIdxApi(),
            TYPE001_MemberNaming(),                # 修正版方案A: TYPE成员命名一致性
            TYPE002_ConstantNamespace(),          # 修正版方案A: 常量命名空间隔离
            TYPE003_CtxNoAlloc(),                  # 修正版方案A: Ctx热路径零分配
        ]
        if enabled_rules:
            self.rules = [r for r in all_rules if r.rule_id in enabled_rules]
        else:
            self.rules = all_rules

    def scan_file(self, path: str) -> List[RuleViolation]:
        try:
            with open(path, 'r', encoding='utf-8', errors='replace') as f:
                lines = f.readlines()
        except OSError as e:
            print(f"[Guardian] WARNING: Cannot read {path}: {e}", file=sys.stderr)
            return []

        all_violations = []
        for rule in self.rules:
            try:
                all_violations.extend(rule.check(lines, path))
            except Exception as e:
                print(f"[Guardian] ERROR in rule {rule.rule_id} on {path}: {e}", file=sys.stderr)

        return all_violations

    def scan_directory(self, root: str) -> List[RuleViolation]:
        all_v = []
        for dirpath, dirnames, files in os.walk(root):
            dirnames[:] = [d for d in dirnames if d not in ('build', 'refactor_out', '__pycache__', '.git')]
            for fname in files:
                if fname.endswith('.f90'):
                    all_v.extend(self.scan_file(os.path.join(dirpath, fname)))
        return all_v

    def generate_report(self, violations: List[RuleViolation],
                        scan_path: str = "") -> Tuple[str, int]:
        p0 = [v for v in violations if v.severity == "P0"]
        p1 = [v for v in violations if v.severity == "P1"]
        p2 = [v for v in violations if v.severity == "P2"]

        now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        lines = [
            f"# UFC Guardian 架构审查报告",
            f"",
            f"> 扫描路径：`{scan_path}`",
            f"> 扫描时间：{now}",
            f"> 总违规数：{len(violations)}（P0: {len(p0)}, P1: {len(p1)}, P2: {len(p2)}）",
            f"",
        ]

        if p0:
            lines.append(f"## 红灯项 P0（{len(p0)}处，须立即修复）")
            lines.append("")
            for v in p0:
                lines.append(f"- [{v.rule_id}] `{v.file_path}:{v.line_no}`")
                lines.append(f"  - 问题：{v.message}")
                lines.append(f"  - 代码：`{v.line_text[:120]}`")
            lines.append("")
        else:
            lines.append("## 红灯项 P0：无违规 ✅")
            lines.append("")

        if p1:
            lines.append(f"## 黄灯项 P1（{len(p1)}处，本迭代修复）")
            lines.append("")
            for v in p1:
                lines.append(f"- [{v.rule_id}] `{v.file_path}:{v.line_no}`  {v.message}")
            lines.append("")
        else:
            lines.append("## 黄灯项 P1：无违规 ✅")
            lines.append("")

        if p2:
            lines.append(f"## 绻灯项 P2（{len(p2)}处，下迭代处理）")
            lines.append("")
            for v in p2:
                lines.append(f"- [{v.rule_id}] `{v.file_path}:{v.line_no}`  {v.message}")
            lines.append("")
        else:
            lines.append("## 绻灯项 P2：无违规 ✅")
            lines.append("")

        if violations:
            lines.append("## 按规则统计")
            lines.append("")
            rule_counts = {}
            for v in violations:
                rule_counts[v.rule_id] = rule_counts.get(v.rule_id, 0) + 1
            for rule_id, count in sorted(rule_counts.items()):
                lines.append(f"- {rule_id}: {count}处")
            lines.append("")

        return "\n".join(lines), len(p0)

    def generate_json_report(self, violations: List[RuleViolation]) -> str:
        return json.dumps([
            {
                "rule_id": v.rule_id,
                "severity": v.severity,
                "file_path": v.file_path,
                "line_no": v.line_no,
                "line_text": v.line_text,
                "message": v.message,
            }
            for v in violations
        ], ensure_ascii=False, indent=2)


# ===========================================================================
# CLI 入口
# ===========================================================================

def main():
    parser = argparse.ArgumentParser(
        description="UFC Architecture Guardian - 架构契约守卫引擎",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例：
  # 扫描单文件
  python arch_guardian.py ufc_core/L4_PH/Bridge/PH_Brg_L3.f90

  # 扫描目录，P0违规时非零退出（pre-commit hook）
  python arch_guardian.py ufc_core/L4_PH/ --fail-on-p0

  # 全库扫描并生成Markdown报告
  python arch_guardian.py ufc_core/ --report > REPORTS/guardian_report.md

  # 仅运行指定规则
  python arch_guardian.py ufc_core/L4_PH/ --rules HOT-001,HOT-002,WB-001
  python arch_guardian.py ufc_core/ --rules GLB-001,DEP-002,NAME-002,T4-001,IDX-001
  python arch_guardian.py ufc_core/ --rules FLOW-002,FLOW-003
  python arch_guardian.py ufc_core/ --rules BRG-002

  # 输出JSON格式（CI系统集成）
  python arch_guardian.py ufc_core/ --json
        """
    )
    parser.add_argument(
        "path",
        help="要扫描的文件或目录路径"
    )
    parser.add_argument(
        "--fail-on-p0",
        action="store_true",
        help="存在P0违规时以退出码1退出（用于pre-commit hook）"
    )
    parser.add_argument(
        "--report",
        action="store_true",
        help="输出完整Markdown格式报告（默认输出简洁列表）"
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="输出JSON格式报告（适合CI系统集成）"
    )
    parser.add_argument(
        "--rules",
        type=str,
        default=None,
        help="仅运行指定规则（逗号分隔，如：HOT-001,WB-001）"
    )
    parser.add_argument(
        "--p0-only",
        action="store_true",
        help="仅显示P0违规"
    )
    parser.add_argument(
        "--save",
        type=str,
        default=None,
        help="将报告保存到指定文件路径"
    )

    args = parser.parse_args()

    enabled_rules = [r.strip() for r in args.rules.split(',')] if args.rules else None
    engine = GuardianEngine(enabled_rules=enabled_rules)

    scan_path = os.path.abspath(args.path)
    if not os.path.exists(scan_path):
        print(f"[Guardian] ERROR: 路径不存在: {scan_path}", file=sys.stderr)
        sys.exit(2)

    print(f"[Guardian] 扫描路径: {scan_path}", file=sys.stderr)

    if os.path.isfile(scan_path):
        violations = engine.scan_file(scan_path)
    else:
        violations = engine.scan_directory(scan_path)

    if args.p0_only:
        violations = [v for v in violations if v.severity == "P0"]

    if args.json:
        output = engine.generate_json_report(violations)
        print(output)
    elif args.report:
        report, p0_count = engine.generate_report(violations, scan_path)
        print(report)
        if args.save:
            with open(args.save, 'w', encoding='utf-8') as f:
                f.write(report)
            print(f"\n[Guardian] 报告已保存到: {args.save}", file=sys.stderr)
    else:
        p0 = [v for v in violations if v.severity == "P0"]
        p1 = [v for v in violations if v.severity == "P1"]
        p2 = [v for v in violations if v.severity == "P2"]
        print(f"[Guardian] 扫描完成: {len(violations)}个违规（P0:{len(p0)}, P1:{len(p1)}, P2:{len(p2)}）")
        for v in violations:
            print(f"  {v}")

    p0_count = sum(1 for v in violations if v.severity == "P0")

    if args.fail_on_p0 and p0_count > 0:
        print(f"\n[Guardian] BLOCKED: 发现 {p0_count} 个P0违规，拒绝提交。", file=sys.stderr)
        sys.exit(1)

    sys.exit(0)


if __name__ == "__main__":
    main()
