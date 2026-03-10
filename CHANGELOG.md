# Changelog

All notable changes to this project will be documented in this file.

## [0.2.0](https://github.com/LuisOsuna117/terraform-aws-bedrock/compare/v0.1.0...v0.2.0) (2026-03-10)

### 🚀 Features

* add multi-prompt support and agent module ([c4e11e7](https://github.com/LuisOsuna117/terraform-aws-bedrock/commit/c4e11e7b6e689fb793f0523e7145cb5bb7d75eb9))
* **knowledge_base:** add Aurora PostgreSQL (pgvector) and Redshift Serverless support ([0d70a1a](https://github.com/LuisOsuna117/terraform-aws-bedrock/commit/0d70a1a93ddc212cfa4c499e0ae3fbc473618135))
* **knowledge_base:** auto-create backing store resources per storage type ([ccf4009](https://github.com/LuisOsuna117/terraform-aws-bedrock/commit/ccf400956321e23da2a9034ad68ff545d83c0aa7))
* **knowledge_base:** default storage_type to S3_VECTORS ([ae185e8](https://github.com/LuisOsuna117/terraform-aws-bedrock/commit/ae185e84d8edbe0a09172008a0e6a676a593b93f))

### 🐛 Bug Fixes

* add missing versions.tf to aurora-pgvector and redshift-serverless examples ([44bfa9b](https://github.com/LuisOsuna117/terraform-aws-bedrock/commit/44bfa9bfb75c2d914ebd0be8c9bd0cc32ac37b6f))
* address Trivy security findings in knowledge_base module ([28a3059](https://github.com/LuisOsuna117/terraform-aws-bedrock/commit/28a30597c622ba14b77c1a001b57a38e49a2d104))

### 📖 Documentation

* regenerate README with terraform-docs ([cca5e71](https://github.com/LuisOsuna117/terraform-aws-bedrock/commit/cca5e71dbff105f6bf65ac54be4adb26d5b0829d))

### 🔧 Code Refactoring

* flatten knowledge_base_config into individual root variables ([cd8ab0c](https://github.com/LuisOsuna117/terraform-aws-bedrock/commit/cd8ab0cbfc4e8a40b4365bcc016db07538cd0534))
* **knowledge_base:** consolidate flat vars into vector_config / kendra_config ([cad2d08](https://github.com/LuisOsuna117/terraform-aws-bedrock/commit/cad2d08a56f5512614812f98cc4d472076251ef0))
* **knowledge_base:** flatten vector_config/kendra_config/redshift_config wrappers ([a13f488](https://github.com/LuisOsuna117/terraform-aws-bedrock/commit/a13f488e2c186bc65ca6b5954fd7200a0c57cddf))
* remove prompt bridge mode ([128c4e0](https://github.com/LuisOsuna117/terraform-aws-bedrock/commit/128c4e0a9ef889099fb2157544547b6f7a5fdedb))
* **variables:** flatten field_mapping nesting, default storage_type (KISS) ([f80c9bf](https://github.com/LuisOsuna117/terraform-aws-bedrock/commit/f80c9bf0f5330c4d9e1eb3b23cc21519269eca87))

## [1.1.0](https://github.com/LuisOsuna117/terraform-aws-bedrock/compare/v1.0.0...v1.1.0) (2026-03-10)

### 🚀 Features

* add bedrock guardrail support ([98d80c8](https://github.com/LuisOsuna117/terraform-aws-bedrock/commit/98d80c8f2826465fb886009edaa3713d7fe40739))

### 🐛 Bug Fixes

* resolve ci validation and docs drift ([8bcef8e](https://github.com/LuisOsuna117/terraform-aws-bedrock/commit/8bcef8ef6d641c7ede0322a773de9e9e207173d7))

### 📖 Documentation

* improve example inputs and outputs ([3a3f5ea](https://github.com/LuisOsuna117/terraform-aws-bedrock/commit/3a3f5eaf7c21b49c06a5e1707848a0dafbe52ad0))

## 1.0.0 (2026-03-09)

### 🚀 Features

* initial terraform-aws-bedrock module scaffold ([b814b2f](https://github.com/LuisOsuna117/terraform-aws-bedrock/commit/b814b2ffdd75fd5e41fd244f960928f297edd201))

## [0.4.2](https://github.com/LuisOsuna117/terraform-aws-agentcore/compare/v0.4.1...v0.4.2) (2026-02-28)

### 📖 Documentation

* update README for runtime refactor — VPC mode, JWT authorizer, lifecycle, protocol, workload_identity_arn ([f1c35b0](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/f1c35b079e86fe240a9e2e7391c7120f78f27783))

## [0.4.1](https://github.com/LuisOsuna117/terraform-aws-agentcore/compare/v0.4.0...v0.4.1) (2026-02-27)

### 📖 Documentation

* polish README — fix emoji glitches, clarify BYO note, improve table, add Windows/CI callout ([6e5db49](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/6e5db49e98136a6ccced45397f12b72fb359f34c))

## [0.4.0](https://github.com/LuisOsuna117/terraform-aws-agentcore/compare/v0.3.1...v0.4.0) (2026-02-27)

### 🚀 Features

* allow_bedrock_invoke_all, ecr_pull_principals, codebuild_start_build_command; enterprise patterns in README ([f54e2d2](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/f54e2d242a25c430c2d6320822822ecf262a93d8))

## [0.3.1](https://github.com/LuisOsuna117/terraform-aws-agentcore/compare/v0.3.0...v0.3.1) (2026-02-27)

### 📖 Documentation

* improve README with quickstart, emojis, security notes, BYO clarification ([b904f8e](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/b904f8e30d00253c777e5155d68a4da4d596cf3e))

## [0.3.0](https://github.com/LuisOsuna117/terraform-aws-agentcore/compare/v0.2.0...v0.3.0) (2026-02-27)

### 🚀 Features

* add modules/memory and modules/gateway, wire into root wrapper, consolidate root to 4 files, update README for v0.3.0 ([2eb8558](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/2eb85584719132f2856a3e12062bfe349696f4dd))

## [0.2.0](https://github.com/LuisOsuna117/terraform-aws-agentcore/compare/v0.1.7...v0.2.0) (2026-02-27)

### 🚀 Features

* BYO image, trigger toggle, submodule refactor, create_build_pipeline API ([ad848cc](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/ad848ccf6c46d8229d6b36423da69121786e5d96))

## [0.1.7](https://github.com/LuisOsuna117/terraform-aws-agentcore/compare/v0.1.6...v0.1.7) (2026-02-27)

### 🐛 Bug Fixes

* **iam:** split CloudWatch Logs statements to fix log stream permissions ([b16f513](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/b16f5139371d8f4ee2f453da56888894acdd5d16))

## [0.1.6](https://github.com/LuisOsuna117/terraform-aws-agentcore/compare/v0.1.5...v0.1.6) (2026-02-25)

### 🐛 Bug Fixes

* **security:** add S3 AES-256 encryption, suppress ECR mutable-tag finding ([7843dcc](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/7843dcc376f26ab378bda0e5000efe70ecbf7308))

## [0.1.5](https://github.com/LuisOsuna117/terraform-aws-agentcore/compare/v0.1.4...v0.1.5) (2026-02-25)

### 🐛 Bug Fixes

* **ci:** separate Trivy table gate from SARIF upload, fix exit-code-1 on empty SARIF ([a9bf595](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/a9bf5959681d7a4a3030d8570c61c911a07b7ca4))

## [0.1.4](https://github.com/LuisOsuna117/terraform-aws-agentcore/compare/v0.1.3...v0.1.4) (2026-02-25)

### 🐛 Bug Fixes

* **ci:** add Trivy table-format step to surface unsuppressed findings ([024da07](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/024da07baf0d3796438e6af630cd2649c8cc9bc7))
* **ci:** suppress CodeBuild privileged_mode finding (AVD-AWS-0008) ([92fe11c](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/92fe11c76146480534b6f22d89ce996f388a2087))

## [0.1.3](https://github.com/LuisOsuna117/terraform-aws-agentcore/compare/v0.1.2...v0.1.3) (2026-02-25)

### 🐛 Bug Fixes

* **ci:** use TRIVY_SKIP_CHECK_UPDATE env var to suppress policy download ([36a6054](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/36a6054dd6644b379b85d6971341b7ad18765a1c))

## [0.1.2](https://github.com/LuisOsuna117/terraform-aws-agentcore/compare/v0.1.1...v0.1.2) (2026-02-25)

### 🐛 Bug Fixes

* **ci:** suppress noisy Trivy Rego parse errors via skip-check-update ([d489a8e](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/d489a8eaf5596e63a2c03f58b2a7716de557f728))

## [0.1.1](https://github.com/LuisOsuna117/terraform-aws-agentcore/compare/v0.1.0...v0.1.1) (2026-02-25)

### 🐛 Bug Fixes

* **ci:** pin Trivy to v0.59.1, add .trivyignore for module-level suppressions ([e8b8029](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/e8b8029e7fff5b2142dba83ceb376142ac0dffa5))
