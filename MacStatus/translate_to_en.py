import os
import re
import json

TRANSLATIONS = {
    "通用设置": "General Settings",
    "需要维修": "Service Recommended",
    "充满": "Fully Charged",
    "高功耗应用": "High Power Apps",
    "电源": "Power",
    "显示百分比": "Show Percentage",
    "设计功率": "Design Power",
    "菜单项间距": "Menu Item Spacing",
    "关于": "About",
    "2.0 秒 (省电)": "2.0 Secs (Power Saving)",
    "正常": "Normal",
    "电池温度": "Battery Temperature",
    "仪表盘": "Dashboard",
    "应用说明": "App Features",
    "未知": "Unknown",
    "充电状态": "Charging State",
    "请选择左侧菜单": "Select a menu on the left",
    "面板关闭后会在后台自动降速为 10 秒刷新": "Refresh rate automatically drops to 10 seconds in the background when the panel is closed",
    "最大容量": "Maximum Capacity",
    "退出应用": "Quit",
    "适配器名称": "Adapter Name",
    "充电中": "Charging",
    "主图标选项": "Main Icon Options",
    "校准模式": "Calibration Mode",
    "外观": "Appearance",
    "循环": "Cycles",
    "循环次数": "Cycle Count",
    "温度": "Temperature",
    "菜单栏右击": "Menu Bar Right Click",
    "菜单更新间隔": "Menu Update Interval",
    "开发者": "Developer",
    "电流": "Current",
    "macOS 原生": "macOS Native",
    "没有高功耗的应用程序": "No Applications Using Significant Energy",
    "高功耗：": "High Power:",
    "0.5 秒 (较快)": "0.5 Secs (Fast)",
    "(选择一个)": "(Select One)",
    "实时监控 Mac 电源与电池状态的极简工具，为您提供精确的系统功耗与电池健康分析。": "A minimalist tool to monitor your Mac's power and battery status in real-time.",
    "协议": "Protocol",
    "配色方案": "Color Scheme",
    "由 SwiftUI 提供驱动。": "Powered by SwiftUI.",
    "主图标样式": "Main Icon Style",
    "仪表盘样式": "Dashboard Style",
    "设计容量": "Design Capacity",
    "全部清除": "Clear All",
    "电池电量": "Battery Level",
    "功率": "Power",
    "macOS 容量": "macOS Capacity",
    "所有小组件已添加在面板上": "All widgets added",
    "当前 PD": "Current PD",
    "外观设置": "Appearance Settings",
    "AlDente 图标": "AlDente Icon",
    "电压": "Voltage",
    "系统负载": "System Load",
    "充电协议 (Adapter)": "Charging Protocol",
    "实时能耗流向": "Real-time Energy Flow",
    "面板打开时刷新间隔": "Refresh Interval While Panel Open",
    "macOS 状态": "macOS Status",
    "不要显示": "Do Not Show",
    "macOS 条件": "macOS Condition",
    "菜单项目录": "Menu Item Directory",
    "跟随系统": "System",
    "健康度": "Health",
    "同左击": "Same as Left Click",
    "协商电压": "Negotiated Voltage",
    "版本 1.0.0 (Build 100)": "Version 1.0.0 (Build 100)",
    "0.2 秒 (极速)": "0.2 Secs (Ultra Fast)",
    "低电量模式颜色": "Low Power Mode Color",
    "选定的菜单项": "Selected Menu Items",
    "协商电流": "Negotiated Current",
    "完成": "Done",
    "刷新频率": "Refresh Rate",
    "添加小组件": "Add Widget",
    "容量": "Capacity",
    "官方网站": "Official Website",
    "满载/剩余时间": "Time until Full/Empty",
    "AlDente 状态": "AlDente Status",
    "航海模式": "Sailing Mode",
    "放电中": "Discharging",
    "菜单栏属性": "Menu Bar Properties",
    "菜单栏": "Menu Bar",
    "电池核心数据": "Battery Core Data",
    "通用": "General",
    "桑基图能量流 (已启用)": "Sankey Power Flow (Enabled)",
    "电池规格": "Battery Specs",
    "电池健康": "Battery Health",
    "电源适配器规格": "Power Adapter Specs",
    "1.0 秒 (正常)": "1.0 Secs (Normal)",
    "重置": "Reset",
    "过热保护": "Overheat Protection",
    "剩余容量": "Remaining Capacity",
    "当前": "Current",
    "链接与支持": "Links & Support",
    "已暂停": "Suspended",
    "未连接": "Not Connected",
    "开启": "On",
    "关闭": "Off",
    "无连接": "Not Connected",
    "健康": "Good",
    "建议维修": "Service Recommended"
}

source_dir = "/Users/kristoff/Documents/GitHub/mac-status/MacStatus/MacStatus"
xcstrings_path = os.path.join(source_dir, "Localizable.xcstrings")

def replace_in_swift_files():
    for root, _, files in os.walk(source_dir):
        for file in files:
            if file.endswith(".swift"):
                filepath = os.path.join(root, file)
                with open(filepath, "r", encoding="utf-8") as f:
                    content = f.read()

                new_content = content
                for zh, en in TRANSLATIONS.items():
                    # Replace occurrences of "zh" with "en"
                    pattern = f'"{zh}"'
                    replacement = f'"{en}"'
                    new_content = new_content.replace(pattern, replacement)
                
                if new_content != content:
                    with open(filepath, "w", encoding="utf-8") as f:
                        f.write(new_content)
                    print(f"Updated: {file}")

def update_xcstrings():
    if not os.path.exists(xcstrings_path):
        print("Localizable.xcstrings not found!")
        return

    with open(xcstrings_path, "r", encoding="utf-8") as f:
        try:
            data = json.load(f)
        except json.JSONDecodeError:
            print("Invalid JSON in xcstrings.")
            return

    # Set source language to english
    data["sourceLanguage"] = "en"
    
    if "strings" not in data:
        data["strings"] = {}

    # Clear old strings if we want to reset, or just map the new ones
    new_strings = {}
    
    # We populate strings with English as key, localized zh-Hans as value
    for zh, en in TRANSLATIONS.items():
        if en not in new_strings:
            new_strings[en] = {
                "extractionState": "manual",
                "localizations": {
                    "zh-Hans": {
                        "stringUnit": {
                            "state": "translated",
                            "value": zh
                        }
                    }
                }
            }
    
    # Check if there are other keys in data["strings"] we should keep
    for orig_key, orig_val in data["strings"].items():
        if orig_key not in new_strings:
            new_strings[orig_key] = orig_val

    data["strings"] = new_strings

    with open(xcstrings_path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print("Updated Localizable.xcstrings")

if __name__ == "__main__":
    print("Starting exact replacements...")
    replace_in_swift_files()
    update_xcstrings()
    print("Done!")
