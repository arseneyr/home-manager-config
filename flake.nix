{
  description = "Home manager config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      homeConfigurations.aromanenko = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [{
          home.username = "aromanenko";
          home.homeDirectory = "/home/aromanenko";
          home.stateVersion = "24.05";

          programs.home-manager.enable = true;

          programs.git = {
            enable = true;
            settings = {
              core.sshCommand = "/usr/bin/ssh";
            };
          };

          programs.claude-code = {
            enable = true;
            package = pkgs.claude-code;
            mcpServers = {
              nixos = {
                type = "stdio";
                command = "nix";
                args = ["run" "github:utensils/mcp-nixos"];
              };
            };
          };

          home.packages = with pkgs; [
            curl
            jq
            delta
            ghostty.terminfo
            ghostty.shell_integration
          ];

          programs.bash = {
            enable = true;
            historyControl = [ "ignoreboth" ];
            historySize = 1000;
            historyFileSize = 2000;
            shellOptions = [
              "histappend"
              "checkwinsize"
            ];

            shellAliases = {
              ls = "ls --color=auto";
              grep = "grep --color=auto";
              fgrep = "fgrep --color=auto";
              egrep = "egrep --color=auto";
              ll = "ls -alF";
              la = "ls -A";
              l = "ls -CF";
              alert = ''notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e 's/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//')"'';
              cptags = "cp -f /mnt/gravytrain/build/latest/src/tags ~/src";
              aws = "/usr/local/bin/aws";

              # srcrun aliases
              qqi = "srcrun simnode/qq_internal --dir build/tmp/cluster";
              s3 = "srcrun simnode/s3.py";
              cr = "srcrun ./check_run.py -b -c";
              lint = "srcrun lint/all -ac";
              qc = "srcrun simnode/qc";
              b = "srcrun build";
              trg = "srcrun tools/red_green.py";
              demo = "srcrun fs/portal/demo.sh";
              merge = "srcrun hg qpush --merge -n";
              fetch = "srcrun hg fetch && ./prebuild";
              debug = "srcrun less build/tmp/latest/**/debug.log";
              output = "srcrun less build/tmp/latest/**/test_output";
              np = "srcrun infrastructure/hg/tools/hg_next_patch.py";
              pp = "srcrun infrastructure/hg/tools/hg_next_patch.py --prev";
              cpra = "srcrun cp -f /mnt/gravytrain/build/latest/src/rust-project.json . && pkill rust-analyzer";
              tn = "srcrun triage/triageninja";
              renumber = "~/src/infrastructure/hg/tools/hg_renumber_patches.py";
              enzo = "source ~/src/tools/qston/enzo/enzo.bash";
              claude-yolo = "claude --dangerously-skip-permissions";
              claude = "claude --permission-mode auto";

              flake-update = "nix flake update --flake ~/.config/home-manager && home-manager switch --flake ~/.config/home-manager";
            };

            initExtra = ''
              export CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING=1

              # Auto-attach to tmux on SSH login
              if [ -n "$SSH_CONNECTION" ] && [ -z "$TMUX" ]; then
                tmux new-session -A -s main
              fi

              # Prompt coloring
              if [ -z "''${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
                debian_chroot=$(cat /etc/debian_chroot)
              fi
              case "$TERM" in
                xterm-color|*-256color) color_prompt=yes;;
              esac
              if [ "$color_prompt" = yes ]; then
                PS1="''${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "
              else
                PS1="''${debian_chroot:+($debian_chroot)}\u@\h:\w\$ "
              fi
              unset color_prompt
              case "$TERM" in
                xterm*|rxvt*)
                  PS1="\[\e]0;''${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
                  ;;
              esac

              # lesspipe
              [ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

              # dircolors
              if [ -x /usr/bin/dircolors ]; then
                test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
              fi

              export GITHUB_TOKEN=$(cat /etc/coder/ghtoken)
              export PATH="/opt/qumulo/toolchain/bin:''${PATH}"


              # Configure vscode/cursor as hg merge tool
              code_latest_version=$(ls ''${HOME}/.vscode-server/bin/ | sort -V | tail -n 1)
              code="''${HOME}/.vscode-server/bin/''${code_latest_version}/bin/remote-cli/code"
              escaped_code=$(echo $code | sed 's/\//\\\//g')
              sed -i.bak "/^three-way-merge.cmd =/c\three-way-merge.cmd = ''${escaped_code} -w -m \$local \$other \$base \$output" ~/.hgrc

              # VSCode shell integration for AI terminals
              if [[ "$TERM_PROGRAM" == "vscode" ]]; then
                . "$(cursor --locate-shell-integration-path bash)"
              fi

              # srcrun helper
              SRC_DIR="''${HOME}/src"
              srcrun () {
                ( cd "''${SRC_DIR}" && command "$@" )
              }

              # Show which files each pending submission modifies
              # Optional arg: partial filename to filter by
              hg-pending-files () {
                (
                  cd "''${SRC_DIR}" || return 1
                  local filter="$1"
                  hg pending --patches 2>/dev/null | awk -v filter="$filter" '
                    /^Submission [0-9]+ has/ {
                      if (sub_id != "" && file_count > 0) {
                        printf "\033[1;33m%s\033[0m\t%s\n", sub_id, user
                        for (i = 1; i <= file_count; i++) print "  " files[i]
                        print ""
                      }
                      sub_id = $2; user = ""; delete files; file_count = 0; seen_file_reset = 1
                      delete seen
                      next
                    }
                    /^# User / && user == "" {
                      user = substr($0, 8)
                      next
                    }
                    /^diff --git / {
                      match($0, /^diff --git a\/(.*) b\/(.*)$/, m)
                      a = m[1]; b = m[2]
                      if (filter != "") {
                        if (tolower(a) !~ tolower(filter) && tolower(b) !~ tolower(filter)) next
                      }
                      if (a == b) {
                        if (!seen[a]++) files[++file_count] = a
                      } else {
                        if (!seen[b]++) files[++file_count] = a " -> " b
                      }
                    }
                    END {
                      if (sub_id != "" && file_count > 0) {
                        printf "\033[1;33m%s\033[0m\t%s\n", sub_id, user
                        for (i = 1; i <= file_count; i++) print "  " files[i]
                        print ""
                      }
                    }
                  '
                )
              }

              # fold helper for hg patch queues
              fold () {
                local next_patch
                next_patch="$(hg qunapplied | head -1)"
                if [ -z "$next_patch" ]; then
                  echo "No unapplied patches to fold"
                  return 1
                fi
                hg qfold -m "$(hg log -r qtip --template '{desc}')" "$next_patch"
              }
            '';
          };

          programs.tmux = {
            enable = true;
            mouse = true;
            keyMode = "vi";
            prefix = "C-a";
            terminal = "tmux-256color";
            extraConfig = ''
              set -g allow-passthrough all
              set -g set-titles on
              set -g set-clipboard on
              set -g update-environment "SSH_AUTH_SOCK SSH_CONNECTION DISPLAY"
              bind-key -T copy-mode-vi WheelUpPane send-keys -X scroll-up
              bind-key -T copy-mode-vi WheelDownPane send-keys -X scroll-down

              # Open new window with Claude (prefix + a)
              bind-key a new-window -n claude -c '#{HOME}/src' 'claude'

              # Prefix key indicator in status bar
              set -g status-right "#{?client_prefix,#[bg=red#,fg=white] ^A #[default] ,}#[default]%a %d %b %H:%M"
            '';
          };
        }];
      };
    };
}
