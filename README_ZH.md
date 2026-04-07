<div align="center">

# Modpack Template - Pakku

基于 [Pakku](https://github.com/juraj-hrivnak/Pakku) 的整合包模板, 提供整合包自动构建、测试与发布。

[English](README.md) / [简体中文](README_ZH.md)

![Counter](https://count.getloli.com/@MPT-P?name=MPT-P&theme=miku&padding=7&offset=0&align=top&scale=1&pixelated=1&darkmode=auto)

</div>

## 特性

- 自动验证 json 与 toml 文件
- 自动构建整合包的服务端与客户端
- 自动测试整合包的服务端与客户端
- 自动测试客户端能否正常连接服务端
- 提供基于分发源码的轻量化服务端

## 使用

### Pakku

参考 [https://juraj-hrivnak.github.io/Pakku/home.html](https://juraj-hrivnak.github.io/Pakku/home.html)。

### Github Action

#### 自动构建 & 测试

- 当整合包内容有实质性变更时，Action 会自动触发，包括 `pakku.json`，`pakku-lock.json` 或 `.pakku/` 中的更改。
- Action 会检验 `.pakku/` 文件夹中的 json 与 toml 文件，你可以配置 `exclude.txt` 来决定哪些文件不被检查。
- 随后构建整合包与服务端，在 `build` tag 下发布。
- 最终启动服务端与客户端进行测试。

#### 发布

- 你必须手动在 Github Action 触发脚本。
- Action 将会自动解析版本并进行发布。
- 如果你想自动将整合包发布至 Curseforge or Modrinth，参阅 [Kir-Antipov/mc-publish](https://github.com/marketplace/actions/mc-publish) 对 [发布脚本](.github/workflows/build.yml) 进行修改。

## 协议

MIT License

## 特别感谢

- [Pakku](https://github.com/juraj-hrivnak/Pakku)
- [PortableMC](https://github.com/theorzr/portablemc)
- [CTNH](https://github.com/CTNH-Team/Create-New-Horizon)