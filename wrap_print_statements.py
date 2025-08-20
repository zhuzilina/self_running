#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Dart文件print语句包装脚本
将所有print语句包装在assert(() { print("调试信息"); return true; }());中
"""

import os
import sys
import re
from pathlib import Path

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

def is_already_wrapped(print_statement):
    """检查print语句是否已经被assert包装"""
    # 检查是否已经被assert包装
    if re.match(r'^\s*assert\s*\(\s*\(\s*\)\s*\{', print_statement.strip()):
        return True
    return False

def wrap_print_statement(match):
    """包装单个print语句"""
    print_statement = match.group(0)
    
    # 如果已经被包装，直接返回
    if is_already_wrapped(print_statement):
        return print_statement
    
    # 获取print语句的缩进
    indent_match = re.match(r'^(\s*)', print_statement)
    indent = indent_match.group(1) if indent_match else ''
    
    # 包装print语句
    wrapped = f'{indent}assert(() {{\n{indent}  {print_statement.strip()}\n{indent}  return true;\n{indent}}}());'
    
    return wrapped

def process_dart_file(file_path):
    """处理单个Dart文件"""
    print(f"处理文件: {file_path}")
    
    # 读取文件内容
    content, encoding = read_file_content(file_path)
    if content is None:
        return False
    
    # 查找所有print语句
    # 匹配print语句，包括多行的情况
    print_pattern = r'^\s*print\s*\([^)]*\);'
    
    # 使用多行模式匹配
    matches = list(re.finditer(print_pattern, content, re.MULTILINE))
    
    if not matches:
        print(f"  跳过：没有找到print语句")
        return True
    
    print(f"  找到 {len(matches)} 个print语句")
    
    # 从后往前替换，避免位置偏移问题
    new_content = content
    for match in reversed(matches):
        start, end = match.span()
        original = new_content[start:end]
        wrapped = wrap_print_statement(match)
        
        # 如果内容没有变化，跳过
        if original == wrapped:
            continue
            
        new_content = new_content[:start] + wrapped + new_content[end:]
    
    # 如果内容没有变化，跳过写入
    if new_content == content:
        print(f"  跳过：所有print语句都已经被包装或无需包装")
        return True
    
    # 写入文件
    if write_file_content(file_path, new_content, encoding):
        print(f"  成功：已包装 {len(matches)} 个print语句")
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
        'target', '.idea', '.vscode', 'dist', 'generated'
    }
    
    for file_path in root_path.rglob('*.dart'):
        # 检查是否在排除目录中
        if any(exclude_dir in file_path.parts for exclude_dir in exclude_dirs):
            continue
        
        dart_files.append(file_path)
    
    return dart_files

def preview_changes(file_path):
    """预览文件中的print语句"""
    content, _ = read_file_content(file_path)
    if content is None:
        return []
    
    print_pattern = r'^\s*print\s*\([^)]*\);'
    matches = list(re.finditer(print_pattern, content, re.MULTILINE))
    
    changes = []
    for match in matches:
        original = match.group(0)
        if not is_already_wrapped(original):
            wrapped = wrap_print_statement(match)
            changes.append((original.strip(), wrapped.strip()))
    
    return changes

def main():
    """主函数"""
    # 获取当前目录
    current_dir = os.getcwd()
    
    print("=== Dart文件print语句包装工具 ===")
    print(f"工作目录: {current_dir}")
    print("将把所有print语句包装在assert(() { print(...); return true; }());中")
    print()
    
    # 查找所有Dart文件
    dart_files = find_dart_files(current_dir)
    print(f"找到 {len(dart_files)} 个Dart文件")
    print()
    
    if not dart_files:
        print("没有找到Dart文件")
        return
    
    # 预览模式
    preview_mode = input("是否先预览更改？(y/N): ").strip().lower()
    if preview_mode in ['y', 'yes']:
        print("\n=== 预览模式 ===")
        total_changes = 0
        
        for file_path in dart_files:
            changes = preview_changes(file_path)
            if changes:
                print(f"\n文件: {file_path}")
                print(f"需要包装 {len(changes)} 个print语句:")
                for i, (original, wrapped) in enumerate(changes, 1):
                    print(f"  {i}. 原始: {original}")
                    print(f"     包装: {wrapped}")
                    print()
                total_changes += len(changes)
        
        print(f"总计需要包装 {total_changes} 个print语句")
        print()
        
        if total_changes == 0:
            print("没有需要包装的print语句")
            return
    
    # 确认是否继续
    response = input("是否继续包装print语句？(y/N): ").strip().lower()
    if response not in ['y', 'yes']:
        print("操作已取消")
        return
    
    # 处理文件
    success_count = 0
    skip_count = 0
    error_count = 0
    total_wrapped = 0
    
    for file_path in dart_files:
        if process_dart_file(file_path):
            success_count += 1
            # 统计包装的语句数量
            content, _ = read_file_content(file_path)
            if content:
                print_pattern = r'^\s*print\s*\([^)]*\);'
                matches = list(re.finditer(print_pattern, content, re.MULTILINE))
                for match in matches:
                    if not is_already_wrapped(match.group(0)):
                        total_wrapped += 1
        else:
            error_count += 1
    
    print()
    print("=== 处理完成 ===")
    print(f"成功处理: {success_count} 个文件")
    print(f"跳过文件: {skip_count} 个文件")
    print(f"处理失败: {error_count} 个文件")
    print(f"总计文件: {len(dart_files)} 个文件")
    print(f"包装的print语句: {total_wrapped} 个")

if __name__ == "__main__":
    main()
