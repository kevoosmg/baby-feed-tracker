# 宝宝喂奶记录 - 华为手表版

基于 HarmonyOS ArkTS 开发，专为 Huawei Watch 5 设计的手表原生应用。

## 功能

- 👶 大宝/小宝切换
- ⏱️ 环形倒计时可视化（2.5 小时间隔）
- 🍼 奶粉/母乳/亲喂 类型选择
- 📊 预设喂养量 + 手动调节
- 💊 维生素 AD/D3 标记
- ☁️ Supabase 云端同步（与手机版数据互通）
- 📡 离线降级（无网络时本地缓存，联网后同步）

## 环境准备

### 1. 下载 DevEco Studio

前往 [华为开发者官网](https://developer.huawei.com/consumer/cn/download/) 下载 **DevEco Studio 5.1.0+**

### 2. 安装 HarmonyOS SDK

DevEco Studio 首次启动会自动提示安装 SDK，选择 API 11+ 版本即可。

### 3. 登录华为开发者账号

在 DevEco Studio 中登录你的华为账号（设置 → 华为开发者联盟）

## 导入项目

1. 打开 DevEco Studio
2. 选择 **Open** → 选择 `BabyFeedTracker` 文件夹
3. 等待项目同步完成（Gradle/Hvigor 会自动下载依赖）

## 连接手表

### 开启开发者模式

在手表上操作：
1. **设置 → 关于 → 软件版本**
2. 连续点击 **版本号** 7 次，开启开发者选项
3. 在 **开发者选项** 中开启：
   - ✅ **HDC 调试**
   - ✅ **通过 Wi-Fi 调试**（会显示 IP 地址和端口）

### 连接 DevEco Studio

1. 确保电脑和手表在 **同一 Wi-Fi** 网络
2. 在 DevEco Studio 中：**Tools → IP Connection**
3. 输入手表显示的 **IP 地址和端口**
4. 点击 **Connect**

## 运行

1. 顶部设备下拉选择 **已连接的手表**
2. 点击 **Run ▶** 按钮
3. 首次运行需要签名，DevEco Studio 自动处理

应用中会看到「喂奶记录」图标，点击即可使用。

## 项目结构

```
BabyFeedTracker/
├── build-profile.json5        # 工程级构建配置 (API 11)
├── hvigorfile.ts              # 构建入口
├── oh-package.json5            # 工程依赖
├── entry/
│   ├── build-profile.json5    # 模块级构建配置
│   ├── hvigorfile.ts
│   ├── oh-package.json5
│   └── src/main/
│       ├── module.json5        # 模块配置 (权限、设备类型)
│       ├── ets/
│       │   ├── entryability/
│       │   │   └── EntryAbility.ets  # 应用入口
│       │   ├── pages/
│       │   │   └── Index.ets         # 主界面
│       │   └── utils/
│       │       └── SupabaseClient.ets # Supabase HTTP 客户端
│       └── resources/
│           └── base/
│               ├── element/          # 颜色/字符串资源
│               └── profile/
│                   └── main_pages.json
```

## Supabase 配置

应用已内置 Supabase 配置，无需额外设置。如需更换为自己的 Supabase 项目，修改 `entry/src/main/ets/utils/SupabaseClient.ets` 中的 `SUPABASE_URL` 和 `SUPABASE_KEY`。

## 技术栈

- **框架**: HarmonyOS ArkUI (Stage Model)
- **语言**: ArkTS
- **网络**: @ohos.net.http (直接调用 Supabase REST API)
- **本地存储**: @ohos.data.preferences
- **目标 API**: 11 (HarmonyOS 4.0+)
