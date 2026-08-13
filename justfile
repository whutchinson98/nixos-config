switch:
    sudo nixos-rebuild switch --flake .#$(hostname)

boot:
    sudo nixos-rebuild boot --flake .#$(hostname)

update:
    nix flake update

# Generate hardware config for the current host
hardware-config:
    nixos-generate-config --show-hardware-config > modules/hosts/$(hostname)/_hardware.nix

# Deploy to a remote host (usage: just deploy media)
deploy host:
    nixos-rebuild switch --flake .#{{host}} --target-host root@{{host}}
