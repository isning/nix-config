{ lib, ... }:
{
  options.features.media.enable = lib.mkEnableOption "media tools";
  options.features.media.recording.enable = lib.mkEnableOption "screen recording and streaming";
}
