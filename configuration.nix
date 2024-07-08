{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  nix.settings.auto-optimise-store = true;

  virtualisation.docker.enable = true;

  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ]; # Enable ‘sudo’ for the user.
    initialPassword = "admin";
  };

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
      ${pkgs.git}/bin/git clone --depth 1 --single-branch https://github.com/applyinnovations/cicd.git /tmp/cicd
      ${pkgs.docker}/bin/docker compose --project-directory /tmp/cicd up
    '';
    serviceConfig = {
      Restart = "always";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    requires = [ "network.target" ];
  };

  networking.firewall.allowedTCPPorts = [ 22 80 443 ];

  system.stateVersion = "24.05";
}
