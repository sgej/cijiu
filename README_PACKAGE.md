# MineRadio iOS 打包指南

## 目录
1. [环境准备](#环境准备)
2. [Apple 开发者账号配置](#apple-开发者账号配置)
3. [证书和描述文件配置](#证书和描述文件配置)
4. [Xcode 项目配置](#xcode-项目配置)
5. [自动打包脚本使用](#自动打包脚本使用)
6. [手动打包步骤](#手动打包步骤)
7. [常见签名错误及解决方法](#常见签名错误及解决方法)
8. [IPA 安装和测试](#ipa-安装和测试)

---

## 环境准备

### 1.1 系统要求
- **操作系统**: macOS 12.0 (Monterey) 或更高版本
- **Xcode**: 14.0 或更高版本
- **iOS**: 14.0 或更高版本（目标设备）

### 1.2 安装 Xcode
1. 从 Mac App Store 下载并安装 Xcode
2. 首次启动 Xcode，同意许可协议
3. 安装命令行工具：
   ```bash
   xcode-select --install
   ```

### 1.3 验证安装
```bash
# 检查 Xcode 版本
xcodebuild -version

# 检查命令行工具
xcode-select -p
```

---

## Apple 开发者账号配置

### 2.1 账号类型

| 账号类型 | 费用 | 功能 | 适用场景 |
|---------|------|------|---------|
| 个人开发者 | $99/年 | App Store 发布、TestFlight、最多100台设备测试 | 个人开发者 |
| 公司开发者 | $99/年 | 个人版所有功能 + 团队协作 | 小型团队 |
| 企业开发者 | $299/年 | 企业内部分发，无需 App Store 审核 | 大型企业内部应用 |
| 免费账号 | 免费 | 仅能在自己的设备上测试，7天后失效 | 学习、试用 |

### 2.2 注册开发者账号

#### 个人/公司账号
1. 访问 [Apple Developer 网站](https://developer.apple.com/)
2. 点击 "Account" 登录你的 Apple ID
3. 按照提示完成注册流程
4. 支付年费
5. 等待审核通过（通常1-3个工作日）

#### 企业账号
1. 需要企业邓白氏编码 (D-U-N-S Number)
2. 访问 [Apple Developer Enterprise Program](https://developer.apple.com/programs/enterprise/)
3. 按照提示完成注册
4. 支付年费 $299
5. 等待审核通过

### 2.3 登录 Xcode
1. 打开 Xcode
2. 菜单栏选择 `Xcode` → `Settings...` (或 `Preferences...`)
3. 选择 `Accounts` 标签页
4. 点击左下角 `+` 号
5. 选择 `Apple ID`
6. 输入你的开发者账号和密码
7. 等待账号加载完成

---

## 证书和描述文件配置

### 3.1 证书类型

| 证书类型 | 用途 | 说明 |
|---------|------|------|
| Development Certificate | 开发调试 | 用于开发阶段在设备上调试 |
| Distribution Certificate | 发布分发 | 用于提交 App Store 或 Ad-Hoc 分发 |
| Push Certificate | 推送通知 | 用于 Apple Push Notification 服务 |

### 3.2 自动签名（推荐）

Xcode 支持自动管理签名，这是最简单的方式：

1. 在 Xcode 中打开项目
2. 选择项目文件（最左侧导航栏顶部）
3. 选择 `Signing & Capabilities` 标签页
4. 勾选 `Automatically manage signing`
5. 选择你的 Team
6. Xcode 会自动生成和管理证书、描述文件

> 💡 **优点**: 简单方便，无需手动管理证书
> 
> ⚠️ **注意**: 需要有效的开发者账号

### 3.3 手动签名

如果需要更精细的控制，可以使用手动签名：

#### 步骤1：生成 Certificate Signing Request (CSR)
1. 打开 `钥匙串访问` (Keychain Access)
2. 菜单栏选择 `钥匙串访问` → `证书助理` → `从证书颁发机构请求证书...`
3. 填写你的邮箱和常用名称
4. 选择 `存储到磁盘`
5. 保存 `.certSigningRequest` 文件

#### 步骤2：在开发者网站创建证书
1. 登录 [Apple Developer Center](https://developer.apple.com/account/)
2. 进入 `Certificates, Identifiers & Profiles`
3. 点击 `Certificates` → `+`
4. 选择证书类型（Development 或 Distribution）
5. 上传刚才生成的 CSR 文件
6. 下载生成的证书（`.cer` 文件）
7. 双击下载的证书，导入到钥匙串中

#### 步骤3：创建 App ID
1. 在开发者网站点击 `Identifiers` → `+`
2. 选择 `App IDs` → `Continue`
3. 选择 `App` → `Continue`
4. 填写 Description 和 Bundle ID
   - Bundle ID 格式: `com.company.appname`
   - 例如: `com.mineradio.ios`
5. 勾选需要的 Capabilities（如 Push Notifications 等）
6. 点击 `Continue` → `Register`

#### 步骤4：注册测试设备（Development/Ad-Hoc）
1. 连接设备到 Mac
2. 打开 Xcode → `Window` → `Devices and Simulators`
3. 找到设备，复制 `Identifier` (UDID)
4. 在开发者网站点击 `Devices` → `+`
5. 填写设备名称和 UDID
6. 点击 `Continue` → `Register`

> ⚠️ **注意**: 个人/公司账号最多只能注册 100 台设备

#### 步骤5：创建描述文件 (Provisioning Profile)
1. 在开发者网站点击 `Profiles` → `+`
2. 选择描述文件类型：
   - **iOS App Development**: 开发调试用
   - **Ad Hoc**: 内部分发测试
   - **App Store**: 提交 App Store
   - **In-House**: 企业内部分发（企业账号）
3. 选择对应的 App ID → `Continue`
4. 选择证书 → `Continue`
5. 选择设备（Development/Ad-Hoc 需要）→ `Continue`
6. 填写描述文件名称 → `Generate`
7. 下载描述文件（`.mobileprovision` 文件）
8. 双击下载的描述文件，Xcode 会自动安装

---

## Xcode 项目配置

### 4.1 打开项目
1. 双击 `MineRadio.xcodeproj` 打开项目
2. 等待 Xcode 加载完成

### 4.2 基本配置

#### 修改 Bundle ID
1. 选择项目文件 → `Signing & Capabilities`
2. 修改 `Bundle Identifier` 为你自己的
   - 例如: `com.yourcompany.mineradio`

> ⚠️ **重要**: Bundle ID 必须与你在开发者网站注册的一致

#### 配置签名
1. 选择 `Signing & Capabilities` 标签页
2. 勾选 `Automatically manage signing`（推荐）
3. 选择你的 Team
4. 等待 Xcode 自动配置完成

#### 配置版本号
1. 在 `General` 标签页中
2. `Version`: 应用版本号，如 `1.1.4`
3. `Build`: 构建号，每次打包递增，如 `1`

### 4.3 配置 Capabilities

根据需要添加以下功能：

| 功能 | 说明 | 是否必需 |
|------|------|---------|
| Background Modes | 后台播放音频 | ✅ 必需 |
| Access WiFi Information | WiFi 信息访问 | ❌ 可选 |
| Camera | 相机权限（手势识别） | ⚠️ 手势识别需要 |
| Photo Library | 相册权限 | ⚠️ 背景图片需要 |

**添加步骤**:
1. 在 `Signing & Capabilities` 标签页
2. 点击 `+ Capability`
3. 搜索并添加需要的功能

### 4.4 配置 Info.plist

项目已包含基本的 Info.plist 配置，根据需要修改：

```xml
<!-- 相机权限说明 -->
<key>NSCameraUsageDescription</key>
<string>需要访问相机用于手势识别功能</string>

<!-- 相册权限说明 -->
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册用于选择背景图片</string>

<!-- 麦克风权限说明 -->
<key>NSMicrophoneUsageDescription</key>
<string>需要访问麦克风用于手势识别功能</string>
```

> 💡 **提示**: 权限说明文字要清晰描述用途，否则 App Store 审核可能被拒

---

## 自动打包脚本使用

### 5.1 脚本说明

项目提供了 `build_ipa.sh` 自动打包脚本，支持以下导出方式：

| 导出方式 | 参数 | 说明 |
|---------|------|------|
| 开发版 | `development` | 开发测试用，需要注册设备 |
| Ad-Hoc版 | `ad-hoc` | 内部分发测试，需要注册设备 |
| App Store版 | `app-store` | 提交 App Store 审核 |
| 企业版 | `enterprise` | 企业内部分发（企业账号） |

### 5.2 使用方法

#### 1. 给脚本添加执行权限
```bash
chmod +x build_ipa.sh
```

#### 2. 运行打包脚本
```bash
# 开发版
./build_ipa.sh development

# Ad-Hoc版
./build_ipa.sh ad-hoc

# App Store版
./build_ipa.sh app-store

# 企业版
./build_ipa.sh enterprise
```

### 5.3 输出文件

打包完成后，会在 `build/` 目录生成：

```
build/
├── MineRadio.xcarchive/    # 归档文件
├── ipa/
│   └── MineRadio.ipa       # IPA 安装包
└── exportOptions.plist     # 导出配置
```

### 5.4 脚本配置

可以修改脚本开头的配置项：

```bash
# Scheme名称
SCHEME="MineRadio"

# 配置类型 (Debug/Release)
CONFIGURATION="Release"

# 输出目录
OUTPUT_DIR="./build"
```

---

## 手动打包步骤

### 6.1 Archive 归档

#### 方法一：Xcode 界面操作

1. 打开 Xcode 项目
2. 选择目标设备为 `Any iOS Device (arm64)`
   - 或者连接真机，选择真机
3. 菜单栏选择 `Product` → `Archive`
4. 等待编译和归档完成
5. 归档完成后会自动弹出 Organizer 窗口

#### 方法二：命令行
```bash
xcodebuild archive \
    -project MineRadio.xcodeproj \
    -scheme MineRadio \
    -configuration Release \
    -archivePath build/MineRadio.xcarchive \
    -destination "generic/platform=iOS"
```

### 6.2 导出 IPA

#### 方法一：Xcode Organizer

1. 在 Organizer 窗口中选择刚才的归档
2. 点击 `Distribute App`
3. 选择分发方式：
   - **App Store Connect**: 提交到 App Store
   - **Ad Hoc**: 内部分发
   - **Development**: 开发测试
   - **Enterprise**: 企业分发
4. 点击 `Next`
5. 选择签名方式（推荐 Automatically manage signing）
6. 点击 `Next`
7. 确认信息后点击 `Export`
8. 选择保存位置，等待导出完成

#### 方法二：命令行

1. 创建 `exportOptions.plist` 配置文件：
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>method</key>
       <string>ad-hoc</string>
       <key>signingStyle</key>
       <string>automatic</string>
       <key>stripSwiftSymbols</key>
       <true/>
       <key>teamID</key>
       <string>YOUR_TEAM_ID</string>
   </dict>
   </plist>
   ```

2. 执行导出命令：
   ```bash
   xcodebuild -exportArchive \
       -archivePath build/MineRadio.xcarchive \
       -exportPath build/ipa \
       -exportOptionsPlist exportOptions.plist
   ```

---

## 常见签名错误及解决方法

### 7.1 证书相关错误

#### 错误：No signing certificate "iOS Development" found
**原因**: 没有找到开发证书

**解决方法**:
1. 检查 Xcode → Settings → Accounts 中是否登录了开发者账号
2. 检查是否勾选了 `Automatically manage signing`
3. 尝试手动刷新配置：
   ```bash
   # 清理缓存
   rm -rf ~/Library/MobileDevice/Provisioning\ Profiles
   ```
4. 重新在开发者网站生成证书

#### 错误：Certificate has expired
**原因**: 证书已过期

**解决方法**:
1. 登录 Apple Developer 网站
2. 撤销过期的证书
3. 重新生成新的证书
4. 下载并安装新证书

#### 错误：Private key not found
**原因**: 证书的私钥不在钥匙串中

**解决方法**:
1. 检查钥匙串中是否有对应的私钥
2. 如果没有，需要重新生成 CSR 并重新创建证书
3. 或者从其他 Mac 导出证书（包含私钥）并导入

> 💡 **建议**: 备份你的证书和私钥，保存到安全的地方

### 7.2 描述文件相关错误

#### 错误：Provisioning profile doesn't match
**原因**: 描述文件与 Bundle ID 或证书不匹配

**解决方法**:
1. 检查 Bundle ID 是否与描述文件中的一致
2. 检查描述文件是否包含正确的证书
3. 重新生成描述文件
4. 删除旧的描述文件：
   ```bash
   rm -rf ~/Library/MobileDevice/Provisioning\ Profiles
   ```

#### 错误：Device not registered
**原因**: 设备 UDID 没有添加到描述文件中

**解决方法**:
1. 在开发者网站添加设备 UDID
2. 更新描述文件，添加新设备
3. 重新下载并安装描述文件

### 7.3 Bundle ID 相关错误

#### 错误：Bundle ID 已被使用
**原因**: Bundle ID 已经被其他开发者注册

**解决方法**:
1. 修改 Bundle ID 为唯一值
2. 通常使用反向域名格式：`com.yourcompany.appname`
3. 在开发者网站注册新的 Bundle ID

#### 错误：No App ID found
**原因**: 开发者账号中没有对应的 App ID

**解决方法**:
1. 登录 Apple Developer 网站
2. 创建新的 App ID
3. 确保 Bundle ID 与 Xcode 中的一致

### 7.4 其他常见错误

#### 错误：Code signing is required
**原因**: 没有配置签名

**解决方法**:
1. 在 Xcode 中配置签名
2. 选择 Team
3. 勾选 Automatically manage signing

#### 错误：Architecture not supported
**原因**: 架构不支持

**解决方法**:
1. 检查 Build Settings → Architectures
2. 确保包含 arm64
3. 对于真机，不要包含模拟器架构 (x86_64, arm64-simulator)

#### 错误：Build Failed - 编译错误
**原因**: 代码编译失败

**解决方法**:
1. 查看 Xcode 中的错误信息
2. 检查是否缺少依赖
3. 检查 Swift 版本兼容性
4. 清理构建缓存：
   ```bash
   # 清理构建缓存
   xcodebuild clean
   
   # 清理派生数据
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```

### 7.5 导出 IPA 时的错误

#### 错误：IPA 安装失败
**可能原因**:
1. 设备 UDID 不在描述文件中
2. 证书已过期
3. 设备系统版本过低
4. IPA 损坏

**排查方法**:
1. 检查设备是否已注册
2. 检查证书和描述文件是否有效
3. 检查设备系统版本是否满足要求
4. 重新导出 IPA

#### 错误：App Store 提交被拒
**常见原因**:
1. 权限说明不清晰
2. 功能不完整
3. 存在私有 API 调用
4. 用户界面不符合设计规范

**解决方法**:
1. 仔细阅读苹果的审核指南
2. 完善权限说明文字
3. 确保所有功能正常工作
4. 避免使用私有 API

---

## IPA 安装和测试

### 8.1 通过 Xcode 安装
1. 连接设备到 Mac
2. 打开 Xcode → `Window` → `Devices and Simulators`
3. 选择设备
4. 点击 `+` 号或拖拽 IPA 文件到已安装应用列表
5. 等待安装完成

### 8.2 通过 Apple Configurator 安装
1. 下载并安装 [Apple Configurator 2](https://apps.apple.com/app/apple-configurator-2/id1037126344)
2. 连接设备到 Mac
3. 打开 Apple Configurator 2
4. 选择设备
5. 点击 `添加` → `应用`
6. 选择 IPA 文件
7. 等待安装完成

### 8.3 通过 TestFlight 测试
1. 使用 App Store 方式打包
2. 上传到 App Store Connect
3. 创建 TestFlight 测试组
4. 添加测试员邮箱
5. 测试员通过 TestFlight 应用安装

### 8.4 通过第三方分发平台
- **蒲公英** (pgyer.com)
- **FIR.im**
- **TestFlight** (官方推荐)

> ⚠️ **注意**: 使用第三方平台需要注意数据安全和合规性

---

## 九、无 Mac 云端打包指南

如果你没有 Mac 电脑，可以使用云端 CI/CD 服务来打包 IPA。以下是详细的操作指南。

### 9.1 GitHub Actions 打包（推荐）

项目已内置 GitHub Actions 自动打包配置，只需将代码推送到 GitHub 即可自动构建。

#### 步骤 1：注册 GitHub 账号
1. 访问 [github.com](https://github.com/)
2. 点击 "Sign up" 注册账号
3. 按照提示完成注册（免费账号即可）

#### 步骤 2：创建新仓库
1. 登录 GitHub
2. 点击右上角 `+` → `New repository`
3. 填写仓库名称，例如 `MineRadio-iOS`
4. 选择 `Public` 或 `Private`
   - **Public**: 无限构建分钟数（推荐）
   - **Private**: 每月 2000 分钟免费额度
5. 不要勾选 "Initialize this repository with..."
6. 点击 `Create repository`

#### 步骤 3：推送代码到 GitHub

在你的电脑上打开终端，进入项目目录：

```bash
# 进入项目目录
cd MineRadio-iOS

# 初始化 Git 仓库
git init

# 添加所有文件
git add .

# 提交代码
git commit -m "Initial commit"

# 添加远程仓库（替换为你的仓库地址）
git remote add origin https://github.com/你的用户名/MineRadio-iOS.git

# 推送到 main 分支
git branch -M main
git push -u origin main
```

> 💡 **提示**: 如果是 Windows 电脑，可以使用 GitHub Desktop 图形化工具，更简单易用。

#### 步骤 4：触发构建

**方式一：自动触发**
- 代码推送到 main 分支后会自动触发构建
- 可以在仓库的 `Actions` 标签页查看构建状态

**方式二：手动触发**
1. 进入仓库页面
2. 点击 `Actions` 标签
3. 左侧选择 `Build iOS IPA`
4. 点击 `Run workflow`
5. 选择配置选项：
   - **Build Configuration**: Release（推荐）
   - **Export Method**: unsigned（未签名，无需证书）
6. 点击 `Run workflow`

#### 步骤 5：下载构建产物

1. 等待构建完成（约 5-10 分钟）
2. 点击进入构建详情页
3. 滚动到页面底部 `Artifacts` 部分
4. 下载以下文件：
   - `MineRadio-IPA` - IPA 安装包
   - `MineRadio-XCArchive` - Xcode 归档文件（可选）

#### 步骤 6：配置签名（可选）

如果你有开发者证书，可以配置 Secrets 实现自动签名：

1. 进入仓库 `Settings` → `Secrets and variables` → `Actions`
2. 点击 `New repository secret`
3. 添加以下 Secrets：

| Secret 名称 | 说明 |
|------------|------|
| `IOS_CODE_SIGN_IDENTITY` | Base64 编码的 .p12 证书文件 |
| `IOS_PROVISIONING_PROFILE` | Base64 编码的 .mobileprovision 文件 |
| `KEYCHAIN_PASSWORD` | 钥匙串密码（自定义） |

**生成 Base64 编码的方法**（在 Mac 上执行）：
```bash
# 证书文件转 Base64
base64 -i certificate.p12 -o certificate_base64.txt

# 描述文件转 Base64
base64 -i profile.mobileprovision -o profile_base64.txt
```

---

### 9.2 其他云端打包方案

除了 GitHub Actions，还有以下云端打包服务可选：

| 方案 | 免费额度 | 难度 | 推荐指数 |
|------|---------|------|---------|
| **GitHub Actions** | 公开仓库无限 | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Codemagic** | 每月 500 分钟 | ⭐ | ⭐⭐⭐⭐ |
| **Appcircle** | 每月 30 分钟 | ⭐⭐ | ⭐⭐⭐ |
| **Bitrise** | 每月 300 分钟 | ⭐⭐ | ⭐⭐⭐ |

详细对比请查看 `docs/CloudBuildOptions.md`。

---

### 9.3 未签名 IPA 安装方案

云端打包生成的未签名 IPA 无法直接安装到 iPhone，需要通过以下方式处理：

#### 方案一：TrollStore（推荐，永久签名）

**支持系统**: iOS 14.0 - 16.6.1

**优点**:
- ✅ 永久签名，不会过期
- ✅ 无需电脑，手机端操作
- ✅ 无需越狱
- ✅ 完全免费

**缺点**:
- ❌ 有系统版本限制
- ❌ 需要安装 TrollStore

**安装步骤**:

##### 第一步：检查设备是否支持
1. 打开 iPhone 的「设置」→「通用」→「关于本机」
2. 查看 iOS 版本
3. 确保版本在 14.0 - 16.6.1 之间

##### 第二步：安装 TrollStore

**方法 A：通过 TrollHelper（推荐）**
1. 用 Safari 访问 [api.jailbreaks.app](https://api.jailbreaks.app/)
2. 点击安装 TrollHelper
3. 等待安装完成
4. 打开 TrollHelper
5. 点击 "Install TrollStore"
6. 等待安装完成后重启手机

**方法 B：通过 Sideloadly**
1. 在电脑上下载 [Sideloadly](https://sideloadly.io/)
2. 下载 TrollStore IPA
3. 用 Sideloadly 签名并安装到手机
4. 打开 TrollStore 进行安装

> 💡 **提示**: 具体安装方法可能随系统版本变化，建议搜索最新的 TrollStore 安装教程。

##### 第三步：用 TrollStore 安装 IPA
1. 将 IPA 文件传输到 iPhone
   - 可以通过 AirDrop、文件 App、网盘等方式
2. 在 iPhone 上找到 IPA 文件
3. 点击分享按钮
4. 选择「用 TrollStore 打开」
5. 等待安装完成
6. 回到桌面即可看到应用图标
7. 点击即可打开使用

> ✅ **重要**: 通过 TrollStore 安装的应用是永久签名的，不会过期，可以正常使用所有功能。

#### 方案二：免费 Apple ID 签名（7天过期）

**支持系统**: 所有 iOS 版本

**优点**:
- ✅ 官方方式，安全可靠
- ✅ 所有系统版本都支持
- ✅ 完全免费

**缺点**:
- ❌ 7 天后过期，需要重新签名
- ❌ 需要电脑操作
- ❌ 每个 Apple ID 最多同时安装 3 个应用

**推荐工具**:
- **Sideloadly** (Windows/Mac): [sideloadly.io](https://sideloadly.io/)
- **AltStore** (Windows/Mac): [altstore.io](https://altstore.io/)
- **3uTools** (Windows): [3uTools.com](https://www.3utools.com/)

**Sideloadly 使用步骤**:
1. 下载并安装 Sideloadly
2. 连接 iPhone 到电脑
3. 打开 Sideloadly
4. 输入你的 Apple ID
5. 拖拽 IPA 文件到 Sideloadly
6. 点击 Start 开始签名安装
7. 在 iPhone 上信任开发者证书
   - 设置 → 通用 → VPN与设备管理 → 信任
8. 等待安装完成

> ⚠️ **注意**: 免费 Apple ID 签名的应用 7 天后会失效，需要重新签名安装。

#### 方案三：企业签名（1年过期）

**支持系统**: 所有 iOS 版本

**优点**:
- ✅ 有效期长（1年）
- ✅ 无需注册设备 UDID
- ✅ 安装方便

**缺点**:
- ❌ 需要企业开发者账号（$299/年）
- ❌ 共享证书可能被苹果封禁
- ❌ 有一定安全风险

**获取渠道**:
- 某些第三方应用商店提供企业签名服务
- 可以购买企业证书自己签名
- 部分付费签名平台提供服务

> ⚠️ **注意**: 使用企业签名请注意数据安全，避免使用来源不明的签名服务。

#### 方案四：越狱设备

**支持系统**: 可越狱的 iOS 版本

**优点**:
- ✅ 完全自由，无需签名
- ✅ 可以安装任何 IPA
- ✅ 功能完整

**缺点**:
- ❌ 有安全风险
- ❌ 可能失去保修
- ❌ 不是所有系统版本都能越狱

**安装方法**:
1. 越狱你的 iPhone
2. 安装 AppSync Unified 插件
3. 使用 Filza 或其他工具安装 IPA
4. 或者通过 Cydia 添加源安装

> ⚠️ **警告**: 越狱有风险，请谨慎操作，确保了解相关风险后再进行。

---

### 9.4 云端打包常见问题

#### Q: GitHub Actions 构建失败怎么办？
A: 
1. 点击进入构建详情页查看日志
2. 检查是否有编译错误
3. 确认项目配置正确
4. 可以尝试在本地用 Xcode 编译测试

#### Q: 构建分钟数用完了怎么办？
A: 
- 公开仓库是无限分钟数，建议使用公开仓库
- 私有仓库可以创建新的 GitHub 账号
- 或者使用其他云端打包服务（如 Codemagic）

#### Q: 未签名 IPA 可以直接安装吗？
A: 不可以，必须通过签名工具或特殊方式安装。详见 9.3 节。

#### Q: TrollStore 安全吗？
A: TrollStore 是利用系统漏洞实现的永久签名，相对安全，但仍需注意：
- 只安装可信来源的 IPA
- 不要输入敏感信息到不明应用
- 定期更新 TrollStore 版本

#### Q: 没有 Mac 可以配置签名吗？
A: 
- 未签名 IPA 不需要配置，直接构建即可
- 如果需要签名，可以在 Windows 上用其他工具签名
- 或者使用支持自动签名的云端服务（如 Codemagic）

#### Q: 构建需要多长时间？
A: 
- GitHub Actions: 约 5-10 分钟（含启动时间）
- 主要时间花在 macOS runner 启动和 Xcode 编译上
- 首次构建可能稍慢

---

## 附录

### A. 有用的命令

```bash
# 查看已安装的证书
security find-identity -v -p codesigning

# 查看描述文件
ls ~/Library/MobileDevice/Provisioning\ Profiles/

# 查看 IPA 信息
unzip -l MineRadio.ipa

# 查看应用签名
codesign -d --entitlements - Payload/MineRadio.app

# 清理 Xcode 缓存
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Caches/com.apple.dt.Xcode
```

### B. 参考链接

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Code Signing Guide](https://developer.apple.com/support/code-signing/)
- [Xcode Build System Guide](https://developer.apple.com/documentation/xcode/build-system)

---

**文档版本**: 1.0
**更新日期**: 2026-07-03
**适用项目**: MineRadio iOS v1.1.4
