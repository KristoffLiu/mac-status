import os, re, json

directory = "/Users/kristoff/Documents/GitHub/mac-status/MacStatus/MacStatus"
strings = set()

# Matches things like Text("Refresh"), .navigationTitle("Settings"), Label("Text", systemImage: "x")
pattern1 = re.compile(r'\b(?:Text|LocalizedStringKey|navigationTitle)\s*\(\s*"([^"]+)"\s*\)')
pattern2 = re.compile(r'Label\s*\(\s*"([^"]+)"')
pattern3 = re.compile(r'Picker\s*\(\s*"([^"]+)"')
pattern4 = re.compile(r'Toggle\s*\(\s*"([^"]+)"')

for root, _, files in os.walk(directory):
    for f in files:
        if f.endswith(".swift"):
            with open(os.path.join(root, f), "r") as file:
                content = file.read()
                for p in [pattern1, pattern2, pattern3, pattern4]:
                    matches = p.findall(content)
                    for m in matches:
                        strings.add(m)

translations = {
    "MacStatus": "MacStatus",
    "完成": "Done",
    "添加小组件": "Add Widget",
    "所有小组件已添加在面板上": "All widgets added",
    "没有高功耗的应用程序": "No items using significant energy",
    "高功耗：": "High Energy Impact:",
    "充电协议 (Adapter)": "Charging Protocol (Adapter)",
    "0.2 秒 (极速)": "0.2s (Fastest)",
    "0.5 秒 (较快)": "0.5s (Fast)",
    "1.0 秒 (正常)": "1.0s (Normal)",
    "2.0 秒 (省电)": "2.0s (Power Saving)",
    "面板关闭后会在后台自动降速为 10 秒刷新": "Background refresh scales down to 10s when panel is closed",
    "版本 1.0.0 (Build 100)": "Version 1.0.0 (Build 100)",
    "实时监控 Mac 电源与电池状态的极简工具，为您提供精确的系统功耗与电池健康分析。": "A minimalist tool to monitor Mac power and battery status in real-time, providing precise system energy usage and battery health analysis.",
    "© 2024 Kristoff. All rights reserved.": "© 2024 Kristoff. All rights reserved.",
    "由 SwiftUI 提供驱动。": "Powered by SwiftUI.",
    "选定的菜单项": "Selected Menu Items",
    "32°C": "32°C",
    "15.2W": "15.2W",
    "12.4V": "12.4V",
    "1.2A": "1.2A",
    "菜单项目录": "Menu Item Directory",
    "显示百分比": "Show Percentage",
    "低电量模式颜色": "Low Power Mode Color",
    "最大容量": "Maximum Capacity",
    "macOS 容量": "macOS Capacity",
    "macOS 条件": "macOS Condition",
    "循环": "Cycles",
    "温度": "Temperature",
    "满载/剩余时间": "Time Remaining",
    "当前": "Current",
    "电压": "Voltage",
    "电源": "Power",
    "系统负载": "System Load",
    "校准模式": "Calibration Mode",
    "过热保护": "Heat Protection",
    "航海模式": "Sailing Mode",
    "充满": "Fully Charged",
    "重置": "Reset",
    "全部清除": "Clear All",
    "菜单项间距": "Menu Item Spacing",
    "常规": "General",
    "关于": "About",
    "电源状态": "Power Status",
    "电池健康": "Battery Health",
    "MacStatus 设置": "MacStatus Settings",
    "刷新频率": "Refresh Rate",
    "电池图标状态：": "Battery Icon Status:",
    "电量": "Capacity",
    "状态": "Status",
    "来源": "Power Source",
    "容量信息": "Capacity Info",
    "健康度": "Health",
    "循环次数": "Cycle Count",
    "最大载荷": "Design Capacity"
}

# Auto-add missing translations with a placeholder flag if any
for s in strings:
    if s not in translations:
        # Ignore interpolations or empty strings for simple map
        if "\\(" in s or not s:
            continue
        translations[s] = s  # default fallback

# Now build the xcstrings mapping
xcstrings_path = "/Users/kristoff/Documents/GitHub/mac-status/MacStatus/MacStatus/Localizable.xcstrings"

# Read existing or create new
data = {
    "sourceLanguage" : "zh-Hans",
    "strings" : {},
    "version" : "1.0"
}

for zh_key, en_value in translations.items():
    data["strings"][zh_key] = {
        "extractionState" : "manual",
        "localizations" : {
            "en" : {
                "stringUnit" : {
                    "state" : "translated",
                    "value" : en_value
                }
            }
        }
    }

with open(xcstrings_path, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print("Updated Localizable.xcstrings successfully!")
