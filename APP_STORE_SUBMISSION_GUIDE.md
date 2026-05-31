# 起身 App Store 提交审核指引

本文记录 `起身` iOS 版从本地构建到 App Store Connect 提交审核的完整手动流程，适合作为以后版本发布时的检查清单。

## 一、发布前检查

1. 确认代码在正确分支：

   ```bash
   cd ~/Developer/standup-reminder-git
   git status
   ```

   当前发布分支是 `codex-ios-port`。

2. 确认版本号：

   在 `pubspec.yaml` 中检查：

   ```yaml
   version: 1.1.0+3
   ```

   `1.1.0` 是 App Store 显示版本，`+3` 是构建号。每次重新上传 App Store Connect，构建号必须递增。

3. 确认 Bundle Identifier：

   当前使用：

   ```text
   com.routingcn.standupreminder
   ```

4. 确认出口合规声明：

   `ios/Runner/Info.plist` 中应包含：

   ```xml
   <key>ITSAppUsesNonExemptEncryption</key>
   <false/>
   ```

   这表示 App 不使用需要出口合规文件的加密能力，可避免 App Store Connect 对构建版本显示“缺少出口合规证明”。

## 二、本地构建与上传

1. 清理并获取依赖：

   ```bash
   flutter clean
   flutter pub get
   cd ios
   pod install
   cd ..
   ```

2. 构建 IPA：

   ```bash
   flutter build ipa --release --no-tree-shake-icons
   ```

3. 打开归档文件：

   ```bash
   open build/ios/archive/Runner.xcarchive
   ```

4. 在 Xcode Organizer 中上传：

   - 选择最新归档。
   - 点击 `Distribute App`。
   - 选择 `App Store Connect`。
   - 按提示继续签名并上传。

5. 上传完成后，等待 App Store Connect 处理构建版本。通常几分钟后可在 `TestFlight` 或版本页面选择该构建。

## 三、App Store Connect 信息填写

进入 App Store Connect：

```text
我的 App -> 起身 -> 分发 -> 当前 iOS 版本
```

需要确认以下项目。

### App 信息

- 名称：`起身`
- Bundle Identifier：`com.routingcn.standupreminder`
- 主要类别：`健康健美`
- 年龄分级：根据实际内容回答。当前 App 无暴力、成人、赌博、医疗诊断等内容，通常为 `4+`。

### 价格

- 当前目标价格：中国区 `¥1.00`
- 如果是收费 App，需要确认 App Store Connect 的协议、税务和银行信息已经完成，否则可能无法销售或收款。

### 隐私

当前隐私策略：

- 不收集用户数据。
- 不需要登录。
- 数据保存在本机。

隐私政策 URL 当前使用 GitHub 项目说明页：

```text
https://github.com/RoutingCn/standup-reminder
```

注意：如果仓库改为私有，这个 URL 不适合作为公开隐私政策页。建议后续准备一个公开网页，例如 GitHub Pages、个人网站或 Notion 公共页面。

### 版权

当前填写：

```text
© 2026 cn routing. All rights reserved.
```

### 技术支持网址

当前填写：

```text
https://github.com/RoutingCn/standup-reminder
```

同样注意：如果仓库私有，建议换成公开支持页面或公开邮箱说明页。

### 审核联系信息

填写 Apple 审核团队需要联系开发者时使用的信息：

- 名字：`Tao`
- 姓氏：`Kang`
- 电话：使用开发者本人可接听的手机号
- 邮箱：使用开发者本人可收到邮件的邮箱

### 登录信息

如果 App 不需要账号登录，保持 `需要登录` 不勾选。

如果 App 以后加入账号系统，才需要在这里填写一个“给 Apple 审核员测试用的 App 内测试账号”，不是 Apple ID，也不是 GitHub 账号，更不是开发者自己的私人账号。

示例：

```text
用户名：review@example.com
密码：专门给审核使用的测试密码
```

这个账号必须能让 Apple 审核员进入 App 的受限功能，且不能要求短信验证码、邮箱验证码或人工审批。

## 四、截图要求

App Store Connect 会根据 App 支持的设备类型要求截图。

当前项目支持 iPhone 和 iPad，因此需要：

- iPhone 截图
- 13 英寸 iPad 截图

### iPhone 截图

本次使用 `1242 × 2688px` 规格，已生成目录：

