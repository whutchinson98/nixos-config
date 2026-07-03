{
  flake.modules.homeManager.terminal = {
    programs.tmux = {
      enable = true;
      terminal = "alacritty";
      historyLimit = 15000;
      prefix = "C-a";
      baseIndex = 1;
      mouse = true;
      escapeTime = 20;

      extraConfig = ''
        set-option -sa terminal-features ',alacritty:RGB'
        set-option -ga terminal-features ",alacritty:usstyle"
        set-option -ga terminal-overrides ',alacritty:Tc'

        set-option -sa terminal-overrides ',screen-256color:Tc'

        set -as terminal-overrides ',*:Ss=\E[%p1%d q:Se=\E[2 q'

        set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'
        set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'

        unbind C-b
        bind-key C-a send-prefix

        bind | split-window -h -c "#{pane_current_path}"
        bind - split-window -v -c "#{pane_current_path}"
        unbind '"'
        unbind %

        unbind Up
        unbind Down
        unbind Left
        unbind Right

        bind r source-file ~/.tmux.conf

        bind q kill-session

        bind-key -r -T prefix Up resize-pane -U
        bind-key -r -T prefix Down resize-pane -D
        bind-key -r -T prefix Left resize-pane -L
        bind-key -r -T prefix Right resize-pane -R
        bind-key -r -T prefix S-Up resize-pane -U 5
        bind-key -r -T prefix S-Down resize-pane -D 5
        bind-key -r -T prefix S-Left resize-pane -L 5
        bind-key -r -T prefix S-Right resize-pane -R 5

        bind -r ^ last-window
        bind -r k select-pane -U
        bind -r j select-pane -D
        bind -r h select-pane -L
        bind -r l select-pane -R

        set -g set-clipboard on
        set -g allow-passthrough on
        set -as terminal-features ',*:clipboard'
        set -g extended-keys on
        set -g extended-keys-format csi-u

        bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
        bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-selection-and-cancel
      '';
    };
  };
}
