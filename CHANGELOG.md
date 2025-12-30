## [0.1.0-rc.3] - 2025-12-29

### ✨ Features
- Implement trusted publishing for PyPI and npm ([`f6d0782`](https://github.com/santosr2/luma/commit/f6d0782020de47807d7662c42e75375f5e5a9325)) by [@santosr2](https://github.com/santosr2)
- Rename npm package to luma-js and implement trusted publishing ([`7d3a779`](https://github.com/santosr2/luma/commit/7d3a779811a177496b4034cdf8bd03435302ba6c)) by [@santosr2](https://github.com/santosr2)


### 🐛 Bug Fixes
- **ci**: Enable publishing for pre-releases ([`723b63a`](https://github.com/santosr2/luma/commit/723b63a2217d31980126eaa6fa4cb3f234ba35c5)) by [@santosr2](https://github.com/santosr2)
- **publishing**: Resolve all publishing blockers for registries ([`1f5f7bd`](https://github.com/santosr2/luma/commit/1f5f7bd0f598f81e6a5a5a8ad550e42aa4d65d79)) by [@santosr2](https://github.com/santosr2)
- **release**: Enable LuaRocks publishing for pre-releases ([`e8cc16f`](https://github.com/santosr2/luma/commit/e8cc16f395e71331815dc4604c4e09823fd72562)) by [@santosr2](https://github.com/santosr2)
- **docker**: Use scm-1 rockspec for pre-releases ([`41aa23d`](https://github.com/santosr2/luma/commit/41aa23dafc0e87f5efa7c5b84d7014e580873981)) by [@santosr2](https://github.com/santosr2)
- **docker**: Correct Dockerfile syntax for sed commands ([`23db2e9`](https://github.com/santosr2/luma/commit/23db2e960b8da400a3779397fd76a28e1104191f)) by [@santosr2](https://github.com/santosr2)
- **docker**: Install Luma modules directly without luarocks ([`89ed450`](https://github.com/santosr2/luma/commit/89ed4508df42c9cc56bbe3fe5d00e01b861d07cb)) by [@santosr2](https://github.com/santosr2)
- **cli**: Use correct version field in --version output ([`78331ec`](https://github.com/santosr2/luma/commit/78331ec47d05881a54368fbe448cfe86c5d1285f)) by [@santosr2](https://github.com/santosr2)
- **bumpversion**: Remove Dockerfile from version bump config ([`a0c5f79`](https://github.com/santosr2/luma/commit/a0c5f7957c5ddef996d47ce5e9ff742b21080022)) by [@santosr2](https://github.com/santosr2)
- **release**: Consolidate publishing into release workflow ([`5fe0c40`](https://github.com/santosr2/luma/commit/5fe0c40819969cbacfd38f5f6fbd0ce086e27cc9)) by [@santosr2](https://github.com/santosr2)
- **release**: Remove false positives and consolidate all publishing ([`ae0d03f`](https://github.com/santosr2/luma/commit/ae0d03f352b0d73c6b35b45ef7d6da79d851c5eb)) by [@santosr2](https://github.com/santosr2)
- **release**: Create rockspec in luarocks job ([`0e3a792`](https://github.com/santosr2/luma/commit/0e3a792fdd6d09347de25076aaf4952e3ee010bd)) by [@santosr2](https://github.com/santosr2)
- **release**: Use scm-1 for pre-release rockspecs ([`bb84adf`](https://github.com/santosr2/luma/commit/bb84adff90e60f2ef0fcba436b86d67a8e04ce1e)) by [@santosr2](https://github.com/santosr2)
- **release**: Clarify Go module availability (not publishing) ([`74610f0`](https://github.com/santosr2/luma/commit/74610f0507019a7c75a165b9fc251a05be461b8d)) by [@santosr2](https://github.com/santosr2)
- **release**: Restore Go documentation generation ([`41d4e73`](https://github.com/santosr2/luma/commit/41d4e73133bda66533228582a69c3785e0c15614)) by [@santosr2](https://github.com/santosr2)


### ♻️  Refactor
- **naming**: Standardize package names across registries ([`a7c16da`](https://github.com/santosr2/luma/commit/a7c16da7797712355001c6154b0ee537879ce198)) by [@santosr2](https://github.com/santosr2)


### ⚙️  Miscellaneous Tasks
- **release**: Update CHANGELOG.md for v0.1.0-rc.2 ([`220cc06`](https://github.com/santosr2/luma/commit/220cc06a9edf7ecb0d652672b8db1bb6d3df7074)) by [@github-actions[bot]](https://github.com/github-actions[bot])
- Bump version 0.1.0-rc.2 → 0.1.0-rc.3 ([`6988661`](https://github.com/santosr2/luma/commit/6988661827b259e32d2b37b35f3d90ba70fc91b5)) by [@santosr2](https://github.com/santosr2)
- **release**: Update CHANGELOG.md for v0.1.0-rc.3 ([`fcbf3ca`](https://github.com/santosr2/luma/commit/fcbf3cafb9d9f1dcdb774a010cda59c56c4e82cd)) by [@github-actions[bot]](https://github.com/github-actions[bot])
- **release**: Update CHANGELOG.md for v0.1.0-rc.3 ([`94cf1c2`](https://github.com/santosr2/luma/commit/94cf1c2f853922073e529ba35874361237ff6533)) by [@github-actions[bot]](https://github.com/github-actions[bot])
- **release**: Update CHANGELOG.md for v0.1.0-rc.3 ([`3e4b106`](https://github.com/santosr2/luma/commit/3e4b1060870da4478311d6056711a7f1fdc76cf9)) by [@github-actions[bot]](https://github.com/github-actions[bot])


## [0.1.0-rc.2] - 2025-12-29

### ✨ Features
- **wasm**: Complete WASM build with embedded Lua modules ([`fd85666`](https://github.com/santosr2/luma/commit/fd856668b918c8ee7b36126b708cb567ffc5a727)) by [@santosr2](https://github.com/santosr2)
- **vscode**: Complete VSCode extension with lumalint integration ([`bfc36f9`](https://github.com/santosr2/luma/commit/bfc36f942c672d2237a2398e3ef0e6f4d6c44022)) by [@santosr2](https://github.com/santosr2)
- **terraform**: Add Terraform provider implementation ([`270665d`](https://github.com/santosr2/luma/commit/270665d2ab2b52e35a9c4f7e94e8fad97afaf3c9)) by [@santosr2](https://github.com/santosr2)
- **wasm**: Complete WASM implementation - all 25 tests passing ([`396eac7`](https://github.com/santosr2/luma/commit/396eac78ba2fe90366033cc51d2d6682b0ea1e18)) by [@santosr2](https://github.com/santosr2)


### 🐛 Bug Fixes
- **lexer**: Preserve hyphens between interpolations ([`dc095e0`](https://github.com/santosr2/luma/commit/dc095e0e9e6cf38bbe3ca0054de29f1c9543f0f2)) by [@santosr2](https://github.com/santosr2)
- **lexer**: Properly distinguish dash-trim from literal hyphens ([`06ad5f1`](https://github.com/santosr2/luma/commit/06ad5f1e86b6e1a675709afb624f00c53c4e88b6)) by [@santosr2](https://github.com/santosr2)
- **bindings**: Sync Lua modules and fix test issues across all bindings ([`169b6bd`](https://github.com/santosr2/luma/commit/169b6bd38c7184c58ac2c721bc29497674c02100)) by [@santosr2](https://github.com/santosr2)
- **lexer**: Fix dash-trim with leading whitespace - all 589 tests passing! ([`b1c21fe`](https://github.com/santosr2/luma/commit/b1c21fee7a7c75ddb3b3fbab6a034c177966b06d)) by [@santosr2](https://github.com/santosr2)
- **tests**: Skip break/continue tests on Lua 5.1 ([`3845581`](https://github.com/santosr2/luma/commit/38455814d8ab56e7e8b6e6e978ad3b95d10680fc)) by [@santosr2](https://github.com/santosr2)
- **bumpversion**: Remove duplicate docker/build.sh entry ([`43c613e`](https://github.com/santosr2/luma/commit/43c613e1ba222da841c853016709f57efc6edfff)) by [@santosr2](https://github.com/santosr2)
- **bumpversion**: Add missing files to version bump config ([`889d130`](https://github.com/santosr2/luma/commit/889d1305972d2860f8704462d93548b5779fa6a9)) by [@santosr2](https://github.com/santosr2)


### 📚 Documentation
- **ecosystem**: Update to reflect actual implementation status ([`7b87b7b`](https://github.com/santosr2/luma/commit/7b87b7b3bb765f9d492ff6764c07386adffafeb5)) by [@santosr2](https://github.com/santosr2)
- **ecosystem**: Update with completed Terraform provider ([`7c25959`](https://github.com/santosr2/luma/commit/7c25959d093f2b70d7af7ced833717a9139b03c9)) by [@santosr2](https://github.com/santosr2)


### 🎨 Styling
- **lexer**: Fix luacheck warnings in native.lua ([`de23e69`](https://github.com/santosr2/luma/commit/de23e69574d3620128c601ff20a9c7c948e7455a)) by [@santosr2](https://github.com/santosr2)
- **lexer**: Fix luacheck warning - remove trailing whitespace ([`09f8fd1`](https://github.com/santosr2/luma/commit/09f8fd191b9aac4b9dffabfa1906a2ed25733aab)) by [@santosr2](https://github.com/santosr2)


### 🧪 Testing
- **loops**: Enable break/continue directive tests ([`8599c48`](https://github.com/santosr2/luma/commit/8599c48eb05fe1f12029470f40f136fbd0a40ee9)) by [@santosr2](https://github.com/santosr2)


### ⚙️  Miscellaneous Tasks
- **release**: Update CHANGELOG.md for v0.1.0-rc.1 ([`9204ed9`](https://github.com/santosr2/luma/commit/9204ed91b3e6bc6ca91849b6b6d4d1c55e059eea)) by [@github-actions[bot]](https://github.com/github-actions[bot])
- Remove duplicate extensions/ directory ([`c6fc8a6`](https://github.com/santosr2/luma/commit/c6fc8a6cdad526207a56d413f7b722802888701a)) by [@santosr2](https://github.com/santosr2)
- **release**: Bump version to 0.1.0-rc.2 ([`12a3a5c`](https://github.com/santosr2/luma/commit/12a3a5cd96a049033d1760fa2d4009aaa79bbd30)) by [@santosr2](https://github.com/santosr2)


### Sync
- **bindings**: Sync dash-trim fix to all bindings ([`25256ce`](https://github.com/santosr2/luma/commit/25256ce95cac1038b516c365739eecae2684dee7)) by [@santosr2](https://github.com/santosr2)


## [0.1.0-rc.1] - 2025-12-23

### ✨ Features
- Initial structure ([`ccb9023`](https://github.com/santosr2/luma/commit/ccb90232f1667cd3a4d40abdd5304197862b5164)) by [@santosr2](https://github.com/santosr2)
- Add Jinja2 compatibility, template inheritance, and loop enhancements ([`e882aa0`](https://github.com/santosr2/luma/commit/e882aa0bd793859818fc04d1436e0b132707453c)) by [@santosr2](https://github.com/santosr2)
- Preserve indentation for multiline content in placeholders ([`177c391`](https://github.com/santosr2/luma/commit/177c391e980b348072d3a004aa81ca15760f6527)) by [@santosr2](https://github.com/santosr2)
- Add Jinja2 migration tools and whitespace control design ([`d0d1f59`](https://github.com/santosr2/luma/commit/d0d1f59c8e7818b96980d5f8607aa3ad90e37362)) by [@santosr2](https://github.com/santosr2)
- Implement super() function for template inheritance ([`65df5c0`](https://github.com/santosr2/luma/commit/65df5c0e55c9813a765c48cb370664fc57a4dd87)) by [@santosr2](https://github.com/santosr2)
- Implement Jinja2 trim-before ({%- {{-) for whitespace control ([`9996e32`](https://github.com/santosr2/luma/commit/9996e32c04540846a5607d0f95da4855161e3d40)) by [@santosr2](https://github.com/santosr2)
- Implement context-aware inline mode for directives ([`bb9941a`](https://github.com/santosr2/luma/commit/bb9941aad43d78c9e8da6880d3ce96cf6de5b267)) by [@santosr2](https://github.com/santosr2)
- Implement filter named arguments for Jinja2 compatibility ([`7d6c120`](https://github.com/santosr2/luma/commit/7d6c1204284d60a6f1c09803812b4f5d223e1b5d)) by [@santosr2](https://github.com/santosr2)
- Implement dash (-) trimming for Luma native syntax ([`c83f7a5`](https://github.com/santosr2/luma/commit/c83f7a5a7aa0a4d98a22afda060d599fe82eb3e8)) by [@santosr2](https://github.com/santosr2)
- Implement set block syntax for Jinja2 compatibility ([`e5dfad4`](https://github.com/santosr2/luma/commit/e5dfad4fab02bb93715bfd78ee0f8005205a5974)) by [@santosr2](https://github.com/santosr2)
- Implement additional test expressions (escaped, in) ([`7f5f596`](https://github.com/santosr2/luma/commit/7f5f596b620fb3acf4a7e3929a077ea24914d7cf)) by [@santosr2](https://github.com/santosr2)
- Implement selective imports (from ... import) ([`877fed3`](https://github.com/santosr2/luma/commit/877fed324c551f0bb06f5152f9e360ddf5026c7e)) by [@santosr2](https://github.com/santosr2)
- Implement autoescape blocks for XSS protection ([`f6c286b`](https://github.com/santosr2/luma/commit/f6c286b8d27aae5ce8deae53642bb8cdb5d85c81)) by [@santosr2](https://github.com/santosr2)
- Implement scoped blocks for variable isolation ([`e2e2d5f`](https://github.com/santosr2/luma/commit/e2e2d5fe4ca522bfcec5b66f8370eff201fac389)) by [@santosr2](https://github.com/santosr2)
- Implement call with caller pattern for advanced macros ([`6d6173d`](https://github.com/santosr2/luma/commit/6d6173d528a29477974c5da50d2e802c2943880a)) by [@santosr2](https://github.com/santosr2)
- Implement {% with %} directive for scoped variables ([`c3d0f9b`](https://github.com/santosr2/luma/commit/c3d0f9bcaa1811cd2a51c955ebb4e07570e02980)) by [@santosr2](https://github.com/santosr2)
- Implement {% filter %} blocks for content filtering ([`eda6693`](https://github.com/santosr2/luma/commit/eda6693a5520e43a5487ffbc52521310559e6dcf)) by [@santosr2](https://github.com/santosr2)
- Implement namespace() for mutable variables in loops ([`6497895`](https://github.com/santosr2/luma/commit/6497895e10e6cfb0810755d20ec41458f0b96cb3)) by [@santosr2](https://github.com/santosr2)
- Add context control modifiers to {% include %} ([`198f985`](https://github.com/santosr2/luma/commit/198f9851c7f2853efac6a18a90e687632a0136ff)) by [@santosr2](https://github.com/santosr2)
- Implement {% do %} statement for side effects ([`7955e1d`](https://github.com/santosr2/luma/commit/7955e1de60ca363ffa371bf20389b298f628ecc4)) by [@santosr2](https://github.com/santosr2)
- Add benchmarks, examples, and comprehensive documentation ([`057d1b0`](https://github.com/santosr2/luma/commit/057d1b0d1484dbfdf3b1154186da2e60712f926b)) by [@santosr2](https://github.com/santosr2)
- Add CLI tool with multiple commands ([`02dc0a2`](https://github.com/santosr2/luma/commit/02dc0a26b3e7d4af7025ed0ecf1878a6e86c6720)) by [@santosr2](https://github.com/santosr2)
- Enhance Makefile with benchmark and example targets ([`4261d31`](https://github.com/santosr2/luma/commit/4261d31e4477c18d86241f56a445147c5a1220cf)) by [@santosr2](https://github.com/santosr2)
- Add semicolon delimiter for inline directives ([`b0e92b0`](https://github.com/santosr2/luma/commit/b0e92b03053108aca24a8fa6c3ba907d03930c9c)) by [@santosr2](https://github.com/santosr2)
- Add multiline directive support with comma continuation ([`b7bc4ac`](https://github.com/santosr2/luma/commit/b7bc4ac99cddfb59593484e6d031c7d400ac8e7b)) by [@santosr2](https://github.com/santosr2)
- Add Python-like methods to lists and dicts ([`ee9613c`](https://github.com/santosr2/luma/commit/ee9613c6cbfef79211deda565bd90b19aa403c3c)) by [@santosr2](https://github.com/santosr2)
- Add default parameter values for macros ([`540a34b`](https://github.com/santosr2/luma/commit/540a34b152988034f95bcbcf1d3a33f1aba7a8be)) by [@santosr2](https://github.com/santosr2)
- Add mixed syntax support in Jinja2 mode ([`7419870`](https://github.com/santosr2/luma/commit/7419870b6d70cc9fe84b0f556a3f65c97a003a47)) by [@santosr2](https://github.com/santosr2)
- Implement ternary expressions (value if cond else alt) ([`ed93614`](https://github.com/santosr2/luma/commit/ed93614f756c63d49ce13275cd7fcb2af8488c0f)) by [@santosr2](https://github.com/santosr2)
- Implement selective import system and namespace.__setattr__ ([`12198dd`](https://github.com/santosr2/luma/commit/12198dd3561207ea3a1885c6ba74f022587f7455)) by [@santosr2](https://github.com/santosr2)
- Add center filter and fix truncate spacing ([`d256b63`](https://github.com/santosr2/luma/commit/d256b63a9425d20eb732c6012e260431c790b184)) by [@santosr2](https://github.com/santosr2)
- Add comprehensive documentation website for GitHub Pages ([`b7a3739`](https://github.com/santosr2/luma/commit/b7a37394c41ebe44669580eacc30dd16e61a72f5)) by [@santosr2](https://github.com/santosr2)
- Add distribution channels (Homebrew, Docker, LuaRocks) ([`f5c26b3`](https://github.com/santosr2/luma/commit/f5c26b3eafddc2d15b84ed76acf0ab9275cfdc41)) by [@santosr2](https://github.com/santosr2)
- Enhance CLI with stdin, YAML support, and better error handling ([`5879a51`](https://github.com/santosr2/luma/commit/5879a51e80858fd3a05544c0ec41b7917fb19f9b)) by [@santosr2](https://github.com/santosr2)
- Add PyPI publishing infrastructure for Python bindings ([`5c50770`](https://github.com/santosr2/luma/commit/5c5077072a07b04b727ae905269d7b7ff6c2b5a6)) by [@santosr2](https://github.com/santosr2)
- Add complete ecosystem scaffolding (steps 6-11) ([`7ebc4a0`](https://github.com/santosr2/luma/commit/7ebc4a0def05f2db47f15baed009816f6c6b5292)) by [@santosr2](https://github.com/santosr2)
- Complete Go bindings implementation (v0.1.0) ([`faf370a`](https://github.com/santosr2/luma/commit/faf370a1b10678d0b9f8e21e25b66e73e90a1670)) by [@santosr2](https://github.com/santosr2)
- Complete Helm integration implementation (v0.1.0) ([`3759959`](https://github.com/santosr2/luma/commit/37599597f6c46cf4b59a4492c6e7d56c89707a3b)) by [@santosr2](https://github.com/santosr2)
- Complete Node.js bindings implementation (v0.1.0) ([`d9f175f`](https://github.com/santosr2/luma/commit/d9f175f31a76c0202bace346c701db845ca816be)) by [@santosr2](https://github.com/santosr2)
- Complete Lumalint implementation (v0.1.0) ([`2cad6a5`](https://github.com/santosr2/luma/commit/2cad6a5da82e2cbb89a5244b4519a7d8cc74d841)) by [@santosr2](https://github.com/santosr2)
- Complete VSCode extension implementation (v0.1.0) ([`ef083b7`](https://github.com/santosr2/luma/commit/ef083b7c71686ab87ac1d49a3cf693995db9e28f)) by [@santosr2](https://github.com/santosr2)
- Complete WASM build implementation (v0.1.0) ([`4131621`](https://github.com/santosr2/luma/commit/4131621eb9d6f67139f18577d798f01db9698051)) by [@santosr2](https://github.com/santosr2)
- Enhance Python bindings to 100% completeness ([`314d6eb`](https://github.com/santosr2/luma/commit/314d6ebca92bceeeb468196691cb5694ccfe9c43)) by [@santosr2](https://github.com/santosr2)
- **release**: Improve release process with proper tooling ([`1293feb`](https://github.com/santosr2/luma/commit/1293feb9678a92ec6f0b55c2d2cf4cdd2ad3c42f)) by [@santosr2](https://github.com/santosr2)


### 🐛 Bug Fixes
- Correct HTML escaping and update Makefile for local installs ([`00e4b3c`](https://github.com/santosr2/luma/commit/00e4b3c1f95a0cfe101cf02ef516d3d7a7aa4442)) by [@santosr2](https://github.com/santosr2)
- Implement member assignment and function named arguments ([`b93ea84`](https://github.com/santosr2/luma/commit/b93ea8492b8dec2d78d2bbb5264dc2265bf7ecdc)) by [@santosr2](https://github.com/santosr2)
- Implement do statement with assignments ([`fbdfe5a`](https://github.com/santosr2/luma/commit/fbdfe5a16f2bc88e99d852250971630a33463930)) by [@santosr2](https://github.com/santosr2)
- Support absolute paths in template loader ([`95487b7`](https://github.com/santosr2/luma/commit/95487b7212aaa287bf651cff16add8d3eff320a0)) by [@santosr2](https://github.com/santosr2)
- Parse 'import' keyword in from...import statements ([`944ad27`](https://github.com/santosr2/luma/commit/944ad2711546b03cdf55c64d653746e8caf2ddcd)) by [@santosr2](https://github.com/santosr2)
- Add string concatenation (..) operator and resolve CI issues ([`7dd8bb3`](https://github.com/santosr2/luma/commit/7dd8bb3ef09dfd7d3f89a013802c4c32e78f54a3)) by [@santosr2](https://github.com/santosr2)
- Resolve keyword conflicts and add missing runtime functions ([`57a4243`](https://github.com/santosr2/luma/commit/57a4243ec16e16814e951d2a0045bdf8eb01fcb5)) by [@santosr2](https://github.com/santosr2)
- Improve macro caller() support and call-with-caller parsing ([`bf6b70b`](https://github.com/santosr2/luma/commit/bf6b70b6d030652c51363aa4dbfa9861a701068a)) by [@santosr2](https://github.com/santosr2)
- Add 'is in' test expression support ([`82630b5`](https://github.com/santosr2/luma/commit/82630b50d198b221493c162aebf84f256d1a3d30)) by [@santosr2](https://github.com/santosr2)
- Improve lexer handling of special characters in directive mode ([`7dc5227`](https://github.com/santosr2/luma/commit/7dc5227fbc4bccf2e7815e7570dba9b89e7d9bf7)) by [@santosr2](https://github.com/santosr2)
- Handle dash-trim markers in directive mode ([`bfcfd4f`](https://github.com/santosr2/luma/commit/bfcfd4fb412688759a0159c8678ec6f4acc92c82)) by [@santosr2](https://github.com/santosr2)
- Support Jinja2 dict syntax with = in table literals ([`90d6aaa`](https://github.com/santosr2/luma/commit/90d6aaa44af4dbbb8c5c7c74cdb9c83b9817ee4e)) by [@santosr2](https://github.com/santosr2)
- Handle 'is not in' test expression ([`129b3d9`](https://github.com/santosr2/luma/commit/129b3d9bbe3b8067e5205daefc6282d219389a33)) by [@santosr2](https://github.com/santosr2)
- Use correct field name for MEMBER_ACCESS in assignments ([`ed8e831`](https://github.com/santosr2/luma/commit/ed8e831de7cd97b67cc08c48698afeff396926e6)) by [@santosr2](https://github.com/santosr2)
- Support 'scoped' modifier for block directive ([`31ffa7c`](https://github.com/santosr2/luma/commit/31ffa7c03089cf3396aea9c9f6b9ffb2f73b7751)) by [@santosr2](https://github.com/santosr2)
- Only wrap tables in let/set assignments, not all literals ([`9db5bc7`](https://github.com/santosr2/luma/commit/9db5bc7c8c3ca3b82b8a0713af609bb9f66ebc1d)) by [@santosr2](https://github.com/santosr2)
- Properly detect call-with-caller vs simple macro calls ([`b4a2aa8`](https://github.com/santosr2/luma/commit/b4a2aa8f1002760fd852bc4cad9b93dfa6cbbd35)) by [@santosr2](https://github.com/santosr2)
- Make Lua built-ins available in template context ([`c805fad`](https://github.com/santosr2/luma/commit/c805fadcb807b650c0d95a72f7b0e1bfb537ba91)) by [@santosr2](https://github.com/santosr2)
- Support ipairs/pairs in for loops ([`ab928b9`](https://github.com/santosr2/luma/commit/ab928b997d4413a257c945f29a29c0d3f0eed25e)) by [@santosr2](https://github.com/santosr2)
- Wrap nested table literals with Python-like methods ([`fc94e4f`](https://github.com/santosr2/luma/commit/fc94e4fd7ddb5197ab9f53ab5469dff0afae3192)) by [@santosr2](https://github.com/santosr2)
- Make 'scoped' context-sensitive keyword ([`66d7daf`](https://github.com/santosr2/luma/commit/66d7daf8366b20ad6d2fa817fa4220d315d67b47)) by [@santosr2](https://github.com/santosr2)
- Mark caller() output as safe to prevent HTML escaping ([`d1e0d99`](https://github.com/santosr2/luma/commit/d1e0d9931e8612ce57150f22bc465ec781e74c9f)) by [@santosr2](https://github.com/santosr2)
- Center filter line-by-line and filter block safe handling ([`09462e3`](https://github.com/santosr2/luma/commit/09462e33a09652bcd53a707518e0e90478a9cc69)) by [@santosr2](https://github.com/santosr2)
- Escape forward slashes in HTML for XSS protection ([`224712c`](https://github.com/santosr2/luma/commit/224712c44da48a32d5ae776bddcddf9ef11ddc4f)) by [@santosr2](https://github.com/santosr2)
- Preserve safe context in do assignments with autoescape ([`37e206f`](https://github.com/santosr2/luma/commit/37e206f4790cf0ba8e65c03cc20cac8ec6433c53)) by [@santosr2](https://github.com/santosr2)
- Add caller support in expressions for inline usage ([`940d44b`](https://github.com/santosr2/luma/commit/940d44bac76750d6d5d0d0a9e008642344edbb45)) by [@santosr2](https://github.com/santosr2)
- Migrate_spec and jinja_trim_spec all tests passing ([`fc44a96`](https://github.com/santosr2/luma/commit/fc44a96fc89bc64c0c1a3ad9a7c8a386aa35cee8)) by [@santosr2](https://github.com/santosr2)
- Complete dash_trim and inline_mode tests (76 tests fixed) ([`26da255`](https://github.com/santosr2/luma/commit/26da25553764dce9580eec0dd1df71955fd33bb3)) by [@santosr2](https://github.com/santosr2)
- Achieve 100% test pass rate (589/589 tests passing) ([`cfa69e8`](https://github.com/santosr2/luma/commit/cfa69e89ce37fc7b5675421e46a54c7c3b5fee82)) by [@santosr2](https://github.com/santosr2)
- Escape Jinja2/Luma syntax in Jekyll docs to prevent Liquid parsing ([`02855d3`](https://github.com/santosr2/luma/commit/02855d3a2297539f987e4f595a60f0de48e0d96d)) by [@santosr2](https://github.com/santosr2)
- Escape nested raw/endraw tags in Jekyll documentation ([`d55bd3f`](https://github.com/santosr2/luma/commit/d55bd3f0a75cda176ad692ba9bb0d97f8dc2ba4e)) by [@santosr2](https://github.com/santosr2)
- Disable Liquid processing for documentation pages ([`e4f1255`](https://github.com/santosr2/luma/commit/e4f1255a8df05fb601bac23fa7b1e327cfdf6bf5)) by [@santosr2](https://github.com/santosr2)
- Remove alpha pre-release tag from version 0.1.0 ([`8258308`](https://github.com/santosr2/luma/commit/8258308ddfbf07cd6d42ec8c3161316c49aed3ed)) by [@santosr2](https://github.com/santosr2)
- Remove pre_lua custom part from bumpversion config ([`4db6b11`](https://github.com/santosr2/luma/commit/4db6b11f19972348d15190fb9fecc26b52a804ea)) by [@santosr2](https://github.com/santosr2)
- Configure pre-release parts to support stable releases ([`fe77466`](https://github.com/santosr2/luma/commit/fe77466718ca41793a91e4f7a9e022e00728df66)) by [@santosr2](https://github.com/santosr2)
- Simplify bumpversion config to use single pre-release part ([`97a6d4a`](https://github.com/santosr2/luma/commit/97a6d4abcc77437181df8f696298349eef8e588f)) by [@santosr2](https://github.com/santosr2)
- Ignore cyclomatic complexity warnings in CI workflow ([`8a8e7de`](https://github.com/santosr2/luma/commit/8a8e7ded29231edd1dc1a2d0ab196c6b7f6e5427)) by [@santosr2](https://github.com/santosr2)
- Update GitHub workflows for consistency and compatibility ([`e9e244a`](https://github.com/santosr2/luma/commit/e9e244a10d4db0cf3db16b571491949e3bca2b22)) by [@santosr2](https://github.com/santosr2)
- Improve CI and docs workflows reliability ([`c8158e9`](https://github.com/santosr2/luma/commit/c8158e91a18d3aa6c75a1fb4101e1fda6dec7f30)) by [@santosr2](https://github.com/santosr2)
- Add jekyll-default-layout plugin for better page rendering ([`5b66010`](https://github.com/santosr2/luma/commit/5b66010f7eaf2bc7969ad41ea012c9e6e435c408)) by [@santosr2](https://github.com/santosr2)
- Add newline at end of Gemfile ([`5843100`](https://github.com/santosr2/luma/commit/5843100efe6cd28457b5ec93651922da8bf30771)) by [@santosr2](https://github.com/santosr2)
- Resolve CI failures and add workflows for bindings/integrations ([`190ab45`](https://github.com/santosr2/luma/commit/190ab4507e5caf62097292bdc22216a6607b6775)) by [@santosr2](https://github.com/santosr2)
- Standardize bindings workflows and fix Go bindings issues ([`8785b12`](https://github.com/santosr2/luma/commit/8785b121c5262556da340b56dc98530b0af1a62e)) by [@santosr2](https://github.com/santosr2)
- Escape all Jinja2/Liquid syntax in documentation for Jekyll ([`81349b5`](https://github.com/santosr2/luma/commit/81349b5ff3a602bd2e2f03baeaf548ecc7a58612)) by [@santosr2](https://github.com/santosr2)
- Escape all Jinja2 syntax in docs and remove LuaJIT from workflows ([`07ab9c3`](https://github.com/santosr2/luma/commit/07ab9c3b7ab982fe620b2f027ce1b538ad852be3)) by [@santosr2](https://github.com/santosr2)
- Mark break/continue tests as pending due to codegen issues ([`42cd788`](https://github.com/santosr2/luma/commit/42cd7887758e067b50a45b3fc92bad031af6afb6)) by [@santosr2](https://github.com/santosr2)
- **nodejs**: Add missing package-lock.json for CI cache ([`58b22aa`](https://github.com/santosr2/luma/commit/58b22aa34dd80da67279e41729a236bf204d186c)) by [@santosr2](https://github.com/santosr2)
- **bindings**: Fix Lua module loading in Python and Go bindings ([`dc066cb`](https://github.com/santosr2/luma/commit/dc066cbd0415ff8adfcb9eec35a4d4dd414bc67f)) by [@santosr2](https://github.com/santosr2)
- **bindings**: Fix Windows path handling and add TypeScript declarations ([`7bb1019`](https://github.com/santosr2/luma/commit/7bb101954937ad30ac884329bdbc8f87e474127a)) by [@santosr2](https://github.com/santosr2)
- **nodejs**: Fix TypeScript type declarations and duplicate exports ([`ff2d5c9`](https://github.com/santosr2/luma/commit/ff2d5c9df198fbbe66cf4304337b8926157d12a0)) by [@santosr2](https://github.com/santosr2)
- **nodejs**: Simplify type declarations and escape template literal ([`4adaf7f`](https://github.com/santosr2/luma/commit/4adaf7f89ac7b0a456dcbcdf27a1ccadbb278918)) by [@santosr2](https://github.com/santosr2)
- **nodejs**: Fix TypeScript type references and template literal escaping ([`b7d1dea`](https://github.com/santosr2/luma/commit/b7d1deaf859a4900e9f2af45eee0482faa885866)) by [@santosr2](https://github.com/santosr2)
- **helm**: Fix template syntax and add debug output to test ([`83bbc75`](https://github.com/santosr2/luma/commit/83bbc75bd0a27e5885053c4b1b9569137d8f8c28)) by [@santosr2](https://github.com/santosr2)
- **nodejs+helm**: Fix runtime errors in both bindings ([`10366ad`](https://github.com/santosr2/luma/commit/10366ade7cba60de467f6a01ddb16a9e3e64580f)) by [@santosr2](https://github.com/santosr2)
- **nodejs+helm**: Fix fengari-interop import and Helm template concatenation ([`9ded711`](https://github.com/santosr2/luma/commit/9ded71151c988ff8777a37a4668cbea12af9413f)) by [@santosr2](https://github.com/santosr2)
- **nodejs**: Use require() for fengari-interop CommonJS module ([`af55341`](https://github.com/santosr2/luma/commit/af55341ce787a1743fc10e1e5324f71e98c5860b)) by [@santosr2](https://github.com/santosr2)
- **helm**: Use quoted string for template name with interpolation ([`9b98f53`](https://github.com/santosr2/luma/commit/9b98f53ee1c9e1ad62f7b6df6ee4939a1211bc24)) by [@santosr2](https://github.com/santosr2)
- **nodejs+helm**: Add eslint-disable and workaround Luma hyphen bug ([`b5da0fa`](https://github.com/santosr2/luma/commit/b5da0fa7f1f0b77646aeeb1a205473f7ad49a206)) by [@santosr2](https://github.com/santosr2)
- **nodejs**: Use fengari.to_luastring instead of separate import ([`07ebd10`](https://github.com/santosr2/luma/commit/07ebd10b82a2f677fbea3880c35b4e9b8f4eb252)) by [@santosr2](https://github.com/santosr2)
- **nodejs**: Add TypeScript declarations for fengari-interop ([`ebaa3d0`](https://github.com/santosr2/luma/commit/ebaa3d0d25d66dc2c10bd82016b6c9ffb0276395)) by [@santosr2](https://github.com/santosr2)
- **nodejs**: Remove unused lua_State import from type declarations ([`3b7d434`](https://github.com/santosr2/luma/commit/3b7d4347ca28a933d7b5d891050d46720d58d6ed)) by [@santosr2](https://github.com/santosr2)
- **nodejs**: Use namespace import for fengari-interop ([`9652dc5`](https://github.com/santosr2/luma/commit/9652dc5883b1238bbba4cd54524b8ffa89690f85)) by [@santosr2](https://github.com/santosr2)
- **nodejs**: Use require with fallback for fengari-interop ([`c5d106e`](https://github.com/santosr2/luma/commit/c5d106e36e87958e982c5b864d409df65046ab41)) by [@santosr2](https://github.com/santosr2)
- **nodejs**: Use destructuring require for fengari-interop ([`d90e6cf`](https://github.com/santosr2/luma/commit/d90e6cfd5766b855fdb6b1df2a73b58be2130101)) by [@santosr2](https://github.com/santosr2)
- **nodejs**: Import to_luastring/to_jsstring from main fengari package ([`2cc2241`](https://github.com/santosr2/luma/commit/2cc2241a35dabe7ca52f8946bc4a34e9ad37d6ad)) by [@santosr2](https://github.com/santosr2)
- **nodejs**: Add to_jsstring/to_luastring to fengari type declarations ([`0c4f546`](https://github.com/santosr2/luma/commit/0c4f546a22b1f4469587c919615dfdd36e8bb90b)) by [@santosr2](https://github.com/santosr2)
- **nodejs**: Add module name aliases for init.lua files ([`d0b9d3b`](https://github.com/santosr2/luma/commit/d0b9d3bc96b6741ec87b25a88fe9c47bd0f2178c)) by [@santosr2](https://github.com/santosr2)
- **nodejs**: Update tests to match Lua number formatting and fix filter syntax ([`007e741`](https://github.com/santosr2/luma/commit/007e7413dae64d517bc160c7689ef2cb3bf28d36)) by [@santosr2](https://github.com/santosr2)
- **nodejs**: Fix remaining 2 test failures ([`0e7a50c`](https://github.com/santosr2/luma/commit/0e7a50c7106585347f5554b460d8924f081850ef)) by [@santosr2](https://github.com/santosr2)
- **ci**: Generate dev rockspec dynamically in CI workflow ([`ca1575a`](https://github.com/santosr2/luma/commit/ca1575ae257cf00f210e30bc90b4806f7b94b065)) by [@santosr2](https://github.com/santosr2)
- **release**: Configure bump-my-version for pre-release versions ([`f0d3461`](https://github.com/santosr2/luma/commit/f0d34613c36f0665d4d752b0ca605cb0f6a94ca4)) by [@santosr2](https://github.com/santosr2)
- **workflows**: Fix rockspec and tar issues across all workflows ([`1722763`](https://github.com/santosr2/luma/commit/172276371e139964c347aa69a22adef608c008ce)) by [@santosr2](https://github.com/santosr2)
- **release**: Improve changelog with GitHub usernames and better details ([`88cdfc0`](https://github.com/santosr2/luma/commit/88cdfc0c5eacb4a459784c66c214fff5fd02a693)) by [@santosr2](https://github.com/santosr2)
- **release**: Add proper error handling for git-cliff installation and execution ([`2013ece`](https://github.com/santosr2/luma/commit/2013ece1b760be0d92c57b69d87ba9a848d16394)) by [@santosr2](https://github.com/santosr2)
- **release**: Improve git-cliff installation robustness ([`cc5382c`](https://github.com/santosr2/luma/commit/cc5382c1bdd8592695144e5fa05b62a2bb725303)) by [@santosr2](https://github.com/santosr2)
- **release**: Use --current flag for git-cliff changelog generation ([`b0eabb7`](https://github.com/santosr2/luma/commit/b0eabb78a4850d9c1346f63d82cbd114596e8296)) by [@santosr2](https://github.com/santosr2)
- **release**: Use --tag flag for git-cliff changelog generation ([`dc90137`](https://github.com/santosr2/luma/commit/dc9013736d4656c01604464314e732fcd3424b3b)) by [@santosr2](https://github.com/santosr2)
- **release**: Correct git-cliff configuration ([`124c43b`](https://github.com/santosr2/luma/commit/124c43bf61ef0b339992f33fed5e5ca24411ed28)) by [@santosr2](https://github.com/santosr2)
- **release**: Generate complete changelog from all commits and update CHANGELOG.md ([`bfae0af`](https://github.com/santosr2/luma/commit/bfae0af05e20f30903348d9e183a02f1893c3307)) by [@santosr2](https://github.com/santosr2)
- **release**: Detect first release and generate changelog from all commits ([`8905979`](https://github.com/santosr2/luma/commit/89059793b1b339d7ad9de11eb4fe3e941e90c919)) by [@santosr2](https://github.com/santosr2)
- **release**: Skip CHANGELOG.md commit due to branch protection ([`fcf21f5`](https://github.com/santosr2/luma/commit/fcf21f5de13a086cd1c8fa37df07475c57b9c11a)) by [@santosr2](https://github.com/santosr2)
- **release**: Restore CHANGELOG.md commit to workflow ([`4a1212d`](https://github.com/santosr2/luma/commit/4a1212d512463a6295c505802cff887c32252ff1)) by [@santosr2](https://github.com/santosr2)
- **release**: Generate changelog from first commit to tag for initial release ([`e5961b1`](https://github.com/santosr2/luma/commit/e5961b1e7eec6ccbcca1a86e6f845c4f258dff79)) by [@santosr2](https://github.com/santosr2)
- **release**: Use no-range git-cliff for first release to capture all commits ([`cdc256c`](https://github.com/santosr2/luma/commit/cdc256c615d1f607e91ef5e12109042d578ed69f)) by [@santosr2](https://github.com/santosr2)
- **release**: Explicitly use commit range from repo root to HEAD for first release ([`178dd56`](https://github.com/santosr2/luma/commit/178dd56b1b341506275c19e26f2800c364485b38)) by [@santosr2](https://github.com/santosr2)
- **release**: Fetch full git history for complete changelog generation ([`35056e4`](https://github.com/santosr2/luma/commit/35056e4daa2193e5ceabc5673f7d7fcd49a871c2)) by [@santosr2](https://github.com/santosr2)
- **cliff**: Remove commit body from changelog, show only titles ([`f70b473`](https://github.com/santosr2/luma/commit/f70b47352b46f6e53a8b087a42b3b9a6221ccfdb)) by [@santosr2](https://github.com/santosr2)


### 📚 Documentation
- **README**: Improve Kubernetes example with indentation best practices ([`12f1212`](https://github.com/santosr2/luma/commit/12f12122aca3783e1e2fef5fbf31acc6a1190b3f)) by [@santosr2](https://github.com/santosr2)
- Add comprehensive Jinja2 feature parity documentation ([`e018f7d`](https://github.com/santosr2/luma/commit/e018f7dbfb08651124ac58dc9df4ece8f837aa27)) by [@santosr2](https://github.com/santosr2)
- Document TRUE 100% Jinja2 feature parity achievement ([`6798543`](https://github.com/santosr2/luma/commit/6798543e6af66823226a57e1601f3dc9575ca738)) by [@santosr2](https://github.com/santosr2)
- Disable Liquid processing for code-heavy pages ([`d195105`](https://github.com/santosr2/luma/commit/d195105c4b27d8ff58c9c37da10040920b866f70)) by [@santosr2](https://github.com/santosr2)
- Completely remove all HTML entity remnants ([`506b6b1`](https://github.com/santosr2/luma/commit/506b6b165901c1d6400bd985f6a9528c5ab96a44)) by [@santosr2](https://github.com/santosr2)
- Wrap code blocks with {% raw %} tags for Jekyll ([`a49ae0a`](https://github.com/santosr2/luma/commit/a49ae0a8d194512c1d03a63db54a8200561d22b6)) by [@santosr2](https://github.com/santosr2)
- Escape Jinja2 syntax in inline code and tables ([`1911dde`](https://github.com/santosr2/luma/commit/1911dde36b00f1d0c64ea26b9533c19388a6bbb5)) by [@santosr2](https://github.com/santosr2)
- Process all markdown files for Jekyll compatibility ([`0278836`](https://github.com/santosr2/luma/commit/027883618edaaf6e489225ec01b12e801fb48ed1)) by [@santosr2](https://github.com/santosr2)
- Fix duplicate raw/endraw tags causing Jekyll errors ([`b9795bd`](https://github.com/santosr2/luma/commit/b9795bd84a162cd7f2c74f4f5ef139a4c5eb9c2f)) by [@santosr2](https://github.com/santosr2)
- Fix baseurl for GitHub Pages deployment ([`f301bb6`](https://github.com/santosr2/luma/commit/f301bb69fa5bb6b1768e4f5df092dedeed6c3edd)) by [@santosr2](https://github.com/santosr2)


### ♻️  Refactor
- Remove Docker Hub, use GitHub Container Registry exclusively ([`22e6408`](https://github.com/santosr2/luma/commit/22e6408edc1c48541184ec4ccf22b506b668a627)) by [@santosr2](https://github.com/santosr2)


### 🧪 Testing
- Properly disable break/continue tests to avoid CI errors ([`2281b4b`](https://github.com/santosr2/luma/commit/2281b4bb7f070f207d723dc532853b9eb0fc04d5)) by [@santosr2](https://github.com/santosr2)
- Fix Lua syntax errors in commented test blocks ([`64296ce`](https://github.com/santosr2/luma/commit/64296cec2c8491722436947924b4c861f153c750)) by [@santosr2](https://github.com/santosr2)


### ⚙️  Miscellaneous Tasks
- Add .gitignore ([`c3567dc`](https://github.com/santosr2/luma/commit/c3567dcadc750ef6401795dc8d98297d180a3e04)) by [@santosr2](https://github.com/santosr2)
- Add comprehensive OSS infrastructure ([`e6463c7`](https://github.com/santosr2/luma/commit/e6463c77f3405e211e1f14f8dc224f8c43a50973)) by [@santosr2](https://github.com/santosr2)
- Remove outdated docs ([`209525a`](https://github.com/santosr2/luma/commit/209525a28e55e30d36868cdae10684d646cd8c2e)) by [@santosr2](https://github.com/santosr2)
- Add Python cache files to gitignore ([`61d1e60`](https://github.com/santosr2/luma/commit/61d1e602a05dee2273f4e9321ce2b0308a79c3c0)) by [@santosr2](https://github.com/santosr2)
- Enhance workflow with Python bindings and benchmarks ([`531edd9`](https://github.com/santosr2/luma/commit/531edd9af638273b12c59003ef76a974a98cf695)) by [@santosr2](https://github.com/santosr2)
- Update release workflow for new directories ([`45d3e90`](https://github.com/santosr2/luma/commit/45d3e90ff87fb65b9a58306ce552a5f2e10f1437)) by [@santosr2](https://github.com/santosr2)
- Untrack internal work files ([`e583c90`](https://github.com/santosr2/luma/commit/e583c9061fad63ad4c738dba72d6eb041cae238c)) by [@santosr2](https://github.com/santosr2)
- Apply lint/format changes from pre-commit ([`90c34c1`](https://github.com/santosr2/luma/commit/90c34c1d89993278ba20ffe37c71ca43cadc7e3b)) by [@santosr2](https://github.com/santosr2)
- Fix pre-commit findings - markdown linting and unused variables ([`752db86`](https://github.com/santosr2/luma/commit/752db862e274173a012af373dab3323c9a1b5545)) by [@santosr2](https://github.com/santosr2)
- Fix remaining luacheck warnings (49→25) ([`7f8e0d8`](https://github.com/santosr2/luma/commit/7f8e0d8c494d337e97978a677df1d2c4aa432734)) by [@santosr2](https://github.com/santosr2)
- Configure pre-commit to pass all checks ([`8646941`](https://github.com/santosr2/luma/commit/8646941f87e5780091629c01d76eb0dbacb4288b)) by [@santosr2](https://github.com/santosr2)
- **release**: V0.1.0 [skip-ci] ([`4bb843b`](https://github.com/santosr2/luma/commit/4bb843b7f630c415c42c1d007777abafd32a335a)) by [@santosr2](https://github.com/santosr2)
- Fix version to v0.1.0 in rockspec ([`e4a005d`](https://github.com/santosr2/luma/commit/e4a005df84dc3879de4a7f4cfe646738f9a4ce8c)) by [@santosr2](https://github.com/santosr2)
- Remove __pycache__ directories from git tracking ([`e27c373`](https://github.com/santosr2/luma/commit/e27c373540c8f23c1a1063b76f91cb25c1ca276a)) by [@santosr2](https://github.com/santosr2)
- Add bump-my-version for automated version management ([`82f2a2f`](https://github.com/santosr2/luma/commit/82f2a2ffc8d02ab8e18e1c822760bfce46ed59a8)) by [@santosr2](https://github.com/santosr2)
- Trigger bindings workflows for validation ([`7bf10c2`](https://github.com/santosr2/luma/commit/7bf10c2dd67a3229f7552d5c5c04b847cd966783)) by [@santosr2](https://github.com/santosr2)
- Change coverage badge and ignore node_modules ([`3962991`](https://github.com/santosr2/luma/commit/39629919410c063cc20ccf493a48b2e17b7681d7)) by [@santosr2](https://github.com/santosr2)
- **nodejs**: Update package-lock.json peer dependency metadata ([`13236d6`](https://github.com/santosr2/luma/commit/13236d63633639e6127e94f83c5c3f0be458ec3c)) by [@santosr2](https://github.com/santosr2)
- Bump version 0.1.0 → 0.1.0-rc.1 ([`98f7c03`](https://github.com/santosr2/luma/commit/98f7c03821a1fdfa9ed9b6510a261279a17fba64)) by [@santosr2](https://github.com/santosr2)
- **release**: Update CHANGELOG.md for v0.1.0-rc.1 ([`d91ffbb`](https://github.com/santosr2/luma/commit/d91ffbb0c1b1d44698fb9b834c9b81a5b79199a0)) by [@github-actions[bot]](https://github.com/github-actions[bot])
- **release**: Update CHANGELOG.md for v0.1.0-rc.1 ([`d4c8fc1`](https://github.com/santosr2/luma/commit/d4c8fc10bf61b45a6a9e4f6946339be6b28ff905)) by [@github-actions[bot]](https://github.com/github-actions[bot])
- **release**: Update CHANGELOG.md for v0.1.0-rc.1 ([`fc0120e`](https://github.com/santosr2/luma/commit/fc0120ec5cf3062a2095de07b402ce586e52029f)) by [@github-actions[bot]](https://github.com/github-actions[bot])


### ◀️  Revert
- Restore original .gitignore ([`a9789f7`](https://github.com/santosr2/luma/commit/a9789f702bcfa88768dc719281e79b4d038c4815)) by [@santosr2](https://github.com/santosr2)


### Wip
- Attempt to fix ipairs/pairs in for loops (not working yet) ([`91a4b1e`](https://github.com/santosr2/luma/commit/91a4b1e891534794a75c1c1d2e38e4371912bcaa)) by [@santosr2](https://github.com/santosr2)


<!-- generated by git-cliff -->
