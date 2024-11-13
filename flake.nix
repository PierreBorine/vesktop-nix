{
  description = "A very basic flake for Vesktop configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = {self, nixpkgs}: {
    homeManagerModules = {
      default = self.homeManagerModules.vesktop-nix;
      vesktop-nix = import ./hm.nix;
    };
  };
}
