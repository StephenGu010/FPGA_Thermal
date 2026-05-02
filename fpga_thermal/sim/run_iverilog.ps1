$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Rtl = Join-Path $Root "rtl"
$Sim = Join-Path $Root "sim"
$Out = Join-Path $Sim "out"
New-Item -ItemType Directory -Force $Out | Out-Null
$tests = @("tb_norm16_to_u8","tb_sobel3x3","tb_scaler_nearest","tb_scaler_bilinear","tb_packet_tx","tb_top_tiny1c_fpga")
foreach ($tb in $tests) {
  Write-Host "== $tb =="
  iverilog -g2001 -I $Rtl -o (Join-Path $Out "$tb.vvp") (Join-Path $Rtl "*.v") (Join-Path $Sim "$tb.v")
  vvp (Join-Path $Out "$tb.vvp")
}
