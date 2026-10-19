{
  name,
  pkgs,
  ...
}:
pkgs.writers.writePython3Bin name { } (
  builtins.replaceStrings [ "@CRANE@" ] [ "${pkgs.crane}/bin/crane" ] (
    builtins.readFile ./dev-update.py
  )
)
