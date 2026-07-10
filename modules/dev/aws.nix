# AWS CLI with an optional 1Password credentials provider
{
  flake.modules.homeManager.dev =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.dotfiles.aws;
      useOnePassword = cfg.credentialProvider == "onepassword";

      opAwsWorkCreds = pkgs.writeShellApplication {
        name = "op-aws-work-creds";
        runtimeInputs = [
          pkgs._1password-cli
          pkgs.jq
        ];

        text = ''
          set -euo pipefail

          access_key_id="$(op read 'op://Private/aws_work/access key id')"
          secret_access_key="$(op read 'op://Private/aws_work/secret access key')"

          jq -n \
            --arg ak "$access_key_id" \
            --arg sk "$secret_access_key" \
            '{Version:1, AccessKeyId:$ak, SecretAccessKey:$sk}'
        '';
      };
      opAwsCreds = pkgs.writeShellApplication {
        name = "op-aws-creds";
        runtimeInputs = [
          pkgs._1password-cli
          pkgs.jq
        ];

        text = ''
          set -euo pipefail

          access_key_id="$(op read 'op://Programming/aws-hutchery/access key id')"
          secret_access_key="$(op read 'op://Programming/aws-hutchery/secret access key')"

          jq -n \
            --arg ak "$access_key_id" \
            --arg sk "$secret_access_key" \
            '{Version:1, AccessKeyId:$ak, SecretAccessKey:$sk}'
        '';
      };
    in
    {
      options.dotfiles.aws.credentialProvider = lib.mkOption {
        type = lib.types.enum [
          "default-chain"
          "onepassword"
        ];
        default = "default-chain";
        description = "Credential provider to configure for AWS CLI profiles.";
      };

      config = {
        home.packages = [
          pkgs.awscli2
        ]
        ++ lib.optionals useOnePassword [
          opAwsCreds
          opAwsWorkCreds
        ];

        home.file.".aws/config".text = ''
          [profile work]
          region = us-east-1
          output = json
          ${lib.optionalString useOnePassword "credential_process = ${opAwsWorkCreds}/bin/op-aws-work-creds"}

          [profile personal]
          region = us-east-1
          output = json
          ${lib.optionalString useOnePassword "credential_process = ${opAwsCreds}/bin/op-aws-creds"}
        '';
      };
    };
}
