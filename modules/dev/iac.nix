# Infrastructure-as-code tools — Pulumi and Terraform
{
  flake.modules.homeManager.dev =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        pulumi
        pulumiPackages.pulumi-nodejs
        pulumiPackages.pulumi-aws-native

        terraform
        terraform-ls
        terragrunt
      ];
    };
}
