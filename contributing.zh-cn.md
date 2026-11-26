# 参与 PathDeck 开发

[报告缺陷](https://github.com/AMFI-Disable/PathDeck/issues/new?title=%5BBUG%5D+&body=%23%23+Environment+%2F+%E8%BF%90%E8%A1%8C%E7%8E%AF%E5%A2%83%0A%0A%23%23+Steps+To+Reproduce+%2F+%E5%A4%8D%E7%8E%B0%E6%AD%A5%E9%AA%A4%0A%0A%23%23+Expected+And+Actual+Results+%2F+%E9%A2%84%E6%9C%9F%E4%B8%8E%E5%AE%9E%E9%99%85%E7%BB%93%E6%9E%9C%0A%0A) · [提出功能建议](https://github.com/AMFI-Disable/PathDeck/issues/new?title=%5BFEATURE%5D+&body=%23%23+User+Need+%2F+%E4%BD%BF%E7%94%A8%E9%9C%80%E6%B1%82%0A%0A%23%23+Proposed+Change+%2F+%E6%94%B9%E8%BF%9B%E6%96%B9%E6%A1%88%0A%0A%23%23+Acceptance+Criteria+%2F+%E9%AA%8C%E6%94%B6%E6%9D%A1%E4%BB%B6%0A%0A)

[English](contributing.md) · [项目文档](readme.zh-cn.md)

## 问题与建议

提交缺陷前请搜索已有议题。报告中请提供应用版本、macOS 版本、shell 类型、复现步骤及预期和实际结果。功能建议请说明具体使用场景及验收条件。

## 开发与测试

从仓库的 `main` 建立功能分支。项目使用原生 Swift，不引入第三方依赖。仓库内新增文件及目录采用小写；最终打包的应用及磁盘映像使用产品名。更改解析器或备份管理器时，请在 `tests/pathdecktests/` 添加相应测试，执行 `swift test`。任何写入配置的操作都应先完成自动备份。

维持现有的低内存占用目标（运行时低于 20 MB）。发起拉取请求时请附上验证记录；若涉及性能，请注明测量环境和结果。
