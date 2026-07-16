# ffmpeg-yp3-patch

Patched FFMPEG for Shenju / YP3 H.264 MP3 players.

# Why

H.264 YP3-chip decoders require legacy FFMPEG parameters that cannot be set via command line options. Instead, a minimal patch is necessary.

Without this patch, modern FFMPEG-encoded videos will not play, or will be severely corrupted. This is primarily due to mismatching SPS/PPS and VUI data.

# Credit

- Cursor: File analysis, bisect assistance, stress testing.
- [fdd4s](https://github.com/fdd4s/portable_music_player_avi_video_converter_tool_2025): Shenju vendor-patched `ffmpeg.exe` as reference, and initial working encoding parameters.

# Patch

- `i_nal_ref_idc = NAL_PRIORITY_DISPOSABLE`: P-slices must be disposable, not references.
- `sps->i_poc_type = 0`: Required with disposable-P (explicit POC in every slice header).
- `sps->b_vui = 0`: `extradata` must not include the VUI.
- `pps->i_chroma_qp_index_offset = 0`: Required for proper color tint.
- Disable `P_SKIP`.
- Lower `i_mv_range` floor (32 → 4 px): so `-x264-params mvrange=16` is actually applied.
- `h->i_idr_pic_id = 0`: Do not toggle IDR pic id 0/1; required for scenecut (`sc_threshold > 0`).

# Encoding Requirements

- `-x264-params "mvrange=16:merange=16"`: Clamp motion vectors (~16 px/component; do not go lower or much higher).
- `-bsf:v "filter_units=remove_types=6"`: Device expects no SEI.
- `-profile:v baseline`: Disable unsupported features.
- `-c:a pcm_s16le`: Device expects uncompressed signed PCM 16-bit little-endian.
- `-ar:a >= 8 kHz`: Device requires at least 8 Khz audio rate.
- `-qmin:v 20`: Restrict maximum I-frame complexity.
- `-sc_threshold:v 0`: Disable scene-cut IDRs that destabilize P-chains.

# Encoding Recommendations

- `-pix_fmt:v yuvj420p`: Device prefers full-range pixel format.
- `-filter:v "transpose=cclock"`: Proper orientation.

# Docker

1. Build container: `docker build -t media-player-ffmpeg .`
2. Create a local folder (e.g. `data`) and put your input video into this folder
3. You can then use a bind mount to `/data` (working directory in the container) to share the files between the container and the host
4. The container can be used like this: `docker run --rm -it -v ./data:/data media-player-ffmpeg ffmpeg -i video.mp4 video.avi` (see above for required and recommended ffmpeg flags)
