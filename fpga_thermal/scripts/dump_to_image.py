#!/usr/bin/env python3
"""Convert simulation gray binary dumps to PNG without Pillow."""
from pathlib import Path
import argparse, struct, zlib
def parse_size(s):
    w,h=s.lower().split("x",1); return int(w),int(h)
def write_png_gray(path,w,h,pixels):
    if len(pixels)<w*h: raise ValueError(f"{path}: need {w*h} bytes, got {len(pixels)}")
    pixels=pixels[:w*h]
    raw=b"".join(b"\x00"+pixels[y*w:(y+1)*w] for y in range(h))
    def chunk(tag,data):
        return struct.pack(">I",len(data))+tag+data+struct.pack(">I",zlib.crc32(tag+data)&0xffffffff)
    png=b"\x89PNG\r\n\x1a\n"+chunk(b"IHDR",struct.pack(">IIBBBBB",w,h,8,0,0,0,0))+chunk(b"IDAT",zlib.compress(raw,9))+chunk(b"IEND",b"")
    path.write_bytes(png)
def convert(src,size,out_dir):
    if not src: return
    w,h=parse_size(size); p=Path(src); out=out_dir/(p.stem+".png"); write_png_gray(out,w,h,p.read_bytes()); print(f"wrote {out}")
def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--display"); ap.add_argument("--display-size",default="294x126")
    ap.add_argument("--thumb"); ap.add_argument("--thumb-size",default="64x48")
    ap.add_argument("--edge"); ap.add_argument("--edge-size",default="294x126")
    ap.add_argument("--out-dir",default="sim/png")
    a=ap.parse_args(); out=Path(a.out_dir); out.mkdir(parents=True,exist_ok=True)
    convert(a.display,a.display_size,out); convert(a.thumb,a.thumb_size,out); convert(a.edge,a.edge_size,out)
if __name__=="__main__":
    main()
