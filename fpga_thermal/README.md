# Tang Nano 9K Thermal FPGA Preprocessing Project

本工程面向毕业设计《搭载端侧 NPU 的低延时热成像观测系统设计与实现》的 FPGA 端。FPGA 只做确定性图像预处理与数据打包，不做 AI/NPU 推理，不做 YOLO/ESRGAN，不直接驱动 AMOLED。

## 数据流

```text
Tiny1-C raw stream
  -> spi_rx_tiny1c / frame_source_sim
  -> meta_extract + candidate_mask_gen + thumb_gen
  -> norm16_to_u8
  -> roi_crop
  -> scaler_nearest(P0) / scaler_bilinear(P1 Q8.8)
  -> sobel3x3
  -> edge_blend
  -> packet_tx_spi
  -> ESP32-S3
```

## 目录

```text
rtl/          Verilog-2001 RTL
sim/          testbench 与 test_frame.mem
scripts/      测试帧生成、仿真输出转 PNG
constraints/  Tang Nano 9K 约束模板
gowin/        Gowin 工程入口模板
.codex/skills/fpga-thermal-pipeline/  项目维护 skill
```

## 模块说明

| 模块 | 功能 |
| --- | --- |
| `spi_rx_tiny1c.v` | 通用 SPI 类 16 bit raw pixel 接收，输出帧同步、行列计数、错误标志 |
| `frame_source_sim.v` | 仿真帧源，从 `sim/test_frame.mem` 输出 256x192 raw 流 |
| `norm16_to_u8.v` | P0 高 8 位灰度；保留 min/max 归一化接口 |
| `roi_crop.v` | ROI 裁剪，支持 full/observe 两种顶层配置 |
| `scaler_nearest.v` | P0 帧缓存最近邻缩放，优先保证仿真可检查 |
| `scaler_bilinear.v` | P1 Q8.8 固定点双线性缩放，无浮点 |
| `line_buffer_3row.v` / `window_3x3.v` | Sobel 3x3 流式窗口基础模块 |
| `sobel3x3.v` | 移位加法 Sobel，输出 `edge_strength[7:0]` 与 `edge_mask` |
| `edge_blend.v` | `clip(I + ((edge_strength * edge_gain) >> 4))` |
| `thumb_gen.v` | 64x48 P0 像素跳读缩略图 |
| `candidate_mask_gen.v` | raw 阈值候选掩码与候选计数 |
| `meta_extract.v` | raw min/max/center/hotspot/候选质心统计 |
| `packet_tx_spi.v` | SPI 主机发送 header + payload + CRC16-CCITT |
| `cfg_regs.v` | 预留配置寄存器 |
| `top_tiny1c_fpga.v` | 完整 P0/P1 顶层集成，适合仿真和模块级验证 |
| `top_tangnano9k.v` | Tang Nano 9K 板级 wrapper，IO 数量适合 QN88 封装 |

## 显示模式

| 模式 | 输入区域 | 输出尺寸 |
| --- | --- | --- |
| full view | 256x192 全图 | 168x126 |
| observe view | 默认中心 256x112 ROI，可寄存器配置 | 294x126 |

## 配置寄存器

| 地址 | 名称 | 说明 |
| --- | --- | --- |
| `0x00` | `display_mode` | 0 full，1 observe |
| `0x04` | `edge_enable` | 边缘增强使能 |
| `0x08` | `edge_gain` | 边缘增益，融合时右移 4 |
| `0x0C` | `edge_threshold` | Sobel mask 阈值 |
| `0x10` | `raw_low_threshold` | 候选热区 raw 下阈值 |
| `0x14` | `raw_high_threshold` | 候选热区 raw 上阈值 |
| `0x18` | `roi_x0` | observe ROI 起点 x |
| `0x1C` | `roi_y0` | observe ROI 起点 y |
| `0x20` | `roi_w` | observe ROI 宽 |
| `0x24` | `roi_h` | observe ROI 高 |

## 数据包格式

SPI 发送顺序为大端，40 字节头之后依次是 `display_gray`、`thumb_gray`、`candidate_mask`，最后 2 字节 CRC16-CCITT。

