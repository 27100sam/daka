# 写作打卡 · 联网部署说明（Supabase + 静态托管）

当前 `index.html` 已支持：多设备云端同步、账号登录/注册、每个账号独立记录、管理员后台（查看/停止账号）。
未配置时仍以「本地模式」运行（数据只存本机浏览器）。

## 一、创建 Supabase 项目（免费）
1. 打开 https://supabase.com ，注册并登录。
2. 点 New project：填名称（如 writing-checkin）、设数据库密码、选区域（如 Singapore/Tokyo），创建。
3. 左侧菜单 -> SQL Editor -> New query，把 `supabase-setup.sql` 整段粘贴进去，点 Run（只需运行一次）。
4. 左侧菜单 -> Authentication -> Providers，确认 Email 已启用；如想免邮箱确认，可在 Authentication -> Sign In / Up 关闭 “Confirm email”（可选）。

## 二、拿到项目地址和 anon key
1. 左侧菜单 -> Project Settings（项目设置）-> API。
2. 复制 Project URL（形如 https://xxxx.supabase.co）和 anon public key（eyJhbGci…）。
3. 打开 `index.html`，在顶部 JS 配置区填写：

```js
var SUPABASE_URL = "https://你的项目.supabase.co";
var SUPABASE_ANON_KEY = "你的anon key";
```

## 三、创建账号与管理员
1. 双击打开 `index.html`（或部署后打开网页），点「注册」，用邮箱 + 密码注册。
2. 第一个注册的账号是普通用户。要设为管理员，在 Supabase SQL Editor 里运行：

```sql
update public.profiles set role = 'admin' where email = '你的邮箱@example.com';
```

之后重新登录即可看到「管理后台」。

## 四、部署成网页（手机/其他电脑也能打开）
任选一种：
- **Netlify Drop（最简单）**：打开 https://app.netlify.com/drop ，把「打卡」文件夹拖进去，即可获得公网网址。
- **GitHub Pages**：新建仓库，上传 `index.html` 与 `supabase-setup.sql`，在仓库 Settings -> Pages 开启并选择分支。
- **阿里云 OSS / 腾讯云 COS**：开启静态网站托管，上传 `index.html`。

## 五、日常使用
- 登录后打卡，数据实时写入云端；换设备登录同一账号即可看到同一份数据。
- 首次登录时，会把本机浏览器里原有的旧记录自动导入该账号（只导入一次）。
- 管理员登录后，页面底部出现「管理后台」：可查看每个账号的邮箱、状态、总字数、记录天数、最近打卡，可展开查看记录明细，并可「停止」（停用后该账号无法再读写）或「恢复」账号。

## 六、常见问题
- **无需联网加载 SDK**：supabase-js 已下载为本地文件 `supabase-js.min.js`（同目录），页面不依赖外部 CDN；以后想升级可替换该文件。
- **注册后提示先确认邮箱**：Supabase 默认开启邮箱确认，去邮箱点确认链接；或在 Authentication 里关闭 Confirm email。
- **管理员看不到后台**：确认已执行第 3 步的 update，并重新登录。
- **想重新导入本机旧数据**：清除浏览器 localStorage 里的 `writing-checkin-imported` 键后再登录。