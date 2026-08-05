{ target }:
{
  home.file."${target}/skills/hallmark" = {
    source = ./hallmark;
    recursive = true;
  };
}
