{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  system.autoUpgrade.enable = true;
  system.autoUpgrade.channel = "https://channels.nixos.org/nixos-24.11";
  system.autoUpgrade.allowReboot = false;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  nix.settings.auto-optimise-store = true;

  virtualisation.docker.enable = true;

  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ]; # Enable ‘sudo’ for the user.
    initialPassword = "admin";
  };

  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = true;

  environment.systemPackages = with pkgs; [
    docker
    git
  ];

  systemd.services.cicd = {
    description = "Fetch the latest cicd and redeploy"; 
    wantedBy = [ "multi-user.target" ];
    script = '' 
      #!/bin/sh
      ${pkgs.coreutils}/bin/rm -rf /tmp/cicd
      ${pkgs.git}/bin/git clone --single-branch https://github.com/applyinnovations/cicd.git /tmp/cicd
      ${pkgs.docker}/bin/docker compose --project-directory /tmp/cicd up --build --remove-orphans
    '';
    serviceConfig = {
      StartLimitBurst = 6;
      StartLimitIntervalSec = 30;
      Restart = "always";
      RestartSec = 5;
      RestartSteps = 10;
      RestartMaxDelaySec = 60;
      TimeoutStartSec = "infinity";
    };
    requires = [ "network-online.target" ];
  };

  networking.firewall.allowedTCPPorts = [ 22 80 443 ];

  system.stateVersion = "24.05";
}