```text
/Users/cnrouting/Downloads/appstore-screenshots-1242x2688
```

### iPad 截图

如果页面提示：

```text
你必须上传 13 英寸 iPad 显示屏的截屏。
```

可上传以下规格之一：

```text
2064 × 2752px
2752 × 2064px
2048 × 2732px
2732 × 2048px
```

本次为了通过审核提交，用 iPhone 截图生成了一张 `2064 × 2752px` 的 iPad 截图：

```text
/private/tmp/appstore-ipad-screenshots/IMG_8741_ipad_2064x2752.PNG
```

建议后续正式优化时，用 iPad 模拟器重新截更自然的 iPad 版截图。

## 五、选择构建版本

1. 在版本页面找到 `构建版本`。
2. 点击 `添加构建版本`。
3. 选择最新构建号，例如 `1.1.0 (3)`。
4. 点击完成并保存。

如果构建版本显示“缺少出口合规证明”，优先检查 `Info.plist` 是否已有：

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

修改后必须递增构建号并重新上传。

## 六、提交审核

1. 点击右上角 `添加以供审核`。
2. 页面会生成一个 `草稿提交`。
3. 打开草稿提交面板。
4. 确认包含项目是当前 iOS 版本，例如：

   ```text
   iOS App 1.1.0
   1.1.0 (3)
   ```

5. 点击 `提交以供审核`。

提交成功后，页面会提示：

```text
已提交 1 个项目
审核最多可能需要 48 小时。审核完成后，你会收到电子邮件通知。
```

## 七、常见问题

### 1. 无法添加以供审核：必须选择构建版本

原因：版本页面还没有绑定上传的 build。

解决：

- 等待 App Store Connect 处理上传的构建版本。
- 在 `构建版本` 区域点击 `添加构建版本`。
- 选择最新构建号。

### 2. 缺少出口合规证明

原因：Apple 不知道 App 是否使用受管制加密。

解决：

- 在 `ios/Runner/Info.plist` 添加 `ITSAppUsesNonExemptEncryption=false`。
- 递增 build number。
- 重新构建并上传。

### 3. 要求上传 13 英寸 iPad 截图

原因：App 支持 iPad。

解决：

- 上传至少一张符合规格的 13 英寸 iPad 截图。
- 更好的做法是在 iPad 模拟器上真实截图。
- 临时做法是把已有截图处理成 `2064 × 2752px`。

### 4. 要求填写用户名和密码

这里要填的是“App 内测试账号”，供 Apple 审核员登录 App 使用。

不要填写：

- Apple ID
- GitHub 账号
- App Store Connect 账号
- 开发者本人的私人账号

当前 `起身` 不需要登录，所以应保持 `需要登录` 不勾选。

### 5. 需要提供隐私政策 URL

即使 App 不收集数据，App Store Connect 也可能要求填写隐私政策 URL。

解决：

- 准备一个公开可访问页面。
- 页面说明 App 是否收集数据、数据如何保存、如何联系开发者。

### 6. 欧盟交易商状态提示

App Store Connect 可能提示：

```text
开发者必须提供交易商状态，才能提交新 App 或 App 更新以在欧盟地区分发。
```

这与欧盟《数字服务法》有关。通常需要账号持有人或管理员在 App Store Connect 中确认交易商或非交易商身份。

如果不面向欧盟地区分发，可以调整销售地区；如果面向欧盟地区分发，需要按 Apple 要求补充信息。

### 7. Paid App 协议、税务、银行信息

如果 App 收费，例如中国区 `¥1.00`，需要确认：

- Paid Apps Agreement 已接受。
- 税务信息已填写。
- 银行收款信息已填写。

否则可能可以提交审核，但通过后无法正常销售或收款。

### 8. GitHub 版本与发布版本不一致

每次上传审核前，应确认本地发布提交已推送：

```bash
git status --short --branch
git push
```

本次提交审核对应提交：

```text
6f275e3 Prepare iOS build for App Store review
```

远端 `codex-ios-port` 已同步到该提交。

## 八、本次提交记录

- App：`起身`
- App Store 版本：`1.1.0`
- 构建号：`3`
- Bundle Identifier：`com.routingcn.standupreminder`
- 提交状态：已提交审核
- 提交时间：2026-06-01
- 审核提示：最多可能需要 48 小时
