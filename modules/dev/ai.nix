# AI coding agents — pi + claude-code, with the pi agent config linked from
# configs/pi/agent
{ inputs, ... }:
{
  flake.modules.homeManager.dev =
    { pkgs, ... }:
    let
      piAgentPath = ../../configs/pi/agent;

      piSubagents = pkgs.buildNpmPackage {
        pname = "pi-subagents";
        version = "0.51.0-71ba8a5";
        src = inputs.pi-subagents;
        npmDepsHash = "sha256-kJqaHv5+vHj8F1QpK9ocsoXetdCoTtqC8aEq92yvUKk=";
        npmInstallFlags = [ "--omit=dev" ];
        dontNpmBuild = true;

        postPatch = ''
          substituteInPlace src/agents/agent-scope.ts \
            --replace-fail 'return "both";' 'return "user";'
          substituteInPlace src/extension/schemas.ts \
            --replace-fail "default: 'both'; project wins" "default: 'user'; project wins"
        '';

        installPhase = ''
          runHook preInstall

          mkdir -p "$out"
          cp package.json index.ts ./*.mjs README.md CHANGELOG.md LICENSE "$out/"
          cp -R src agents skills prompts docs node_modules "$out/"

          runHook postInstall
        '';
      };

      piExtensions = pkgs.runCommand "pi-agent-extensions" { } ''
        cp -R ${piAgentPath + /extensions} "$out"
        chmod -R u+w "$out"
        ln -s ${piSubagents} "$out/subagent/upstream"
      '';

      piSkills = pkgs.runCommand "pi-agent-skills" { } ''
        cp -R ${piAgentPath + /skills} "$out"
        chmod -R u+w "$out"
        ln -s ${piSubagents}/skills/pi-subagents "$out/pi-subagents"
      '';

      piPrompts = pkgs.runCommand "pi-agent-prompts" { } ''
        cp -R ${piAgentPath + /prompts} "$out"
        chmod -R u+w "$out"
        cp -R ${piSubagents}/prompts/. "$out/"
      '';

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
          codex
          claude-code
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
        source = piSkills;
        recursive = true;
      };

      # agents
      home.file.".pi/agent/agents" = {
        source = piAgentPath + "/agents";
        recursive = true;
      };

      # extensions
      home.file.".pi/agent/extensions" = {
        source = piExtensions;
        recursive = true;
      };

      # prompts
      home.file.".pi/agent/prompts" = {
        source = piPrompts;
        recursive = true;
      };

      # themes
      home.file.".pi/agent/themes" = {
        source = piAgentPath + "/themes";
        recursive = true;
      };
    };
}
