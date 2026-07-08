# Fish shell — system enablement (login shell for hutch) + full user config.
# loginShellInit auto-launches Niri on TTY1.
{
  flake.modules.nixos.base = {
    programs.fish.enable = true;
  };

  flake.modules.homeManager.terminal = {
    programs.fish = {
      enable = true;

      shellAbbrs = {
        # Basic aliases
        c = "clear";
        ls = "eza --long --git --icons --all";
        l = "ls";

        # Git aliases
        gp = "git push";
        gpu = "git pull";
        gs = "git status";
        glo = "git log --oneline";
        gwtc = "git config --get remote.origin.fetch";
        gwtf = ''git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"'';
        cleangit = "git branch | awk '{print $1}' | xargs git branch -D && git fetch -p";
        gitlfsfix = "git rm --cached -r . && git reset --hard";

        # Nix
        nd = "nix develop -c $SHELL";

        # Cargo aliases
        cb = "cargo build";
        cbr = "cargo build --release";
        cr = "cargo run";
        ct = "cargo test";
      };

      shellAliases = {
        jjw = "jj_workspace_add";
        tm = "tmux_new_session";
      };

      loginShellInit = ''
        # Auto-launch Niri on TTY1
        if test (tty) = "/dev/tty1"; and not set -q WAYLAND_DISPLAY
          systemctl --user reset-failed
          systemctl --user import-environment
          dbus-update-activation-environment --all
          systemctl --user --wait start niri.service
          systemctl --user start --job-mode=replace-irreversibly niri-shutdown.target
          systemctl --user unset-environment WAYLAND_DISPLAY DISPLAY XDG_SESSION_TYPE XDG_CURRENT_DESKTOP NIRI_SOCKET
        end
      '';

      shellInit = ''
        # Disable fish greeting
        set -U fish_greeting ""

        # Load 1Password CLI plugins
        if test -f ~/.config/op/plugins.sh
          source ~/.config/op/plugins.sh
        end

        # Environment variables
        set -gx TERM screen-256color
        set -gx GO_PATH $HOME/go/bin
        set -gx DOCKER_GATEWAY_HOST 172.17.0.1
        # set -gx NVIM (which nvim)
        set -gx RIPGREP_CONFIG_PATH $HOME/.ripgreprc
        set -gx EDITOR "hx"

        set -gx SSH_AUTH_SOCK $HOME/.1password/agent.sock

        # Bun configuration
        set --export BUN_INSTALL "$HOME/.bun"
        set --export PATH $BUN_INSTALL/bin $PATH

        # Add paths
        fish_add_path "$CARGO_HOME/bin"
        fish_add_path $HOME/bin /usr/local/bin $HOME/.local/bin
        fish_add_path $HOME/.config/emacs/bin
        fish_add_path $HOME/.pulumi/bin
        fish_add_path $PNPM_HOME

        # Conditional path additions
        test -d $GO_PATH; and fish_add_path $GO_PATH
        test -d $JAVA_HOME/bin; and fish_add_path $JAVA_HOME/bin
        test -d $DOTNET_ROOT; and fish_add_path $DOTNET_ROOT

        # Key bindings
        bind \cf 'fish -c "~/scripts/tmux-sessionizer"'
        # bind \cf 'commandline -r "~/scripts/zellij-sessionizer; clear"; commandline -f execute'

        # Initialize tools
        starship init fish | source

        # Rustup/Cargo setup
        if test -d "$HOME/.cargo"
          set PATH "$HOME/.cargo/bin" $PATH
        end

        # Nix setup
        if test -e $HOME/.nix-profile/etc/profile.d/nix.fish
          source $HOME/.nix-profile/etc/profile.d/nix.fish
        end

        function jj_workspace_add --argument workspace_name
          if test -z "$workspace_name"
            echo "Usage jj_workspace_add <workspace_name"
            return 1
          end
          set folder (basename (pwd))
          jj workspace add "../$folder-$workspace_name"
        end

        function tmux_new_session
          set -l session_name (basename $PWD | tr '.' '_')
          tmux new-session -A -s $session_name
        end
      '';

      interactiveShellInit = "";
    };

    xdg.configFile."fish/completions/aws.fish".text = ''
      complete --command aws --no-files --arguments '(begin; set --local --export COMP_SHELL fish; set --local --export COMP_LINE (commandline); aws_completer; end)'
    '';
  };
}
