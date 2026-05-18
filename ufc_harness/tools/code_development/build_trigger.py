#!/usr/bin/env python3
"""
UFC 构建触发器
功能: 执行 CMake 编译并提供实时反馈
"""

import os
import sys
import subprocess
import json
import time
from pathlib import Path
from typing import Dict, List, Optional, Tuple

_UFC_HARNESS = Path(__file__).resolve().parents[2]
if str(_UFC_HARNESS) not in sys.path:
    sys.path.insert(0, str(_UFC_HARNESS))

import harness_paths  # noqa: E402


def _default_cmake_generator() -> str:
    g = os.environ.get("UFC_CMAKE_GENERATOR", "").strip()
    if g:
        return g
    return "MinGW Makefiles" if os.name == "nt" else "Unix Makefiles"


class BuildTrigger:
    """构建触发器"""
    
    def __init__(self, build_dir: Optional[str] = None):
        if build_dir:
            self.build_dir = Path(build_dir)
        else:
            self.build_dir = harness_paths.default_build_dir()
        self.source_dir = self.build_dir.parent / "ufc_core"
    
    def check_build_system(self) -> Dict:
        """检查构建系统状态"""
        status = {}
        
        # 检查 CMakeLists.txt
        cmake_file = self.source_dir / "CMakeLists.txt"
        status['cmake_exists'] = cmake_file.exists()
        
        # 检查构建目录
        status['build_dir_exists'] = self.build_dir.exists()
        
        # 检查 CMakeCache
        cache_file = self.build_dir / "CMakeCache.txt"
        status['cmake_cache_exists'] = cache_file.exists()
        
        # 检查编译结果
        if cache_file.exists():
            try:
                content = cache_file.read_text(encoding='utf-8', errors='ignore')
                # 提取构建类型
                for line in content.split('\n'):
                    if 'CMAKE_BUILD_TYPE:STRING=' in line:
                        status['build_type'] = line.split('=')[1].strip()
                    if 'CMAKE_GENERATOR:INTERNAL=' in line:
                        status['generator'] = line.split('=')[1].strip()
            except:
                pass
        
        return status
    
    def configure(self, clean: bool = False) -> Dict:
        """配置 CMake"""
        if clean:
            # 清理构建目录
            import shutil
            if self.build_dir.exists():
                print("清理构建目录...")
                shutil.rmtree(self.build_dir)
            self.build_dir.mkdir(parents=True)
        
        if not self.build_dir.exists():
            self.build_dir.mkdir(parents=True)
        
        # 执行 CMake 配置
        print("执行 CMake 配置...")
        cmd = [
            "cmake",
            "-S", str(self.source_dir),
            "-B", str(self.build_dir),
            "-G", _default_cmake_generator(),
            "-DCMAKE_BUILD_TYPE=Debug"
        ]
        
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                cwd=str(self.build_dir)
            )
            
            return {
                "success": result.returncode == 0,
                "stdout": result.stdout,
                "stderr": result.stderr,
                "returncode": result.returncode
            }
        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }
    
    def build(self, target: str = None, jobs: int = None) -> Dict:
        """执行编译"""
        # 先配置
        config_result = self.check_build_system()
        if not config_result.get('cmake_cache_exists'):
            conf_result = self.configure()
            if not conf_result['success']:
                return conf_result
        
        # 执行编译
        print(f"执行编译{' (目标: ' + target + ')' if target else ''}...")
        
        cmd = ["cmake", "--build", str(self.build_dir)]
        
        if target:
            cmd.extend(["--target", target])
        
        if jobs:
            cmd.extend(["--", f"-j{jobs}"])
        else:
            cmd.extend(["--", "-j4"])
        
        try:
            start_time = time.time()
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                cwd=str(self.build_dir)
            )
            elapsed = time.time() - start_time
            
            # 解析输出
            success = result.returncode == 0
            
            # 提取编译信息
            output_lines = result.stdout.split('\n')
            compiled_files = [l for l in output_lines if 'Compiling' in l]
            errors = [l for l in output_lines if 'error:' in l.lower()]
            warnings = [l for l in output_lines if 'warning:' in l.lower()]
            
            return {
                "success": success,
                "returncode": result.returncode,
                "elapsed_seconds": round(elapsed, 2),
                "compiled_files_count": len(compiled_files),
                "errors_count": len(errors),
                "warnings_count": len(warnings),
                "stdout": result.stdout[-5000:] if len(result.stdout) > 5000 else result.stdout,
                "stderr": result.stderr[-2000:] if len(result.stderr) > 2000 else result.stderr
            }
        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }
    
    def quick_build(self) -> Dict:
        """快速构建 (配置+编译)"""
        # 检查状态
        status = self.check_build_system()
        
        if not status.get('cmake_cache_exists'):
            # 需要配置
            conf_result = self.configure()
            if not conf_result['success']:
                return conf_result
        
        # 直接编译
        return self.build()
    
    def get_build_summary(self) -> Dict:
        """获取构建摘要"""
        status = self.check_build_system()
        
        summary = {
            "source_dir": str(self.source_dir),
            "build_dir": str(self.build_dir),
            "cmake_configured": status.get('cmake_cache_exists', False),
            "build_type": status.get('build_type', 'Unknown')
        }
        
        # 检查可执行文件
        exe_files = list(self.build_dir.rglob("*.exe"))
        summary['exe_files'] = [str(f.relative_to(self.build_dir)) for f in exe_files[:10]]
        
        # 检查库文件
        lib_files = list(self.build_dir.rglob("*.a")) + list(self.build_dir.rglob("*.lib"))
        summary['lib_files'] = [str(f.relative_to(self.build_dir)) for f in lib_files[:10]]
        
        return summary


def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(description='UFC 构建触发器')
    parser.add_argument(
        '--build-dir', '-b',
        default=None,
        help='构建目录（默认：UFC/build）',
    )
    parser.add_argument('--target', '-t', help='编译目标')
    parser.add_argument('--jobs', '-j', type=int, default=4, help='并行任务数')
    parser.add_argument('--clean', '-c', action='store_true', help='清理后重新构建')
    parser.add_argument('--configure', action='store_true', help='仅配置')
    parser.add_argument('--status', action='store_true', help='显示状态')
    parser.add_argument('--json', action='store_true', help='JSON 格式输出')
    
    args = parser.parse_args()
    
    trigger = BuildTrigger(args.build_dir or None)
    
    if args.status:
        result = trigger.get_build_summary()
    elif args.configure:
        result = trigger.configure(clean=args.clean)
    else:
        result = trigger.quick_build()
    
    if args.json:
        print(json.dumps(result, indent=2, ensure_ascii=False))
    else:
        if result.get('success'):
            print(f"✓ 构建成功 ({result.get('elapsed_seconds', 0)}s)")
            print(f"  编译文件: {result.get('compiled_files_count', 0)}")
            print(f"  错误: {result.get('errors_count', 0)}")
            print(f"  警告: {result.get('warnings_count', 0)}")
        else:
            print("✗ 构建失败")
            if result.get('error'):
                print(f"  错误: {result['error']}")
            if result.get('stderr'):
                print(f"  详情: {result['stderr'][:500]}")
    
    sys.exit(0 if result.get('success', False) else 1)


if __name__ == "__main__":
    main()
