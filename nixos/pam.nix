{
  # For skate3 rpcs3, and probably some other games.
  # https://x.com/rpcs3/status/1330818231527944194
  security.pam.loginLimits = [
    {
      domain = "*";
      type = "hard";
      item = "memlock";
      value = "unlimited";
    }
    {
      domain = "*";
      type = "soft";
      item = "memlock";
      value = "unlimited";
    }
  ];
}
