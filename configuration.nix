{ config, pkgs, ... }:

let
  adminPassword = builtins.getEnv "ADMIN_PASSWORD";
  password = if adminPassword == "" then
    throw "Environment variable ADMIN_PASSWORD is required and cannot be empty."
  else
    adminPassword;

  initCicd = pkgs.writeText "init_cicd.sh" ''
    #!/bin/sh
    rm -rf /tmp/cicd
    git clone --depth 1 --single-branch https://github.com/applyinnovations/cicd.git /tmp/cicd
    cd /tmp/cicd
    docker compose up
  '';
in
{

  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  virtualisation.docker.enable = true;

  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ]; # Enable ‘sudo’ for the user.
    initialPassword = password;
  };

  environment.systemPackages = with pkgs; [
    docker
    git
  ];

  systemd.services.initCicd = {
    description = "Fetch the latest cicd and redeploy"; 
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${initCicd}";
      Restart = "always";
    };
    requires = [ "network.target" ];
  };

  networking.firewall.allowedTCPPorts = [ 22 80 443 ];

  system.stateVersion = "24.05";
}
