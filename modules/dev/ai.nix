# AI coding agents — pi + claude-code, with the pi agent config linked from
# configs/pi/agent
{ inputs, ... }:
{
  flake.modules.homeManager.dev =
    { pkgs, ... }:
    let
      piAgentPath = ../../configs/pi/agent;

      # Nix-friendly wrapper for the npm MCP proxy used by remote MCP pi extensions.
      # Use npx from Nix's nodejs package. bunx is tempting, but `bunx -p
      # mcp-remote mcp-remote` resolves the mcp-remote executable from PATH first on
      # this system, which recursively calls this wrapper and exits before the MCP
      # stdio server starts.
      mcpRemote = pkgs.writeShellApplication {
        name = "mcp-remote";
        runtimeInputs = with pkgs; [
          nodejs
        ];
        text = ''
          export NPM_CONFIG_UPDATE_NOTIFIER=false
          exec npx -y mcp-remote "$@"
        '';
      };
    in
    {
      # note: libnotify is part of desktop do not add here
      home.packages =
        (with pkgs; [
          fd
          ripgrep
          # pi-coding-agent
          inputs.pi-mono-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
          inputs.claude-code-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
          inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
        ])
        ++ [ mcpRemote ];

      # package metadata / docs
      home.file.".pi/agent/package.json" = {
        source = piAgentPath + /package.json;
      };

      home.file.".pi/agent/README.md" = {
        source = piAgentPath + /README.md;
      };

      # append system
      home.file.".pi/agent/APPEND_SYSTEM.md" = {
        source = piAgentPath + /APPEND_SYSTEM.md;
      };

      # keybindings
      home.file.".pi/agent/keybindings.json" = {
        source = piAgentPath + /keybindings.json;
      };

      # skills
      home.file.".pi/agent/skills" = {
        source = piAgentPath + /skills;
        recursive = true;
      };

      # agents
      home.file.".pi/agent/agents" = {
        source = piAgentPath + "/agents";
        recursive = true;
      };

      # extensions
      home.file.".pi/agent/extensions" = {
        source = piAgentPath + "/extensions";
        recursive = true;
      };

      # prompts
      home.file.".pi/agent/prompts" = {
        source = piAgentPath + "/prompts";
        recursive = true;
      };

      # themes
      home.file.".pi/agent/themes" = {
        source = piAgentPath + "/themes";
        recursive = true;
      };
    };
}
