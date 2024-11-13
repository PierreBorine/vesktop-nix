{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) types hm;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption mkPackageOption literalExpression;
  inherit (lib.attrsets) concatMapAttrs;
  inherit (builtins) toJSON;

  jsonFormat = pkgs.formats.json {};
  cfg = config.programs.vesktop;

  # Merges recursively the JSONized attribute set into the target file
  mkJsonEditActivationScript = {
    target,
    attrset,
  }:
    hm.dag.entryAfter ["writeBoundary"] ''
      baseDir=$(dirname ${target})
      run ${pkgs.jq}/bin/jq -s '.[0] * .[1]' \
          ${target} <(echo '${toJSON attrset}') \
          > $baseDir/tmp.$$.json && mv $baseDir/tmp.$$.json ${target}
    '';
in {
  options.programs.vesktop = {
    enable = mkEnableOption "Wether to install and configure Vesktop using home-manager";

    package = mkPackageOption pkgs "vesktop" {};

    themes = mkOption {
      type = types.attrsOf types.path;
      default = {};
      example = literalExpression ''
        {
          base16 = ./onedark.css;
        }
      '';
      description = ''
        Files to symlink to ~/.config/vesktop/themes, the attribute's name is used for the file's
      '';
    };

    vencordSettings = mkOption {
      type = types.attrsOf jsonFormat.type;
      default = {};
      example = literalExpression ''
        {
          themeLinks = ["https://refact0r.github.io/system24/theme/flavors/spotify-text.theme.css"];
          frameless = true;
        }
      '';
      description = ''
        Json keys to change in ~/.config/vesktop/settings.json.
        This option uses on home.activation.
      '';
    };

    settings = mkOption {
      type = types.attrsOf jsonFormat.type;
      default = {};
      example = literalExpression ''
        {
          themeLinks = ["https://refact0r.github.io/system24/theme/flavors/spotify-text.theme.css"];
          frameless = true;
        }
      '';
      description = ''
        Json keys to change in ~/.config/vesktop/settings/settings.json.
        This option uses on home.activation.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [cfg.package];

    xdg.configFile =
      concatMapAttrs (
        name: value: {
          "vesktop/themes/${name}.css".source =
            if lib.pathIsDirectory value
            then builtins.abort "programs.vesktop.themes: path ${value} is not a file"
            else value;
        }
      )
      cfg.themes;

    home.activation = {
      editVesktopSettings = mkIf (cfg.settings != {}) (mkJsonEditActivationScript {
        target = "${config.home.homeDirectory}/.config/vesktop/settings.json";
        attrset = cfg.settings;
      });

      editVencordSettings = mkIf (cfg.vencordSettings != {}) (mkJsonEditActivationScript {
        target = "${config.home.homeDirectory}/.config/vesktop/settings/settings.json";
        attrset = cfg.vencordSettings;
      });
    };
  };
}
