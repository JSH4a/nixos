{
  config,
  pkgs,
  lib,
  ...
}: {
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "joshua";
  home.homeDirectory = "/home/joshua";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    wofi
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    (pkgs.writeShellScriptBin "rebuild" ''
           set -e

           # Navigate to the NixOS directory
           pushd ~/nixos/

           # Function to open specific files in nvim
           edit_file() {
             case "$1" in
               f)
                 nvim flake.nix
                 ;;
               c)
                 nvim hosts/default/configuration.nix
                 ;;
               h)
                 nvim hosts/default/home.nix
                 ;;
               w)
                 nvim hosts/default/hyprland.conf
                 ;;
        *)
                 echo "Invalid option. Use 'f' for flake.nix, 'c' for configuration.nix, or 'h' for home.nix."
                 exit 1
                 ;;
             esac
           }

           # Check if an argument is provided
           if [ $# -gt 0 ]; then
             edit_file "$1"

      # Check for changes after editing
             if [ -z "$(git status --porcelain)" ]; then
               echo "No changes detected. Exiting..."
               popd
               exit 0
             else
               echo "Changes detected. Continuing with rebuild..."
             fi
           fi

           # Continue with the rest of the script
           alejandra . &>/dev/null
           git diff -U0 -- '*.nix' '*.conf'
           echo "NixOS Rebuilding..."
           sudo nixos-rebuild switch --flake ~/nixos/hosts/#default &>nixos-switch.log || (
             cat nixos-switch.log | grep --color error && false)
           gen=$(nixos-rebuild list-generations | grep current)
           git commit -am "$gen"

           # Return to the previous directory
           popd
    '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/joshua/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
    LD_LIBRARY_PATH = lib.makeLibraryPath (with pkgs; [
      icu
    ]);
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  wayland.windowManager.hyprland = {
    # Whether to enable Hyprland wayland compositor
    enable = true;
    extraConfig = builtins.readFile ./hyprland.conf;
    settings = {
    };
  };

  programs.wofi = {
    enable = true;
    style = ''
          /*
      * wofi style. Colors are from authors below.
      * Base16 Gruvbox dark, medium
      * Author: Dawid Kurek (dawikur@gmail.com), morhetz (https://github.com/morhetz/gruvbox)
      *
      */
      @define-color base00 #282828;
      @define-color base01 #3C3836;
      @define-color base02 #504945;
      @define-color base03 #665C54;
      @define-color base04 #BDAE93;
      @define-color base06 #D5C4A1;
      @define-color base06 #EBDBB2;
      @define-color base07 #FBF1C7;
      @define-color base08 #FB4934;
      @define-color base09 #FE8019;
      @define-color base0A #FABD2F;
      @define-color base0B #B8BB26;
      @define-color base0C #8EC07C;
      @define-color base0D #83A598;
      @define-color base0E #D3869B;
      @define-color base0F #D65D0E;

      window {
          opacity: 0.9;
          border:  0px;
          border-radius: 10px;
          font-family: monospace;
          font-size: 18px;
      }

      #input {
      	border-radius: 10px 10px 0px 0px;
          border:  0px;
          padding: 10px;
          margin: 0px;
          font-size: 28px;
      	color: #8EC07C;
      	background-color: #554444;
      }

      #inner-box {
      	margin: 0px;
      	color: @base06;
      	background-color: @base00;
      }

      #outer-box {
      	margin: 0px;
      	background-color: @base00;
          border-radius: 10px;
      }

      #selected {
      	background-color: #608787;
      }

      #entry {
      	padding: 0px;
          margin: 0px;
      	background-color: @base00;
      }

      #scroll {
      	margin: 5px;
      	background-color: @base00;
      }

      #text {
      	margin: 0px;
      	padding: 2px 2px 2px 10px;
      }
    '';
  };
}
