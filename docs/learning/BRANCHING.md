# 持久分支与上游同步

- 持久分支：`feature/self-directed-learning`（本项目所有自主订阅客户端改动都落在这里）
- 上游：`origin/main` → https://github.com/bggRGjQaUbCoE/PiliPlus.git
- 基线：`217fb54f5 Release 2.2.1`（2026-11-14）

## 同步上游更新

```bash
git fetch origin
git switch feature/self-directed-learning
git merge origin/main
# 冲突时优先保留 lib/learning/ 下的本地实现，
# 在共享文件（storage.dart / app_pages.dart / video_card_h.dart /
# ugc/view.dart / mine/controller.dart）中手工合并上游改动。
```

不要对该分支使用 `push --force`。上游功能若与我们冲突，以「本地规则 + 只读白名单」的冻结规格为准。

CI: pushes to `feat/norecommend` build signed release APKs via GitHub Actions.
