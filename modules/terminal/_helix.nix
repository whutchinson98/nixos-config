{
  flake.modules.homeManager.terminal =
    { pkgs, ... }:
    {
      programs.helix = {
        enable = true;
        settings = {
          theme = "nord";
          editor = {
            bufferline = "multiple";
            file-picker = {
              hidden = false;
              git-ignore = true;
            };
            cursor-shape = {
              insert = "block";
              normal = "block";
              select = "underline";
            };
            line-number = "relative";
            cursorline = true;
            auto-format = true;
            end-of-line-diagnostics = "hint";
            soft-wrap = {
              enable = true;
            };
            lsp = {
              display-inlay-hints = true;
              display-messages = true;
              display-progress-messages = true;
            };
            inline-diagnostics = {
              cursor-line = "hint";
            };
          };
          keys = {
            normal = {
              esc = [
                "keep_primary_selection"
                "collapse_selection"
              ];
              space = {
                s = {
                  l = "vsplit";
                };
              };
              minus = "file_picker_in_current_buffer_directory";
            };
          };
        };
        languages = {
          language-server.terraform-ls = {
            command = "terraform-ls";
            args = [ "serve" ];
          };
          language-server.gopls = {
            command = "gopls";
          };
          language-server.rust-analyzer = {
            config = {
              check = {
                command = "clippy";
              };
              checkOnSave = true;
              cargo = {
                allFeatures = true;
              };
            };
          };
          language = [
            {
              name = "go";
              scope = "source.go";
              file-types = [ "go" ];
              auto-format = true;
              formatter = {
                command = "goimports";
              };
              language-servers = [ "gopls" ];
              indent = {
                tab-width = 4;
                unit = "\t";
              };
            }
            {
              name = "nix";
              scope = "source.nix";
              file-types = [ "nix" ];
              auto-format = true;
              formatter = {
                command = "${pkgs.nixfmt}/bin/nixfmt";
              };
            }
            {
              name = "rust";
              scope = "source.rust";
              file-types = [ "rs" ];
              auto-format = true;
              formatter = {
                command = "rustfmt";
                args = [
                  "--edition"
                  "2024"
                ];
              };
              indent = {
                tab-width = 4;
                unit = "t";
              };
            }
            {
              name = "json";
              scope = "source.json";
              file-types = [ "json" ];
              auto-format = true;
            }
            {
              name = "just";
              scope = "source.just";
              file-types = [ "just" ];
              auto-format = true;
              formatter = {
                command = "just";
                args = [
                  "--justfile"
                  "/dev/stdin"
                  "--dump"
                ];
              };
            }
            {
              name = "toml";
              scope = "source.toml";
              file-types = [ "toml" ];
              auto-format = true;
              formatter = {
                command = "taplo";
                args = [
                  "format"
                  "-"
                ];
              };
            }
            {
              name = "terraform";
              scope = "source.terraform";
              file-types = [
                "tf"
                "tfvars"
              ];
              auto-format = true;
              language-servers = [ "terraform-ls" ];
            }
            {
              name = "typescript";
              scope = "source.tsx";
              roots = [
                "package.json"
              ];
              file-types = [
                "ts"
                "tsx"
              ];
              auto-format = true;
              language-servers = [ "typescript-language-server" ];
            }
          ];
        };
      };
    };
}
