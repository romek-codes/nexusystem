{ pkgs, ... }: {
  home.packages = with pkgs; [ 
    php
    php84Packages.composer
    laravel
  ];
}
