# UFC 运维手册

> **版本**: v1.0  
> **创建日期**: 2026-03-06  
> **最后更新**: 2026-03-06  
> **适用范围**: UFC 项目运维与维护  
> **上级参考**: UFC_DEPLOYMENT_GUIDE.md（部署指南）

---

## 📋 文档说明

本文档提供 UFC 项目的运维手册，包括：
- 日志管理
- 性能监控
- 故障排查
- 备份与恢复
- 升级指南
- 日常维护

---

## 目录

1. [日志管理](#1-日志管理)
2. [性能监控](#2-性能监控)
3. [故障排查](#3-故障排查)
4. [备份与恢复](#4-备份与恢复)
5. [升级指南](#5-升级指南)
6. [日常维护](#6-日常维护)
7. [运维最佳实践](#7-运维最佳实践)

---

## 1. 日志管理

### 1.1 日志位置

**默认日志位置**:
- Linux/macOS: `/var/log/ufc/ufc.log`
- Windows: `C:\ProgramData\UFC\logs\ufc.log`

**用户日志位置**:
- Linux/macOS: `~/.ufc/logs/ufc.log`
- Windows: `%LOCALAPPDATA%\UFC\logs\ufc.log`

### 1.2 日志级别

**日志级别**（从低到高）:
- `DEBUG`: 详细调试信息
- `INFO`: 一般信息
- `WARNING`: 警告信息
- `ERROR`: 错误信息
- `CRITICAL`: 严重错误

**设置日志级别**:
```bash
# 环境变量
export UFC_LOG_LEVEL=INFO

# 配置文件
log_level = INFO
```

### 1.3 日志轮转

**使用 logrotate** (Linux):

创建 `/etc/logrotate.d/ufc`:
```
/var/log/ufc/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0644 ufc ufc
}
```

**手动轮转**:
```bash
# 重命名当前日志
mv ufc.log ufc.log.$(date +%Y%m%d)

# 重新加载配置
kill -HUP $(pgrep ufc_solver)
```

### 1.4 日志分析

**查看最近错误**:
```bash
grep ERROR /var/log/ufc/ufc.log | tail -20
```

**统计错误数量**:
```bash
grep -c ERROR /var/log/ufc/ufc.log
```

**查看特定时间段的日志**:
```bash
grep "2026-03-06" /var/log/ufc/ufc.log
```

---

## 2. 性能监控

### 2.1 系统资源监控

**CPU 使用率**:
```bash
top -p $(pgrep ufc_solver)
# 或
htop -p $(pgrep ufc_solver)
```

**内存使用**:
```bash
ps aux | grep ufc_solver | awk '{print $6/1024 " MB"}'
```

**磁盘 I/O**:
```bash
iotop -p $(pgrep ufc_solver)
```

### 2.2 UFC 性能指标

**启用性能监控**:
```bash
ufc_solver --profile --input=model.inp
```

**性能报告位置**:
- `model_profile.json`: JSON 格式性能数据
- `model_profile.txt`: 文本格式性能报告

**性能指标**:
- **求解时间**: 总求解时间（秒）
- **内存峰值**: 最大内存使用（GB）
- **迭代次数**: 非线性迭代次数
- **收敛率**: 收敛速度
- **并行效率**: OpenMP/MPI 并行效率

### 2.3 性能基准测试

**运行基准测试**:
```bash
ufc_benchmark --test=all --output=benchmark.json
```

**对比历史性能**:
```bash
ufc_benchmark --compare=baseline.json --current=benchmark.json
```

**性能告警**:
```bash
# 如果性能退化 > 10%，发出告警
ufc_benchmark --alert-threshold=0.1
```

---

## 3. 故障排查

### 3.1 常见错误

#### 错误 1: 内存不足

**症状**:
```
ERROR: Out of memory
ERROR: Memory allocation failed
```

**排查步骤**:
1. 检查可用内存: `free -h`
2. 检查内存限制: `ulimit -v`
3. 减少内存使用:
   - 使用更粗的网格
   - 减少并行线程数
   - 启用内存池优化

**解决方案**:
```bash
# 增加交换空间
sudo swapon --show
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 或减少内存使用
export OMP_NUM_THREADS=2
ufc_solver --memory-limit=8GB model.inp
```

#### 错误 2: 求解器不收敛

**症状**:
```
WARNING: Solver did not converge after 1000 iterations
ERROR: Convergence failed
```

**排查步骤**:
1. 检查模型合理性（材料参数、边界条件）
2. 检查网格质量
3. 检查时间步长（动力分析）
4. 检查收敛容差设置

**解决方案**:
```bash
# 增加最大迭代次数
ufc_solver --max-iterations=2000 model.inp

# 放宽收敛容差
ufc_solver --tolerance=1.0e-5 model.inp

# 启用线搜索
ufc_solver --line-search model.inp
```

#### 错误 3: 文件 I/O 错误

**症状**:
```
ERROR: Failed to open file: model.inp
ERROR: Permission denied
```

**排查步骤**:
1. 检查文件是否存在: `ls -la model.inp`
2. 检查文件权限: `chmod 644 model.inp`
3. 检查磁盘空间: `df -h`
4. 检查文件系统错误: `fsck /dev/sda1`

**解决方案**:
```bash
# 修复权限
chmod 644 model.inp

# 检查磁盘空间
df -h
# 清理磁盘空间

# 检查文件系统
sudo fsck /dev/sda1
```

### 3.2 调试模式

**启用调试模式**:
```bash
ufc_solver --debug --input=model.inp
```

**调试输出位置**:
- `model_debug.log`: 详细调试日志
- `model_debug.trace`: 函数调用跟踪

**使用 GDB 调试** (Linux):
```bash
gdb --args ufc_solver model.inp
(gdb) run
(gdb) bt  # 查看堆栈跟踪
```

**使用 Valgrind 检查内存**:
```bash
valgrind --leak-check=full ufc_solver model.inp
```

### 3.3 故障报告

**收集故障信息**:
```bash
ufc_diagnose --output=diagnostic.tar.gz
```

**诊断信息包括**:
- 系统信息（OS、CPU、内存）
- UFC 版本信息
- 配置文件
- 日志文件
- 性能数据

**提交故障报告**:
```bash
# 上传诊断文件
ufc_report --upload=diagnostic.tar.gz
```

---

## 4. 备份与恢复

### 4.1 数据备份

**备份配置文件**:
```bash
# Linux/macOS
tar -czf ufc_config_backup_$(date +%Y%m%d).tar.gz \
  /opt/ufc/etc/ \
  ~/.ufc/config/

# Windows
tar -czf ufc_config_backup_%date%.tar.gz \
  "C:\Program Files\UFC\etc\" \
  "%LOCALAPPDATA%\UFC\config\"
```

**备份数据文件**:
```bash
# 备份输入文件
rsync -av /data/ufc/inputs/ /backup/ufc/inputs/

# 备份输出文件
rsync -av /data/ufc/outputs/ /backup/ufc/outputs/
```

**自动备份脚本** (Linux):
```bash
#!/bin/bash
# /usr/local/bin/ufc_backup.sh

BACKUP_DIR="/backup/ufc"
DATE=$(date +%Y%m%d)

# 备份配置
tar -czf $BACKUP_DIR/config_$DATE.tar.gz /opt/ufc/etc/

# 备份数据
rsync -av /data/ufc/ $BACKUP_DIR/data_$DATE/

# 删除 30 天前的备份
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete
```

**设置定时任务** (cron):
```bash
# 每天凌晨 2 点备份
0 2 * * * /usr/local/bin/ufc_backup.sh
```

### 4.2 数据恢复

**恢复配置文件**:
```bash
tar -xzf ufc_config_backup_20260306.tar.gz -C /
```

**恢复数据文件**:
```bash
rsync -av /backup/ufc/data_20260306/ /data/ufc/
```

**验证恢复**:
```bash
ufc_config --validate
ufc_solver --test-restore
```

### 4.3 灾难恢复

**完整系统恢复步骤**:
1. 重新安装 UFC（参考部署指南）
2. 恢复配置文件
3. 恢复数据文件
4. 验证安装和配置
5. 运行测试用例

---

## 5. 升级指南

### 5.1 升级前准备

**备份当前安装**:
```bash
# 备份配置
tar -czf ufc_config_backup.tar.gz /opt/ufc/etc/

# 备份数据
rsync -av /data/ufc/ /backup/ufc/
```

**检查当前版本**:
```bash
ufc_solver --version
```

**查看升级说明**:
```bash
# 查看 CHANGELOG
cat /opt/ufc/CHANGELOG.md
```

### 5.2 升级步骤

#### 从源码升级

**步骤 1: 获取新版本**:
```bash
cd ufc
git pull origin main
git checkout v1.1.0  # 或最新版本
```

**步骤 2: 重新编译**:
```bash
cd build
cmake ..
make -j$(nproc)
```

**步骤 3: 运行测试**:
```bash
ctest --output-on-failure
```

**步骤 4: 安装**:
```bash
sudo make install
```

#### 从预编译包升级

**Linux (Debian/Ubuntu)**:
```bash
sudo apt-get update
sudo apt-get install --only-upgrade ufc
```

**Linux (RPM)**:
```bash
sudo rpm -Uvh ufc-1.1.0-1.x86_64.rpm
```

**Windows**:
```powershell
# 运行新版本安装程序
# 安装程序会自动卸载旧版本
```

### 5.3 升级后验证

**验证版本**:
```bash
ufc_solver --version
```

**验证功能**:
```bash
ufc_solver --test-all
```

**验证性能**:
```bash
ufc_benchmark --compare-baseline
```

### 5.4 回滚

**如果升级失败，回滚到旧版本**:
```bash
# 恢复配置文件
tar -xzf ufc_config_backup.tar.gz -C /

# 重新安装旧版本
sudo apt-get install ufc=1.0.0-1
```

---

## 6. 日常维护

### 6.1 定期检查

**每日检查**:
- [ ] 日志文件大小（防止磁盘满）
- [ ] 错误日志（检查是否有新错误）
- [ ] 系统资源使用（CPU、内存、磁盘）

**每周检查**:
- [ ] 性能基准测试（对比历史性能）
- [ ] 备份完整性（验证备份文件）
- [ ] 磁盘空间（清理临时文件）

**每月检查**:
- [ ] 版本更新（检查是否有新版本）
- [ ] 安全更新（系统补丁）
- [ ] 性能优化（分析性能瓶颈）

### 6.2 清理维护

**清理临时文件**:
```bash
# 清理临时文件
find /tmp -name "ufc_*" -mtime +7 -delete

# 清理日志（保留最近 30 天）
find /var/log/ufc -name "*.log.*" -mtime +30 -delete
```

**清理缓存**:
```bash
# 清理 UFC 缓存
rm -rf ~/.ufc/cache/*
```

**清理旧输出文件**:
```bash
# 删除 90 天前的输出文件
find /data/ufc/outputs -name "*.odb" -mtime +90 -delete
```

### 6.3 性能优化

**分析性能瓶颈**:
```bash
# 运行性能分析
ufc_profile --input=model.inp --output=profile.json

# 查看性能报告
ufc_profile --report=profile.json
```

**优化建议**:
- 调整 OpenMP 线程数
- 启用内存池优化
- 使用更高效的求解器
- 优化网格密度

---

## 7. 运维最佳实践

### 7.1 监控告警

**设置监控告警**:
```bash
# CPU 使用率 > 90%
ufc_monitor --alert=cpu --threshold=90

# 内存使用 > 80%
ufc_monitor --alert=memory --threshold=80

# 磁盘空间 < 10%
ufc_monitor --alert=disk --threshold=10
```

**告警通知**:
```bash
# 发送邮件告警
ufc_monitor --email=admin@example.com

# 发送 Slack 通知
ufc_monitor --slack-webhook=https://hooks.slack.com/...
```

### 7.2 容量规划

**评估资源需求**:
```bash
# 分析历史使用情况
ufc_analyze --resource-usage --period=30days

# 预测未来需求
ufc_analyze --forecast --period=90days
```

**扩容建议**:
- CPU: 如果平均使用率 > 70%，考虑增加 CPU
- 内存: 如果峰值使用率 > 80%，考虑增加内存
- 磁盘: 如果使用率 > 75%，考虑扩容

### 7.3 安全最佳实践

**文件权限**:
```bash
# 配置文件权限
chmod 644 /opt/ufc/etc/ufc.conf
chown root:ufc /opt/ufc/etc/ufc.conf

# 日志文件权限
chmod 640 /var/log/ufc/ufc.log
chown ufc:ufc /var/log/ufc/ufc.log
```

**网络安全**:
- 限制网络访问（如需要）
- 使用防火墙规则
- 启用 SSL/TLS（如需要）

---

## 附录

### A.1 运维检查清单

**每日**:
- [ ] 检查日志文件
- [ ] 检查系统资源
- [ ] 检查错误日志

**每周**:
- [ ] 运行性能基准测试
- [ ] 验证备份完整性
- [ ] 清理临时文件

**每月**:
- [ ] 检查版本更新
- [ ] 分析性能数据
- [ ] 更新文档

### A.2 相关文档

- `UFC_DEPLOYMENT_GUIDE.md` - 部署指南
- `UFC_PERFORMANCE_GUIDE.md` - 性能优化指南
- `UFC_CI_CD_PIPELINE.md` - CI/CD 流程文档

---

**文档状态**: Draft v1.0  
**最后更新**: 2026-03-06  
**维护者**: UFC 开发团队
