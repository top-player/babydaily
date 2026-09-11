# 备份导入改用系统文件选择器（SAF），导出仍写公共下载目录

导入不再由应用自己去列「下载/BabyDaily」的目录，而是调用系统文件选择器（`ACTION_OPEN_DOCUMENT`），用户在任意位置挑一份 json（下载目录、微信接收、U 盘、从电脑拷进来的都行）。这修订 ADR-0005 的"导入提供文件选择列表"这一条，导出侧（MediaStore 写入 `下载/BabyDaily`）不变。

原因是自列目录在真机上不可靠：Android 11+ 应用在 MediaStore 里只能看到自己写入的文件，换机、清理重装、或用电脑拷回来的备份都不带本应用的 owner，列表要么看不到、要么标注"无法读取"——用户感受到的就是"有时识别不到"。SAF 由系统授权读任意文档，绕开了这个限制，也省掉了维护一份"备份列表"界面的成本。

**Considered Options**
- 保留自列目录 + 手动把文件放回指定文件夹：被否——正是要修的"识别不到"。
- 引入 `file_picker` 等插件：被否——一个系统 Intent 就能解决，沿用 ADR-0005 的"零新依赖"。
- 导入时也要求用户先导出一次以建立归属：被否——换机场景（旧手机导出、新手机导入）恰恰不满足。

**Consequences**
- `MainActivity` 的存储通道只保留 `saveBackup` 与新增 `pickBackup`（`startActivityForResult` + 后台线程读文件），删掉 `listBackups / readBackup`。
- 选择器不限 MIME（`*/*`）：各家文件管理器对 `.json` 的判定不一致（application/json、text/plain、application/octet-stream 都有），限类型反而会让备份"消失"；因此改在 Dart 侧校验内容，不是本应用的版本 1 快照就明确报"这不是宝宝日常导出的备份文件"。
- 确认框展示文件名与摘要（导出时间、主角与等级、任务/笔记数量），覆盖前能确认选对了文件。
- 导出侧加固：Android 10+ 写入时置 `IS_PENDING`，写完发布，失败删除残留，并在返回前回读校验——避免文件管理器偶尔扫不到刚写下的备份。
- 通道不可用（极旧系统/测试环境）时回退应用文档目录的 `babydaily_restore.json` 高级路径。
