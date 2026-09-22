# Omarchy CN Indicator

A Fcitx5 Chinese input method indicator for the [Omarchy](https://omarchy.org/) top bar.

Shows your current input mode at a glance and toggles it with a click.

| State | Label | Meaning |
|---|---|---|
| Chinese active | `中` | Fcitx5 is typing Chinese |
| Latin / inactive | `EN` | Fcitx5 is running, typing Latin |
| Not running | `—` | Fcitx5 daemon is not reachable |

Click the label to switch input with `fcitx5-remote -t` — the same as your
usual hotkey. State is polled from `fcitx5-remote` every 700 ms, so external
changes (hotkey, tray, `fcitx5-remote -o`/`-c`) are reflected automatically.

Works with any fcitx5 engine — Rime, Pinyin, Shuangpin, table-based input —
since it only talks to `fcitx5-remote`. It does **not** manage fcitx5 or Rime
configuration.

## Install

```bash
omarchy plugin add https://github.com/jfdnet/omarchy-cn-indicator.git --enable
```

The widget lands in the center bar section by default; move it with
`omarchy bar plugin move io.github.jfdnet.cn-indicator --section <left|center|right>`.

## Requirements

- Omarchy with the Quickshell plugin system (Hyprland 0.56+)
- `fcitx5` and `fcitx5-remote` (any engine; Rime works great)

## Uninstall

```bash
omarchy plugin remove io.github.jfdnet.cn-indicator
```

---

## 中文说明

为 [Omarchy](https://omarchy.org/) 顶栏打造的 Fcitx5 中文输入法状态指示器。

- 实时显示 `中` / `EN` / `—`（输入法未运行）三种状态，每 700ms 自动刷新
- 点击即用 `fcitx5-remote -t` 切换中英文，与快捷键等效
- 兼容任意 fcitx5 引擎（Rime、拼音、双拼、形码……），不修改任何 fcitx5/Rime 配置

```bash
omarchy plugin add https://github.com/jfdnet/omarchy-cn-indicator.git --enable
```

## License

[MIT](LICENSE)
