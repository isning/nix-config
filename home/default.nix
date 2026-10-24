{ mylib, ... }:
{
  imports = (mylib.scanPaths ./features) ++ (mylib.scanPaths ./roles);
}
