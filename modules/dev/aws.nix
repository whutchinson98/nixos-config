# AWS CLI with credentials served from 1Password
{
  flake.modules.homeManager.dev =
    { pkgs, ... }:
    let
      opAwsWorkCreds = pkgs.writeShellApplication {
        name = "op-aws-work-creds";
        runtimeInputs = [
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
      home.packages = [
        opAwsCreds
        opAwsWorkCreds
        pkgs.awscli2
      ];

      home.file.".aws/config".text = ''
        [profile work]
        region = us-east-1
        output = json
        credential_process = ${opAwsWorkCreds}/bin/op-aws-work-creds
        [profile personal]
        region = us-east-1
        output = json
        credential_process = ${opAwsCreds}/bin/op-aws-creds
      '';
    };
}
