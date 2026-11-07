"""Render the calendar popup's world map as a PNG (stdlib only, run with /usr/bin/python3).

Usage: calendar_worldmap.py OUT.png DIM ACCENT SHADE LINE ZONE...
DIM/ACCENT/SHADE/LINE: colors as aarrggbb hex. ZONE: "lon_west,lon_east[,dot_lon,dot_lat]".
The land mask (calendar_worldmap.mask, Natural Earth 110m land, equirectangular,
lat 84..-58, 480 px wide) has one row per line: run lengths alternating sea/land.
Coastlines are drawn in DIM; each zone gets a faint ACCENT band with its coast
and a dot at its reference city in ACCENT. The night side (for the current
time) is shaded with SHADE and its features faded, with a soft twilight edge;
the day/night line (sun on the horizon) is dashed in LINE.
"""
import math
import os
import struct
import sys
import time
import zlib

LAT_TOP, LAT_BOTTOM = 84.0, -58.0

out, dim, accent, shade, line_color = sys.argv[1:6]
zones = [tuple(map(float, z.split(","))) for z in sys.argv[6:]]


def subsolar(t):
    """(lon, lat) in degrees where the sun is overhead at unix time t (low-precision almanac)."""
    d = (t - 946728000) / 86400  # days since J2000.0
    g = math.radians(357.529 + 0.98560028 * d)
    q = 280.459 + 0.98564736 * d
    lam = math.radians(q + 1.915 * math.sin(g) + 0.020 * math.sin(2 * g))
    eps = math.radians(23.439 - 0.00000036 * d)
    ra = math.degrees(math.atan2(math.cos(eps) * math.sin(lam), math.cos(lam)))
    dec = math.degrees(math.asin(math.sin(eps) * math.sin(lam)))
    gmst = (18.697374558 + 24.06570982441908 * d) % 24 * 15
    return ((ra - gmst + 180) % 360 - 180, dec)


mask = []
with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "calendar_worldmap.mask")) as f:
    for line in f:
        row, v = [], 0
        for n in map(int, line.split()):
            row += [v] * n
            v ^= 1
        mask.append(row)
h, w = len(mask), len(mask[0])


def rgba(hexcolor, alpha=None):
    a, r, g, b = (int(hexcolor[i:i + 2], 16) for i in (0, 2, 4, 6))
    return (r, g, b, a if alpha is None else alpha)


def px(lon, lat):
    return (int((lon + 180) / 360 * w), int((LAT_TOP - lat) / (LAT_TOP - LAT_BOTTOM) * h))


sun_lon, sun_lat = subsolar(time.time())
sin_dec, cos_dec = math.sin(math.radians(sun_lat)), math.cos(math.radians(sun_lat))
shade_rgb = rgba(shade)[:3]


def sun_height(x, y):
    """Cosine of the sun's zenith angle at pixel (x, y): > 0 in daylight."""
    lat = math.radians(LAT_TOP - (y + 0.5) / h * (LAT_TOP - LAT_BOTTOM))
    lon = math.radians(-180 + (x + 0.5) / w * 360 - sun_lon)
    return math.sin(lat) * sin_dec + math.cos(lat) * cos_dec * math.cos(lon)


img = [[(0, 0, 0, 0)] * w for _ in range(h)]
in_band = [any(px(z[0], 0)[0] <= x < px(z[1], 0)[0] for z in zones) for x in range(w)]

for y in range(h):
    for x in range(w):
        land = mask[y][x]
        coast = land and any(
            not (0 <= x + dx < w and 0 <= y + dy < h) or not mask[y + dy][x + dx]
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
        color = accent if in_band[x] else dim
        if coast:
            img[y][x] = rgba(color)
        elif land:
            img[y][x] = rgba(color, 0x48 if in_band[x] else 0x34)
        elif in_band[x]:
            img[y][x] = rgba(accent, 0x18)

cosz = [[sun_height(x, y) for x in range(w)] for y in range(h)]
for y in range(h):
    for x in range(w):
        # linear across twilight (sun -6..+6 deg)
        night = 1 - min(1.0, max(0.0, (cosz[y][x] + 0.105) / 0.21))
        if night == 0:
            continue
        r, g, b, a = img[y][x]
        if a:  # fade the feature
            img[y][x] = (r, g, b, int(a * (1 - 0.6 * night)))
        else:
            img[y][x] = shade_rgb + (int(0x90 * night),)

for y in range(h):
    for x in range(w):
        if (x + y) // 4 % 2 or cosz[y][x] < 0:
            continue
        if any(0 <= x + dx < w and 0 <= y + dy < h and cosz[y + dy][x + dx] < 0
               for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
            img[y][x] = rgba(line_color)

for z in zones:
    if len(z) < 4:
        continue
    cx, cy = px(z[2], z[3])
    for y in range(cy - 8, cy + 9):
        for x in range(cx - 8, cx + 9):
            if 0 <= x < w and 0 <= y < h:
                d2 = (x - cx) ** 2 + (y - cy) ** 2
                if d2 <= 12:
                    img[y][x] = rgba(accent)
                elif 36 <= d2 <= 56:
                    img[y][x] = rgba(accent, 0xa0)

raw = b"".join(b"\x00" + bytes(c for p in row for c in p) for row in img)


def chunk(tag, data):
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data))


png = (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
       + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))
tmp = out + ".tmp"
with open(tmp, "wb") as f:
    f.write(png)
os.replace(tmp, out)
