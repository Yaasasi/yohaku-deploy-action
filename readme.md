# Yohaku Deploy Action

> **Note:** 这是一个利用 GitHub Action 去构建私有版本站点并构建 Docker 镜像，随后推送到 GitHub Container Registry（GHCR）的工作流。

# 最近变更

- 工作流已通用化：源码仓库、构建命令、产物路径均可通过环境变量覆盖，详见下节「配置项」。

## How to

这个工作流当前只负责：

- 从私有源码仓库构建 Yohaku
- 将构建产物打包成 Docker 镜像
- 推送镜像到 GitHub Container Registry（GHCR）

你只需要确保仓库 `Settings -> Secrets and variables -> Actions` 中包含下列 Secrets：

- `GH_PAT`：用于访问私有源码仓库的 personal access token
- `BASE_URL`：站点运行时的根 URL
- `NEXT_PUBLIC_API_URL`：客户端访问的 API 根地址
- `NEXT_PUBLIC_GATEWAY_URL`：客户端访问的网关地址

构建完成后，镜像会推送到 GHCR，默认镜像名为：

- `ghcr.io/${{ github.repository_owner }}/yohaku`

可用以下方式拉取或运行：

```sh
docker pull ghcr.io/<OWNER>/yohaku:latest
# 或者使用具体 commit 标签
# docker pull ghcr.io/<OWNER>/yohaku:sha-<commit-sha>

docker run -d \
  -e BASE_URL=https://example.com \
  -e NEXT_PUBLIC_API_URL=https://example.com/api/v2 \
  -e NEXT_PUBLIC_GATEWAY_URL=https://example.com \
  -p 3000:3000 \
  ghcr.io/<OWNER>/yohaku:latest
```

如果你希望推送的镜像能正常运行，还应同时准备你 Docker 镜像中运行时需要的环境变量，并在镜像部署到目标环境时注入它们。

---

## 配置项

工作流支持以下环境变量（在 `.github/workflows/deploy.yml` 的 `env` 段修改，或通过 GitHub Variables 注入）：

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `SOURCE_REPO` | `innei-dev/Yohaku` | 私有源码仓库（格式：`owner/repo`） |
| `BUILD_COMMAND` | `pnpm --filter @yohaku/web build:ci` | 构建命令。 workflow 会在构建后自动执行 standalone 打包与 zip；如果你的项目结构不同，可修改此命令 |
| `STANDALONE_SUBPATH` | `standalone/apps/web` | 构建产物中 standalone 包的相对路径。Yohaku 与旧版 Shiroi 若结构不同，请按需调整 |

如果你部署的是旧版 **Shiroi**（monorepo 结构为 `apps/web`），通常保持默认即可；若你的仓库结构不同（例如单仓库直接输出到 `.next/standalone`），请修改 `STANDALONE_SUBPATH`。

## CI 构建与站点 URL 环境变量

工作流在 GitHub Actions 里执行 `next build` 时，会通过仓库 **Secrets** 注入 `BASE_URL`、`NEXT_PUBLIC_API_URL` 与 `NEXT_PUBLIC_GATEWAY_URL`，须与服务器 `~/yohaku/.env`（及私有仓库 `Dockerfile` / 模板）一致。

- **`BASE_URL`**：站点对外根 URL（无尾部斜杠为宜），例如 `https://example.com`。与私有镜像构建阶段一致：`Dockerfile` 中常用 `ARG BASE_URL`，并令 `NEXT_PUBLIC_GATEWAY_URL=${BASE_URL}`、`NEXT_PUBLIC_API_URL=${BASE_URL}/api/v2`。
- **`NEXT_PUBLIC_*`**：直接参与 `next build` 与客户端 bundle；若启用 **ISR**，构建期/再验证会依赖正确端点，不能只依赖部署机 `.env` 而忽略 Actions。

在仓库 **Settings → Secrets and variables → Actions** 中新增：

- `BASE_URL`
- `NEXT_PUBLIC_API_URL`
- `NEXT_PUBLIC_GATEWAY_URL`

## Secrets

- `GH_PAT`：用于访问私有源码仓库的 Personal Access Token
- `BASE_URL`、`NEXT_PUBLIC_API_URL`、`NEXT_PUBLIC_GATEWAY_URL`：供 CI 构建注入

### Github Token

1. 你的账号可以访问当前私有源码仓库（Yohaku 或你正在使用的对应私有仓库）。
2. 进入 [tokens](https://github.com/settings/tokens) - Personal access tokens - Tokens (classic) - Generate new token - Generate new token (classic)

![](https://github.com/innei-dev/yohaku-deploy-action/assets/41265413/e55d32cb-bd30-46b7-a603-7d00b3f8a413)

## Technical details

参考：[跨仓库全自动构建项目并部署到服务器](./post.md)