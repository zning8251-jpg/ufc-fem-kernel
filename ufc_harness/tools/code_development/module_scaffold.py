#!/usr/bin/env python3
"""
UFC 模块脚手架生成器
功能: 根据模板生成标准化的 Fortran 模块文件
"""

import os
import json
import sys
from pathlib import Path
from datetime import datetime
from typing import Dict, Optional


class ModuleScaffoldGenerator:
    """模块脚手架生成器"""
    
    # 模块类型模板
    MODULE_TEMPLATES = {
        "core": {
            "description": "核心算法模块 (含 TYPE 定义和过程)",
            "suffix": "_Core",
            "has_type": True,
            "has_interface": False
        },
        "types": {
            "description": "类型定义模块 (仅 TYPE 定义)",
            "suffix": "_Types",
            "has_type": True,
            "has_interface": False
        },
        "intf": {
            "description": "接口模块 (仅 INTERFACE 定义)",
            "suffix": "_Intf",
            "has_type": False,
            "has_interface": True
        },
        "wrapper": {
            "description": "包装接口模块 (UMAT/UE 包装)",
            "suffix": "_Wrapper",
            "has_type": False,
            "has_interface": True
        }
    }
    
    # UFC 层级前缀映射
    LAYER_PREFIXES = {
        "L1_IF": "if_",
        "L2_NM": "nm_",
        "L3_MD": "md_",
        "L4_PH": "ph_",
        "L5_RT": "rt_",
        "L6_AP": "ap_"
    }
    
    def __init__(self, config_path: Optional[str] = None):
        self.config = {}
        if config_path and Path(config_path).exists():
            with open(config_path, 'r', encoding='utf-8') as f:
                self.config = json.load(f)
    
    def generate(self, 
                 module_name: str,
                 module_type: str,
                 layer: str,
                 domain: str,
                 output_dir: str) -> Dict:
        """生成模块脚手架"""
        
        if module_type not in self.MODULE_TEMPLATES:
            return {"success": False, "error": f"未知模块类型: {module_type}"}
        
        template = self.MODULE_TEMPLATES[module_type]
        prefix = self.LAYER_PREFIXES.get(layer, "")
        
        # 生成文件名
        file_name = f"{module_name}{template['suffix']}.f90"
        output_path = Path(output_dir) / file_name
        
        # 生成模块内容
        content = self._generate_content(
            module_name, module_type, layer, domain, prefix, template
        )
        
        # 写入文件
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(content, encoding='utf-8')
        
        return {
            "success": True,
            "file": str(output_path),
            "module_name": module_name + template['suffix']
        }
    
    def _generate_content(self, 
                          module_name: str,
                          module_type: str,
                          layer: str,
                          domain: str,
                          prefix: str,
                          template: Dict) -> str:
        """生成模块内容"""
        
        mod_name = f"{module_name}{template['suffix']}"
        
        content = f"""! =============================================================================
! UFC {layer} Layer - {domain} Domain
! Module: {mod_name}
! Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
! 
! Description: {template['description']}
! =============================================================================

module {mod_name}
    use UFC_Global_Defs
    implicit none
    
    ! 模块级常量
    integer, parameter :: DP = selected_real_kind(15, 307)
    
    ! -----------------------------------------------------------------------------
    ! TYPE 定义
    ! -----------------------------------------------------------------------------
"""
        
        if template['has_type']:
            content += f"""
    ! {domain} 域核心类型
    type :: {module_name}_Type
        ! 状态变量
        logical :: is_initialized = .false.
        
        ! 参数变量
        real(DP) :: param1 = 0.0_DP
        real(DP) :: param2 = 0.0_DP
        
        ! 内部变量
        real(DP), allocatable :: internal_vars(:)
    contains
        procedure :: init => {module_name}_init
        procedure :: compute => {module_name}_compute
        procedure :: cleanup => {module_name}_cleanup
    end type {module_name}_Type

    ! 过程声明
    interface
        subroutine {module_name}_init(this, config)
            import {module_name}_Type
            class({module_name}_Type), intent(inout) :: this
            real(DP), intent(in), optional :: config(:)
        end subroutine {module_name}_init
        
        subroutine {module_name}_compute(this, input, output, status)
            import {module_name}_Type
            class({module_name}_Type), intent(inout) :: this
            real(DP), intent(in) :: input(:)
            real(DP), intent(out) :: output(:)
            integer, intent(out) :: status
        end subroutine {module_name}_compute
        
        subroutine {module_name}_cleanup(this)
            import {module_name}_Type
            class({module_name}_Type), intent(inout) :: this
        end subroutine {module_name}_cleanup
    end interface
"""
        
        if template['has_interface']:
            content += f"""
    ! -----------------------------------------------------------------------------
    ! INTERFACE 定义
    ! -----------------------------------------------------------------------------
    
    ! UFC 标准接口
    interface
        subroutine {module_name}_compute(input, output, status)
            real(DP), intent(in) :: input(:)
            real(DP), intent(out) :: output(:)
            integer, intent(out) :: status
        end subroutine {module_name}_compute
    end interface
"""
        
        content += f"""
    ! -----------------------------------------------------------------------------
    ! 公共接口导出
    ! -----------------------------------------------------------------------------
    
    ! 将模块名作为公共别名
    public :: {mod_name}
    
contains

    ! -----------------------------------------------------------------------------
    ! 模块过程实现
    ! -----------------------------------------------------------------------------
    
end module {mod_name}
"""
        
        return content
    
    def list_templates(self) -> Dict:
        """列出可用模板"""
        return self.MODULE_TEMPLATES


def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(description='UFC 模块脚手架生成器')
    parser.add_argument('--name', required=True, help='模块基础名称')
    parser.add_argument('--type', required=True, choices=['core', 'types', 'intf', 'wrapper'],
                       help='模块类型')
    parser.add_argument('--layer', required=True, choices=['L1_IF', 'L2_NM', 'L3_MD', 'L4_PH', 'L5_RT', 'L6_AP'],
                       help='UFC 层级')
    parser.add_argument('--domain', required=True, help='域名称')
    parser.add_argument('--output', default='.', help='输出目录')
    parser.add_argument('--config', help='配置文件路径')
    
    args = parser.parse_args()
    
    generator = ModuleScaffoldGenerator(args.config)
    result = generator.generate(
        args.name,
        args.type,
        args.layer,
        args.domain,
        args.output
    )
    
    print(json.dumps(result, indent=2, ensure_ascii=False))
    sys.exit(0 if result['success'] else 1)


if __name__ == "__main__":
    main()
