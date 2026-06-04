# 我的固定规则 & 个人信息（永久记忆）

## 一、个人基础信息
- 我是软件工程专业的学生
- 使用 VS Code + Claude Code + CC Switch + DeepSeek 整套环境
- 国内直连使用，不需要访问 Claude 官方服务
- 注重节省C盘空间，文件优先放在 D/E 盘
- DeepSeek 按 Token 计费，希望回答精简、高效、不浪费

## 二、AI 必须遵守的输出格式
1. 全程使用**中文**回答，代码、变量名用英文
2. 回答逻辑：**先给结论，再给步骤，最后给代码**
3. 语言风格：**简洁干练、不啰嗦、不废话、实战优先**
4. 标题使用 ###，重点内容**加粗**
5. 代码必须放在 ``` 代码块里，并标注语言
6. 操作步骤用 1.2.3.，列表用短横线 -

## 三、编程环境与习惯
1. 主力编辑器：VS Code
2. AI 客户端：Claude Code for VS Code
3. 模型管理：CC Switch 代理
4. 主力模型：deepseek-v4-pro（复杂代码、调试）
5. 快速模型：deepseek-v4-flash（简单问答、单行代码）
6. 常用命令：/init /model /clear /exit

## 四、报错快速判断规则
1. 402 = DeepSeek 余额不足
2. 401 = API Key 错误
3. 连接失败 = CC Switch 未启动
4. 地区不可用 = 代理配置错误

## 五、模型插件能力

### 图片识别（视觉）
- DeepSeek v4 **不支持**视觉，需要间接调用千问 VL 模型
- 脚本: `python f:/Stuff/vision.py <图片路径> [提问]`
- 当用户贴图显示 `[Unsupported Image]` 时，提示保存文件后调用 vision.py
- 千问 API Key: sk-fddd345fa23049c290d393b662d4cc29

### 未来扩展
- 图片生成 / 视频生成 / 语音合成 同样用插件模式
- 主模型永远是 DeepSeek v4，特殊能力走专用模型 API

## 六、Git 自动推送
- 仓库: `https://github.com/Fullerdith/CODE`
- 脚本: `powershell f:/Stuff/auto-push-自动推送.ps1`
- 每次生成/修改文件后提交，commit 格式: `type: EN desc 中文描述`

## 七、长期使用目标
1. 现阶段专注使用 DeepSeek
2. 未来会接入 Claude 等其他模型
3. 依靠 CC Switch 实现一键切换，不改动环境