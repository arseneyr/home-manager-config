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

          home.packages = with pkgs; [
            curl
            jq
            claude-code
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
              cr = "srcrun ./check_run.py -b -c --auto-remote-test-execution";
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
            };

            initExtra = ''
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
              set -g allow-passthrough on
              set -g set-clipboard on
              set -g update-environment "SSH_AUTH_SOCK SSH_CONNECTION DISPLAY"
              bind-key -T copy-mode-vi WheelUpPane send-keys -X scroll-up
              bind-key -T copy-mode-vi WheelDownPane send-keys -X scroll-down
            '';
          };
        }];
      };
    };
}