| 字节偏移 | 字段 | 长度 |
| --- | --- | --- |
| 0 | magic `0x55AA` | 2 |
| 2 | frame_id | 2 |
| 4 | display_width | 2 |
| 6 | display_height | 2 |
| 8 | thumb_width | 2 |
| 10 | thumb_height | 2 |
| 12 | flags | 2 |
| 14 | raw_min | 2 |
| 16 | raw_max | 2 |
| 18 | raw_center | 2 |
| 20 | raw_hotspot | 2 |
| 22 | hotspot_x | 2 |
| 24 | hotspot_y | 2 |
| 26 | candidate_count | 4 |
| 30 | candidate_cx | 2 |
| 32 | candidate_cy | 2 |
| 34 | payload_len | 4 |
| 38 | header_checksum | 2 |

P0 中 `header_checksum` 默认置 0，真正校验值位于包尾 CRC16。ESP32-S3 端以 magic 同步，按 `payload_len` 读取 payload，再验证尾部 CRC。

## 仿真

```powershell
cd F:\FPGA\fpga_thermal
python scripts\gen_test_frame.py
powershell -ExecutionPolicy Bypass -File sim\run_iverilog.ps1
```

本机当前未检测到 `iverilog/vvp` 时，可在 Gowin/ModelSim 中导入 `rtl/*.v` 和对应 `sim/tb_*.v` 运行。

## 仿真图像导出

```powershell
python scripts\dump_to_image.py --display sim\display_gray.bin --display-size 294x126 --thumb sim\thumb_gray.bin --thumb-size 64x48 --edge sim\edge.bin --edge-size 294x126
```

脚本不依赖 Pillow，使用 Python 标准库直接写灰度 PNG。

## Gowin FPGA Designer

1. 打开 Gowin FPGA Designer。
2. 以 `gowin/fpga_thermal.gprj` 为模板，或新建工程后加入 `rtl/*.v`。
3. 板级综合/布局布线顶层选择 `top_tangnano9k`；模块仿真顶层仍使用 `top_tiny1c_fpga`。
4. 器件选择 Tang Nano 9K 常用的 `GW1NR-LV9QN88PC6/I5`。
5. 根据实际接线修改 `constraints/tangnano9k.cst`。
6. `top_tangnano9k` 默认使用 `PACKET_BUFFER_DISPLAY=0` 的资源适配模式，综合发送 metadata、thumb 和 mask，display payload 置 0；完整显示缓存/缩放/Sobel 链可在 `top_tiny1c_fpga` 中设置 `PACKET_BUFFER_DISPLAY=1` 做模块验证，但不建议直接作为 9K 板级综合目标。

## Gowin TCL

根据 `SUG100-2.6` 第 8 章，`gw_sh.exe script_file` 可执行 TCL 脚本，常用命令包括 `set_device`、`add_file`、`set_option`、`run syn` 和 `run all`。

```powershell
powershell -ExecutionPolicy Bypass -File scripts\run_gowin_syn.ps1
powershell -ExecutionPolicy Bypass -File scripts\run_gowin_all.ps1
```

已在 Gowin V1.9.11.03 Education 上验证 `top_tangnano9k`：

| 项目 | 结果 |
| --- | --- |
| `run syn` | 通过 |
| `run all` | 通过，生成 bitstream |
| Logic | 1549 / 8640，18% |
| Register | 722 / 6693，11% |
| BSRAM | 2 / 26，8% |
| I/O Port | 12 / 71，17% |
| Fmax | 52.716 MHz，高于 27 MHz 约束 |

原先的 `display_mem` DFF 超限来自多写口/非 BSRAM 友好写法；完整 observe 显示帧缓存加 scaler 帧缓存也会超过 9K 片上 RAM，因此板级默认采用资源适配模式。后续若要输出真实 `display_gray`，建议改成行 FIFO/ESP32 侧缩放缓存，或外接 SRAM/PSRAM，而不是在 GW1NR-9 内部缓存整帧显示图。

## 工程备注

当前 P0/P1 模块优先保证接口完整、可仿真和 Gowin 友好。`scaler_nearest` 与 `scaler_bilinear` 使用帧缓存，适合毕业设计原型验证；若后续进一步压低 FPGA 增量延时，可在同一接口下替换为行缓存/相位累加式缩放器。Sobel 已提供 `line_buffer_3row` 和 `window_3x3`，便于未来保留流式窗口实现。
