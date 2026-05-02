from pathlib import Path
WIDTH = 256
HEIGHT = 192
OUT = Path(__file__).resolve().parents[1] / "sim" / "test_frame.mem"
def main():
    vals = []
    cx, cy, r = 150, 92, 24
    hx, hy, hr = 92, 118, 12
    for y in range(HEIGHT):
        for x in range(WIDTH):
            base = 0x2800 + int(x * 0x1200 / (WIDTH - 1)) + int(y * 0x0800 / (HEIGHT - 1))
            d2 = (x - cx) ** 2 + (y - cy) ** 2
            if d2 <= r * r:
                base += int((1.0 - d2 / (r * r)) * 0x3800)
            d2h = (x - hx) ** 2 + (y - hy) ** 2
            if d2h <= hr * hr:
                base += int((1.0 - d2h / (hr * hr)) * 0x5000)
            vals.append(max(0, min(0xFFFF, base)))
    OUT.write_text("\n".join(f"{v:04X}" for v in vals) + "\n", encoding="ascii")
    print(f"wrote {OUT} ({len(vals)} pixels)")
if __name__ == "__main__":
    main()
