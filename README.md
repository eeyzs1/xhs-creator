# 小红书种草助手 (XHS Creator)

> Flutter 手机 App + Python FastAPI 后端，帮助博主快速生成小红书帖子内容。
>
> AI 能力全部由**阿里百炼**提供（一个 API Key 搞定全部）。

---

## 功能

- 📸 **虚拟试穿** — 上传服装图 + 真人街拍图，AI 自动生成试穿效果
- ✍️ **文案生成** — 自动生成小红书风格的种草文案（标题 + 正文 + 标签）
- 🎨 **图片编辑** — 通过自然语言指令编辑已生成的试穿图片
- 🔄 **反复修改** — 通过自然语言反复修改图片和文案
- 👀 **帖子预览** — 小红书风格的帖子预览
- 🔐 **用户系统** — 用户名密码注册/登录，数据云端存储
- 💾 **数据持久** — 卸载重装后用原账号登录即可恢复所有数据

---

## 技术栈

| 层 | 技术 |
|------|---------|
| 前端 | Flutter 3.41.6 + Provider 状态管理 |
| 后端 | Python FastAPI + SQLAlchemy + SQLite |
| AI | 阿里百炼（aitryon 试穿 + qwen-plus 文案 + qwen-image-2.0-pro 图片编辑） |

---

## 前置准备

