{ config, pkgs, ... }:

let
  cicd = pkgs.buildGoModule rec {
    pname = "cicd";
    version = "0.0.1";

    src = pkgs.fetchFromGitHub {
      owner = "applyinnovations";
      repo = "cicd";
      rev = "bcabb61d19c85375684fbf7cae8ce4827604a916";
      sha256 = "sha256-7rARHP+DTdouw/RTN8S798VvyI2ytcjTUMKH4FCcnr4=";
    };

    vendorHash = null;
  };

  adminPassword = builtins.getEnv "ADMIN_PASSWORD";

  password = if adminPassword == "" then
    throw "Environment variable ADMIN_PASSWORD is required and cannot be empty."
  else
    adminPassword;
in
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    initialPassword = password;
  };

  environment.systemPackages = with pkgs; [
    pkgs.neovim
    docker
    git
    cicd
  ];

  systemd.services.cicd = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${cicd}/bin/cicd";
      Restart = "always";
    };
    requires = [ "network.target" ];
  };

  networking.firewall.allowedTCPPorts = [ 22 80 443 ];

  system.stateVersion = "23.11";
}
