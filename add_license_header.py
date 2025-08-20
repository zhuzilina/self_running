#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
许可证头注释添加脚本
将LICENSE_HEADER_COMMENT.txt中的内容添加到所有Dart文件的顶部
"""

import os
import sys
from pathlib import Path

def read_license_header(license_file_path):
    """读取许可证头注释文件"""
    try:
        with open(license_file_path, 'r', encoding='utf-8') as f:
            return f.read().strip()
    except FileNotFoundError:
        print(f"错误：找不到许可证文件 {license_file_path}")
        sys.exit(1)
    except UnicodeDecodeError:
        print(f"错误：无法读取许可证文件 {license_file_path}，编码问题")
        sys.exit(1)

def detect_file_encoding(file_path):
    """检测文件编码"""
    encodings = ['utf-8', 'utf-8-sig', 'gbk', 'gb2312', 'latin-1']
    
    for encoding in encodings:
        try:
            with open(file_path, 'r', encoding=encoding) as f:
                f.read()
            return encoding
        except UnicodeDecodeError:
            continue
    
    # 如果都失败，返回utf-8作为默认值
    return 'utf-8'

def read_file_content(file_path):
    """读取文件内容，自动检测编码"""
    encoding = detect_file_encoding(file_path)
    try:
        with open(file_path, 'r', encoding=encoding) as f:
            return f.read(), encoding
    except Exception as e:
        print(f"警告：无法读取文件 {file_path}: {e}")
        return None, None

def write_file_content(file_path, content, encoding):
    """写入文件内容，保持原有编码"""
    try:
        with open(file_path, 'w', encoding=encoding) as f:
            f.write(content)
        return True
    except Exception as e:
        print(f"错误：无法写入文件 {file_path}: {e}")
        return False

def has_license_header(content, license_header):
    """检查文件是否已经有许可证头注释"""
    # 移除空白字符后比较
    content_clean = content.strip()
    license_clean = license_header.strip()
    
    # 检查是否以许可证头开始
    if content_clean.startswith(license_clean):
        return True
    
    # 检查是否包含许可证头的关键部分
    license_lines = license_clean.split('\n')
    if len(license_lines) > 2:
        # 检查第一行（版权声明）
        first_line = license_lines[0].strip()
        if first_line in content_clean:
            return True
    
    return False

def add_license_header_to_file(file_path, license_header):
    """为单个文件添加许可证头注释"""
    print(f"处理文件: {file_path}")
    
    # 读取文件内容
    content, encoding = read_file_content(file_path)
    if content is None:
        return False
    
    # 检查是否已经有许可证头
    if has_license_header(content, license_header):
        print(f"  跳过：文件已包含许可证头注释")
        return True
    
    # 添加许可证头注释
    # 如果文件以换行符开始，保留它
    if content.startswith('\n'):
        new_content = license_header + '\n' + content
    else:
        new_content = license_header + '\n\n' + content
    
    # 写入文件
    if write_file_content(file_path, new_content, encoding):
        print(f"  成功：已添加许可证头注释")
        return True
    else:
        print(f"  失败：无法写入文件")
        return False

def find_dart_files(root_dir):
    """查找所有Dart文件"""
    dart_files = []
    root_path = Path(root_dir)
    
    # 排除的目录
    exclude_dirs = {
        '.git', '.dart_tool', 'build', 'node_modules', 
        'target', '.idea', '.vscode', 'dist'
    }
    
    for file_path in root_path.rglob('*.dart'):
        # 检查是否在排除目录中
        if any(exclude_dir in file_path.parts for exclude_dir in exclude_dirs):
            continue
        
        dart_files.append(file_path)
    
    return dart_files

def main():
    """主函数"""
    # 获取当前目录
    current_dir = os.getcwd()
    
    # 许可证文件路径
    license_file = os.path.join(current_dir, 'LICENSE_HEADER_COMMENT.txt')
    
    print("=== Dart文件许可证头注释添加工具 ===")
    print(f"工作目录: {current_dir}")
    print(f"许可证文件: {license_file}")
    print()
    
    # 读取许可证头注释
    license_header = read_license_header(license_file)
    print("许可证头注释内容:")
    print("-" * 50)
    print(license_header)
    print("-" * 50)
    print()
    
    # 查找所有Dart文件
    dart_files = find_dart_files(current_dir)
    print(f"找到 {len(dart_files)} 个Dart文件")
    print()
    
    if not dart_files:
        print("没有找到Dart文件")
        return
    
    # 确认是否继续
    response = input("是否继续添加许可证头注释？(y/N): ").strip().lower()
    if response not in ['y', 'yes']:
        print("操作已取消")
        return
    
    # 处理文件
    success_count = 0
    skip_count = 0
    error_count = 0
    
    for file_path in dart_files:
        if add_license_header_to_file(file_path, license_header):
            success_count += 1
        else:
            error_count += 1
    
    print()
    print("=== 处理完成 ===")
    print(f"成功处理: {success_count} 个文件")
    print(f"跳过文件: {skip_count} 个文件")
    print(f"处理失败: {error_count} 个文件")
    print(f"总计文件: {len(dart_files)} 个文件")

if __name__ == "__main__":
    main()