1. **Flutter SDK** 3.41.6+
2. **Python** 3.10+
3. **阿里百炼 API Key** — 在 [百炼控制台](https://bailian.console.aliyun.com/) 创建 API Key
4. **Android Studio**（Android 测试）或 **Xcode**（iOS 测试）

---

## 快速开始

### 1. 启动后端

```bash
cd server

# 安装依赖
pip install -r requirements.txt

# 配置 API Key
# 编辑 .env 文件，填入你的阿里百炼 API Key
# BAILIAN_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# 启动服务端
uvicorn main:app --host 0.0.0.0 --port 8000
```

服务端启动后，访问 `http://localhost:8000/docs` 可查看 API 文档。

### 2. 启动前端

```bash
cd app

# 安装依赖
flutter pub get

# 启动（连接模拟器或真机）
flutter run
```

### 3. 配置服务器地址

App 启动后，在**首页右上角 ⚙️ 设置图标**中配置后端 IP：

| 测试场景 | 设置页填什么 |
|---------|-------------|
| Android 模拟器（默认） | `10.0.2.2:8000` |
| 真机 + 同一 WiFi | `192.168.x.x:8000`（你电脑的局域网 IP） |
| 换了台电脑 | 新电脑的局域网 IP:8000 |

> **注意**：真机测试时，电脑防火墙需要放行 8000 端口：
> ```bash
> netsh advfirewall firewall add rule name="XHS Server" dir=in action=allow protocol=TCP localport=8000
> ```

---

## 测试

项目使用 **Flutter integration_test** 进行端到端自动化测试，覆盖注册、登录、创建帖子、AI 生成、编辑、复制粘贴、卸载重装等全流程。

### 服务器 IP 配置

测试通过 `--dart-define=TEST_SERVER_IP=<ip:port>` 参数指定服务器地址，**不硬编码任何 IP**。测试会在 UI 上模拟用户输入来设置服务器 IP。

| 测试场景 | `TEST_SERVER_IP` 值 | 说明 |
|---------|---------------------|------|
| Android 模拟器（默认） | `10.0.2.2:8000` | 不传参时的默认值 |
| 真机 + 同一 WiFi | `你的局域网IP:8000` | 如 `192.168.1.100:8000` |

### 运行完整测试

```powershell
# 确保后端已启动
cd server
uvicorn main:app --host 0.0.0.0 --port 8000

# 运行完整 E2E 测试（含卸载重装验证）
powershell -ExecutionPolicy Bypass -File run_e2e_test.ps1
```

### 分步运行

```bash
cd app

# Part 1: 核心功能测试（注册→配置IP→创建帖子→AI生成→复制粘贴→编辑→退出）
# 模拟器（使用默认 IP 10.0.2.2:8000）：
flutter test integration_test/full_flow_test.dart -d emulator-5554

# 真机（指定你的局域网 IP）：
flutter test integration_test/full_flow_test.dart -d <device-id> --dart-define=TEST_SERVER_IP=192.168.1.100:8000

# 清除 App 数据（模拟卸载重装）
adb shell pm clear com.xhscreator.xhs_creator

# Part 2: 卸载重装持久性测试（登录→配置IP→验证数据→复制粘贴→编辑→退出）
# 模拟器：
flutter test integration_test/reinstall_test.dart -d emulator-5554

# 真机：
flutter test integration_test/reinstall_test.dart -d <device-id> --dart-define=TEST_SERVER_IP=192.168.1.100:8000
```

### 测试覆盖

| 测试项 | 验证方式 |
|--------|---------|
| 用户注册/登录 | UI 交互 + API 验证 |
| 服务器 IP 配置 | UI 模拟用户输入 + SnackBar 确认 |
| 创建帖子（上传图片） | API MultipartRequest + 真实图片 |
| AI 试穿图生成 | API 调用 + tryon_image_path 验证 |
| AI 文案生成 | API 调用 + 标题/内容验证 |
| 复制到剪贴板 | AppBar + 底部栏复制按钮 + Clipboard.getData 验证内容 |
| 编辑文案（提交） | Provider.editPost() + API 验证内容变化 |
| 编辑图片（提交） | Provider.editPost() + API 验证图片路径更新 |
| 从历史记录进入编辑 | UI 点击帖子卡片→预览→编辑 |
| 卸载重装数据持久 | adb pm clear → 重新登录 → 验证帖子仍在 |
| 重装后编辑功能 | 重装后从历史记录进入编辑并提交 |

---

## 项目结构

```
├── app/                          # Flutter 前端
│   ├── integration_test/
│   │   ├── full_flow_test.dart   # 核心功能 E2E 测试
│   │   └── reinstall_test.dart   # 卸载重装持久性测试
│   ├── test_assets/              # 测试用图片资源
│   ├── lib/
│   │   ├── config/
│   │   │   └── api_config.dart   # API 地址配置（支持动态 IP 设置）
│   │   ├── models/
│   │   │   ├── post.dart         # 帖子数据模型
│   │   │   └── user.dart         # 用户数据模型
│   │   ├── providers/
│   │   │   └── post_provider.dart # 帖子状态管理
│   │   ├── screens/
│   │   │   ├── splash_screen.dart    # 启动页
│   │   │   ├── login_screen.dart     # 登录页
│   │   │   ├── register_screen.dart  # 注册页
│   │   │   ├── home_screen.dart      # 首页（帖子列表）
│   │   │   ├── create_post_screen.dart # 创建帖子（3 步流程）
│   │   │   ├── post_preview_screen.dart # 小红书风格预览
│   │   │   ├── edit_post_screen.dart   # 编辑帖子
│   │   │   └── settings_screen.dart    # 服务器 IP 设置
│   │   ├── services/
│   │   │   ├── api_service.dart    # HTTP API 调用
│   │   │   └── auth_service.dart   # 认证服务
│   │   ├── theme/
│   │   │   └── xhs_theme.dart      # 小红书主题
│   │   └── widgets/
│   │       ├── image_picker_widget.dart # 图片选择器
│   │       ├── loading_overlay.dart     # 加载遮罩
│   │       └── xhs_post_card.dart       # 帖子卡片
│   └── pubspec.yaml
│
├── server/                       # Python FastAPI 后端
│   ├── main.py                   # 入口（CORS + 静态文件）
│   ├── config.py                 # 配置（阿里百炼 API 等）
│   ├── database.py               # SQLAlchemy 数据库连接
│   ├── models.py                 # ORM 模型（User, Post）
│   ├── schemas.py                # Pydantic 数据模型
│   ├── .env                      # 环境变量（API Key）
│   ├── requirements.txt          # Python 依赖
│   ├── routers/
│   │   ├── auth.py               # 注册/登录（JWT）
│   │   ├── posts.py              # 帖子 CRUD
│   │   └── ai.py                 # AI 服务路由（async）
│   └── services/
│       ├── tryon_service.py      # 虚拟试穿（aitryon，异步轮询）
│       ├── copywriting_service.py # 文案生成（qwen-plus）
│       └── image_service.py      # 图片编辑（qwen-image-2.0-pro）
│
├── run_e2e_test.ps1              # 一键 E2E 测试脚本
└── README.md
```

---

## API 概览

| 端点 | 方法 | 说明 |
|------|------|------|
| `/api/auth/register` | POST | 注册 |
| `/api/auth/login` | POST | 登录 |
| `/api/auth/me` | GET | 获取当前用户 |
| `/api/posts` | GET | 获取帖子列表 |
| `/api/posts` | POST | 创建帖子 |
| `/api/posts/{id}` | GET/PUT/DELETE | 帖子详情/更新/删除 |
| `/api/ai/tryon` | POST | 虚拟试穿（异步，约 1-3 分钟） |
| `/api/ai/copywriting` | POST | 生成文案 |
| `/api/ai/edit` | POST | 编辑文案/图片 |

---

## 常见问题

**Q: 试穿生成很慢怎么办？**

百炼 `aitryon` 是异步 API，通常需要 1-3 分钟。服务端使用协程轮询，不会阻塞其他请求。

**Q: 图片上传失败？**

确保服务端 `uploads/` 目录存在且有写入权限。真机测试时确保 `SERVER_HOST` 配置正确（百炼需要公网可访问的图片 URL）。

**Q: 换了电脑测试？**

1. 新电脑启动服务端
2. App 设置页 → 输入新电脑的 IP:8000
3. 保存即可

**Q: 如何清空数据？**

删除 `server/xhs_creator.db` 文件，重启服务端即可。

**Q: 卸载 App 后数据还在吗？**

在。所有数据存储在服务端数据库中，App 只保存登录凭据。卸载重装后用原账号登录即可恢复所有帖子。
