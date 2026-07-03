# AMD power management and display — both hosts are AMD machines
{
  flake.modules.nixos.amd = {
    boot.kernelParams = [
      "amd_pstate=active"
      "amdgpu.dc=1"
    ];
    hardware.graphics.enable = true;
  };
}
