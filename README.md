# TheOutsider

## Music

The music is a 4-channel cover of **"She Drives Me Crazy" by Fine Young Cannibals** ([official video](https://www.youtube.com/watch?v=UtvmTu4zAMg)), the 1989 hit from *The Raw and the Cooked*, released the same year as the intro. The module title is "vincent&maurice". The sample names carry a message from the authors: *"ecco la nuova musica del vic & sons group, contattateci per intro e musiche originali!! tel.02.48600137 tel.02.4582806 greetings to: F.P.L, THE OUTSIDER, e quel rinc...di ALPHABIT"*. The arrangement keeps the song's loop in D major (**D – G – Bm – A**, one chord every 16 rows). Bass and chord stabs play on samples 15/12 and 6, the lead melody on samples 14/13, and the drums (kick, snare, hi-hat on every row) never stop. There are 13 patterns played in 23 positions, about 2:56 before the song loops.

### Technical details

- **Format.** The module sits in memory at `$33600` (78278 bytes, ending at `$467c6`, just before the graphics block). It is in the old **Soundtracker format with 15 samples**: 600-byte header, no `M.K.` tag, loop start measured in **bytes** rather than words. 11 of the 15 samples hold data; samples 7–10 are empty and exist only for their names.
- **Replay routine.** The intro does not use the standard ProTracker replay but a small player of its own (`$327c4`–`$32dde` in the original). At startup it reads the header, works out the address of each sample from the pattern count, and installs itself on the **level 3 interrupt**. It writes the vector at `$6c` directly, without `AddIntServer`, and then chains to the old handler, so it runs once per frame (verified on A500, A600 and A1200). It supports only a few effects, NoiseTracker style:

  | Effect | Meaning |
  |---|---|
  | `0xy` | arpeggio |
  | `1xx` / `2xx` | portamento up / down |
  | `Cxx` | volume |
  | `Exx` | audio filter (LED) |
  | `Fxx` | speed |

  In the original, `Fxx` wrote the new speed straight into the immediate operand of a `CMPI.W #6,…` (self-modifying code); the rebuild uses a variable instead.
- **VU meters.** The four bars at the top of the screen are not drawn with bitplanes. Each time a note starts, the player sets a level for that channel equal to the note's volume ÷ 4; the level drops by one step per frame down to a minimum. The level becomes the horizontal position of a copper `WAIT`, and that position sets where the background colour changes on each line of the bar, so the bar gets longer or shorter.

### Why there are two `.mod` files

| File | What it is | When to use it |
|---|---|---|
| [`outsider_st15.mod`](dec/assets/outsider_st15.mod) | The module **byte for byte as it is in memory**: 15 samples, no tag, loop in bytes | Archiving, or comparing against the original |
| [`outsider.mod`](dec/assets/outsider.mod) | The same module converted to **ProTracker `M.K.`**: header widened to 31 samples (16 empty slots), loop start halved and stored in words, `M.K.` tag added | Playing it in ProTracker/OpenMPT/XMP or in demo replay routines, which often reject or misread 15-sample modules |

Patterns and sample data are identical in both files; only the 600-byte header becomes 1084 bytes. The conversion was checked by rendering both files with libopenmpt: the audio is identical. [`outsider.wav`](dec/assets/outsider.wav) is the rendered song (44.1 kHz stereo), and [`dec/assets/samples`](dec/assets/samples) holds the individual samples as WAV and 8SVX.

## Protections

The intro protects its credits in three ways: a **checksum** on the credits text and two **encryptions**, one on the end of the scrolltext and one on part of the graphics. All three live in one 142-byte routine at `$32250`.

The rest of the code is **not encrypted**. In the first IRA disassembly ([dec/unpacked_32250.asm](dec/unpacked_32250.asm)) almost everything shows up as `DC.L` only because IRA started at `$32250`, stopped at the routine's `RTS`, and never found the real entry point at `$322e0`.

### How the routine is reached

The executable `THE_OUTSIDER` is a depacker (tagged " TETRAGON ") followed by the packed data. It unpacks in two stages, an LZ stage (ByteKiller style) and an RLE stage with marker byte `$6d`, into `$32250`–`$60000`. It then ends with `JMP $322e0`. The unpacked program starts like this:

```
322e0  MOVEM.L D0-D7/A0-A6,-(A7)   ; save the registers left by the depacker
322e4  BSR.W   $32250              ; protection routine
322e8  JSR     $3243a              ; ...the intro proper
```

### The protection routine

```
32250  BSET    #1,$bfe001          ; audio filter off (power LED dimmed)

; --- 1. checksum of the credits -------------------------------------------
32258  LEA     $330d8,A0
3225e  ADD.W   (A0)+,D0            ; 16 bit sum of 59 words, $330d8-$3314d
32260  CMPA.L  #$3314e,A0
32266  BNE.W   $3225e
3226a  CMPI.W  #$d7a1,D0
3226e  BEQ.W   $3229a              ; ok -> decrypt

; --- failure: wipe memory and crash ---------------------------------------
32272  LEA     $322d8,A0
32278  CLR.W   (A0)+               ; clear $322d8-$7ffff
3227a  CMPA.L  #$80000,A0
32280  BNE.W   $32278
32284  ADDI.W  #1,$dff180          ; COLOR00
3228c  SUBI.W  #1,$dff182          ; COLOR01
32294  JMP     $3002e

; --- 2. decrypt the end of the scrolltext ---------------------------------
3229a  LEA     $33558,A0
322a0  SUBI.W  #$1532,(A0)+        ; 16 words, $33558-$33577
322a4  CMPA.L  #$33578,A0
322aa  BNE.W   $322a0

; --- 3. copy the graphics block and decrypt part of it ---------------------
322ae  LEA     $467e0,A0
322b4  LEA     $5e000,A1
322ba  MOVE.L  (A0)+,(A1)+         ; $c000 bytes: $467e0-$527df -> $5e000-$69fff
322bc  CMPA.L  #$6a000,A1
322c2  BNE.W   $322ba
322c6  LEA     $635c0,A0
322cc  CLR.L   D0
322ce  SUBI.W  #$7f8f,(A0)+        ; 13600 words, $635c0-$69fff
322d2  CMPA.L  #$6a000,A0
322d8  BNE.W   $322ce
322dc  RTS
```

On a 7 MHz 68000 the routine takes about 0.15 s. Roughly half of that is the `$c000`-byte copy (44 cycles per longword) and half is the graphics decryption (40 cycles per word). This estimate leaves out wait states from chip-bus DMA.

### 1. Credits checksum

- **What it checks.** The 118 bytes (59 words) from `$330d8` to `$3314d` are part of the scrolltext:
  `f2s1 THIS INTRO WAS CREATED BY "#$%&s2          CODING BY DR.MAURICE            GRAPHICS BY VINCENT '89s3       @1989 `
  The codes `f2`, `s1`, `s2`, `s3` are scroller commands (`fN` sets the logo wobble step, `sN` the scroll speed). The characters `"#$%&` are not text: in the font those slots hold the five pieces of the **VIC&SONS** logo. The text that follows (`FOR    THE OUTSIDER`) is not covered by the checksum.
- **Algorithm.** It is a plain 16-bit sum: `ADD.W` of each word, any carry out of the word is lost, and the total is compared with `$d7a1`. The text on its own already adds up to exactly `$d7a1`.
- **The hidden dependency on `D0`.** The loop adds into `D0` without clearing it first, so the check only passes if `D0.W = 0` when the routine starts. That value is left by the depacker. I verified it in FS-UAE: on the stack, in the frame saved by the `MOVEM` at `$322e0`, `D0 = $00000000`, next to `D7 = $6d` (the RLE marker) and `A5 = $dff1a4` (`COLOR18`, which the depacker uses to flicker the screen while unpacking). Whether intended or not, the result is that the unpacked image only works when started by its own depacker. A ripper that dumps memory and jumps to `$322e0` with any other `D0` sets off the protection.
- **Weakness.** Like any additive checksum it catches a single changed character, but not two changes that cancel out. It also misses words that are only swapped: `"GRAPHICS BY"` and `"CODING BY"` could trade places as long as both stay word-aligned.

### What happens when the check fails

1. The routine clears memory word by word from `$322d8` to `$7ffff`. The start address is chosen with care: `$322d8` is the `BNE` of the last decryption loop, right after the wipe loop and the `JMP` that are still needed. The routine therefore erases its own tail and everything after it: the intro code, texts, module, graphics, the still-encrypted source block at `$467e0` and the copy area at `$5e000`. With only 512K of chip RAM the system stack and the OS structures in that range go too.
2. `ADDI.W #1,$dff180` / `SUBI.W #1,$dff182` change colours 0 and 1. The colour registers are write-only, so a read-modify-write first reads an undefined value and the colour that results is unpredictable: one visible "flash".
3. `JMP $3002e` jumps to an address just below the unpacked program. Nothing valid is there: if the loader sits at `$2ff00` (the address used in [THE_OUTSIDER.asm](THE_OUTSIDER.asm)), `$3002e` lands in the middle of the packed data. Either way the CPU runs garbage and the machine crashes.

If the check fails, the two decryptions never run, so the data stays encrypted as well.

### 2. Encrypted scrolltext

The 32 bytes from `$33558` to `$33577` are the last piece of the scrolltext. They come right after `FOR THE OUTSIDER` and its padding spaces, and are stored with `$1532` **added to each 16-bit word**:

| Address | Stored | As text | Decrypted (`-$1532`) | Meaning |
|---|---|---|---|---|
| `$33558` | `$7b63` | `{c` | `$6631` | `f1` – logo wobble step 1 |
| `$3355a` | `$8863` | `\x88c` | `$7331` | `s1` – scroll speed 1 |
| `$3355c` | `$3755` | `7U` | `$2223` | `"#` – VIC&SONS logo, part 1–2 |
| `$3355e` | `$3957` | `9W` | `$2425` | `$%` – logo, part 3–4 |
| `$33560` | `$3b52` | `;R` | `$2620` | `&` + space – logo, part 5 |
| `$33562`–`$33576` | `$3552` ×11 | `5R5R…` | `$2020` | spaces |

The `$00` terminator at `$33578` is **outside** the encrypted area, so the scroller stops and restarts from the beginning even when the text has not been decrypted. Without decryption:

- the `f1`/`s1` commands are not recognised (`{` and `$88` are not `f`/`s`), so speed and wobble keep the values from earlier in the text;
- the scroller treats `{c`, `\x88c`, `7U`, … as characters. The glyph index is `code - $20`, split into row (÷10) and column. `{` and `$88` give rows 9 and 10, but the font only has 6 rows, so the blitter copies glyphs from outside the font (other bitplanes, other data). The result is graphic noise in place of the group logo, followed by a line of `5R5R5R…`.

The obvious purpose is to stop anyone finding the logo/"signature" by searching the file for the text and swapping it.

### 3. Encrypted graphics

The graphics block is stored in the file at `$467e0`–`$527df` and is **copied** to `$5e000`–`$69fff` (`$c000` bytes, 12288 longwords). That address range would otherwise fall in the zero area at the end of the unpacked image. Only after the copy is the **destination** area `$635c0`–`$69fff` decrypted (27200 bytes = 13600 words, `SUBI.W #$7f8f,(A0)+`). In the file that area is `$4bda0`–`$527df`.

The boundary at `$635c0` is not arbitrary. The copper list (`$5eff8`), the "OUTSIDER" logo (`$60000`) and the "ITALY" bar (`$63340`) are stored in clear. Everything from the credits line onwards is encrypted:

| Area | Address | Bytes | Contents |
|---|---|---|---|
| credits | `$635c0` | 320 | 1-plane line *"THIS INTRO WAS DONE BY VIC&SONS GROUP"* |
| sine | `$63700` | 182 | sine table (values 0–96) |
| (gap) | `$637b6` | 2122 | almost all zero |
| font | `$64000` | 24480 | scroller font, 3 planes × `$1fe0` |
| (tail) | `$69fa0` | 96 | zero |

So the credits line at the bottom of the screen is protected in the same way. The font and the sine table end up in the encrypted area as well, so you cannot just "skip" the decryption: the whole intro would stop working, not only the credits.

Without decryption:

- the scroller would draw noise, because every font word is shifted by `$7f8f`;
- the bottom line would be noise;
- the sine table would hold values up to 239 instead of 96. The logo wobble (`value×15/97`, then ×`$11` into `BPLCON1`) and the "ITALY" bar position (`value×56/97 + $b4`) would go out of range: wrong shifts and the bar drawn on the wrong lines.

The copy also makes sure the original block at `$467e0` stays encrypted in memory. The decryption is **not idempotent**: if the text routine ran twice on the same image, `$33558` would be decrypted twice and become garbage. The graphics part survives a second run only because it is decrypted again from a fresh copy of the source.

### Analysis of the cipher

Both encryptions use the same scheme: **addition of a 16-bit constant modulo 2^16 on each word** (a Caesar cipher on words), undone by subtracting the same constant. It is not a byte-by-byte encryption, because of the carry from the low byte into the high byte:

```
font, plaintext      $24d2   ->  $24d2 + $7f8f = $a461   (low byte: $d2+$8f = $161, carry into the high byte)
                     $e800   ->  $e800 + $7f8f = $678f   (high byte: $e8+$7f = $167, wraps out of the word)
text,  "  " $2020    ->  $2020 + $1532 = $3552   ("5R")
```

In the graphics area, 3121 of the 13600 words (23%) carry from the low byte. Anyone trying to decrypt byte by byte with a `-$8f`/`-$7f` pair would get those words wrong.

The scheme is very weak against anyone who looks at a hex dump:

- **The key shows up in clear.** An encrypted zero word becomes the key itself. In the graphics area 5169 words out of 13600 (38%) are `$7f8f`. Long runs of `7F 8F 7F 8F …` sit exactly where you would expect zeros: the bitplane margins, the gap, the first values of the sine table (`$7f8f $7f8f $7f8f $8090 $8091 $8192` → `$0000 $0000 $0000 $0101 $0102 $0203`). In the text the same goes for spaces: eleven `$3552` in a row stand out, and `$3552 - $2020 = $1532` gives the key immediately.
- No dependency on position, no chaining, no key schedule: one known-plaintext word is enough to decrypt everything.

As obfuscation it does its job: a simple text search for "VIC" or a look at the graphics with a ripper finds nothing. It is not a real cipher.

### In the relocatable version

[dec/outsider.asm](dec/outsider.asm) removes the whole routine. The text at `$33558` and the font, sine and credits block are stored **already decrypted**, so there is no checksum, no wipe and no `JMP $3002e`. The graphics block is no longer copied: it sits directly in its own `DATA_C` section. The `BSET #1,$bfe001` (audio filter off) is kept, because it is the only part of the routine that has nothing to do with protection.

Two pieces of self-modifying code have also been removed, though they were not protections: the player speed (written by the `Fxx` effect into the immediate of `CMPI.W #6,…`) and the `JMP` to the old level 3 interrupt vector, whose operand was patched at runtime. Both are safe on a 68000 but not on CPUs with an instruction cache.

The extracted assets (module, images, font, scrolltext) are in [dec/assets](dec/assets).
