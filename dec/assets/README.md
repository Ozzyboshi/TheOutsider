# The Outsider intro – assets

Extracted from the unpacked and decrypted memory image (`$32250`–`$60000`). The graphics block was stored at `$467e0` and copied to `$5e000` at startup; the encrypted part (`$635c0`–`$6a000`) was decrypted with `SUBI.W #$7f8f`. The addresses below are the runtime ones.

## Music

| File | Contents |
|---|---|
| `outsider_st15.mod` | Original module, byte for byte as in memory (`$33600`, 78278 bytes): Soundtracker, 15 samples, no `M.K.` tag, loop start in bytes. Title "vincent&maurice", 13 patterns, 23 positions. |
| `outsider.mod` | Same module converted to ProTracker `M.K.` (31 samples, loop start in words), for players and trackers that don't support the 15-sample format. Renders identically to the original in libopenmpt. |
| `samples/NN_name.wav` | The 11 non-empty samples, 8 bit mono, 8287 Hz (PAL C-2). |
| `samples/NN_name.8svx` | Same samples as IFF 8SVX, with loop and volume. |

The sample names hold the musicians' message: *"ecco la nuova musica del vic & sons group, contattateci per intro e musiche originali!! tel.02.48600137 tel.02.4582806 greetings to: F.P.L, THE OUTSIDER, e quel rinc...di ALPHABIT"*.

## Graphics

Every image comes in four forms:

- `*.raw` – planar bitplanes as in Amiga memory, one plane after the other (not interleaved), 40 bytes per row.
- `*.pal` – palette as big-endian OCS words (`$0RGB`), 2^planes entries.
- `*.png` – the image with one fixed palette.
- `*_copper.png` – the image as it looks on screen. The copper list changes colours on every line, and these files apply that per-line palette (taken by simulating the copper list).

| Name | Address | Size | Planes | Notes |
|---|---|---|---|---|
| `logo` | `$60000` | 320×82 | 4 (plane stride `$cd0`) | "OUTSIDER" logo; on screen it wobbles horizontally via `BPLCON1` |
| `italy_bar` | `$63340` | 320×16 | 1 | "ITALY" bar bouncing on a sine; the copper paints the blue gradient and the green/white/red text colours |
| `credits` | `$635c0` | 320×8 | 1 | "THIS INTRO WAS DONE BY VIC&SONS GROUP" at the bottom of the screen |
| `font` | `$64000` | 320×204 | 3 (plane stride `$1fe0`) | Scroller font: 10×6 characters of 32×34 pixels (row stride `$550`). Chars from `' '` in ASCII order, plus the VIC&SONS logo glyphs on `" # $ % &` |

## Other data

| File | Contents |
|---|---|
| `scrolltext.txt` | Scroller text (`$32efe`). Control codes: `sN` sets the scroll speed (N = 0-9), `fN` sets the logo wobble step. The text ends with a 0 byte. |
| `sine.bin` | 182-byte sine table (`$63700`). It drives the logo wobble (values scaled to 0-15 → `BPLCON1`) and the bounce of the "ITALY" bar. |
| `copperlist.bin` | The original copper list (`$5eff8`–`$5f8c8`). Its bitplane pointers refer to the original absolute addresses (`$6xxxx`). |
