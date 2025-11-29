
{
  description = "Lode bitmap font";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor = system: nixpkgs.legacyPackages.${system};
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.stdenv.mkDerivation {
            pname = "lode-font";
            version = "2.0";

            src = ./.;

            dontBuild = true;

            installPhase = ''
              runHook preInstall

              # Install X11 bitmap fonts
              install -Dm644 x11-bitmap/*.pcf.gz -t $out/share/fonts/misc/
              install -Dm644 x11-bitmap/*.bdf -t $out/share/fonts/misc/

              # Install OTB fonts
              install -Dm644 otb/*.otb -t $out/share/fonts/misc/

              # Install console fonts
              mkdir -p $out/share/consolefonts
              install -Dm644 consolefonts/*.psf.gz consolefonts/*.psfu.gz -t $out/share/consolefonts/ 2>/dev/null || true

              # Install documentation
              install -Dm644 README.md -t $out/share/doc/lode-font/
              install -Dm644 LICENSE -t $out/share/licenses/lode-font/

              runHook postInstall
            '';

            meta = with pkgs.lib; {
              description = "Lode bitmap font for console and X11";
              license = licenses.free; # Adjust based on actual LICENSE file
              platforms = platforms.all;
            };
          };
        });

      # NixOS module for easy system-wide installation
      nixosModules.default = { config, lib, pkgs, ... }: {
        options.fonts.fonts = lib.mkOption {
          type = lib.types.listOf lib.types.package;
        };

        config = lib.mkIf (builtins.elem self.packages.${pkgs.system}.default config.fonts.fonts) {
          fonts.packages = [ self.packages.${pkgs.system}.default ];
        };
      };
    };
}
