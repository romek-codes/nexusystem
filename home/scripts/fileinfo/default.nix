{ pkgs, config, lib, ... }:

let
  fileinfo = pkgs.writeShellScriptBin "fileinfo" ''
    #!/usr/bin/env bash
    # Human-readable universal file info
    file="$1"

    if [ ! -f "$file" ]; then
      echo "File not found: $file"
      exit 1
    fi

    # Human-readable size
    size=$(ls -lh "$file" | awk '{print $5}')

    # Basic type
    type=$(command -v file >/dev/null 2>&1 && file --brief "$file" || echo "unknown type")

    echo "File: $file"
    echo "Size: $size"
    echo "Type: $type"

    # Video info using mediainfo
    if command -v mediainfo >/dev/null 2>&1 && mediainfo "$file" >/dev/null 2>&1; then
      if mediainfo "$file" | grep -q "Video"; then
        echo "Video info: $(mediainfo --Inform='General;%Duration/String3% - %Video_Format% %Width%x%Height%' "$file")"
      fi
    fi

    # Full metadata using exiftool (works for images, videos, PDFs, etc.)
    if command -v exiftool >/dev/null 2>&1 && exiftool "$file" >/dev/null 2>&1; then
      echo "Full metadata:"
      exiftool "$file" | sed 's/^/  /'
    fi

    # Extended attributes (xattr) on Linux
    if command -v getfattr >/dev/null 2>&1; then
      echo "Extended attributes (xattr):"
      getfattr -d "$file" 2>/dev/null | sed 's/^/  /'
    fi
  '';
in {
  home.packages = [
    pkgs.file # classic 'file' binary
    pkgs.mediainfo # video metadata
    pkgs.exiftool # image/media metadata
    fileinfo # human-readable wrapper aliased as 'fileinfo'
  ];
}
