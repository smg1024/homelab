{ ... }:

{
  # Enable these imports after collecting disk IDs and generated hardware config
  # during the NixOS installer phase.
  # imports = [
  #   ./hardware-configuration.nix
  #   ./disko.nix
  # ];

  networking.hostName = "yggdrasil";

  system.stateVersion = "25.11";
}
