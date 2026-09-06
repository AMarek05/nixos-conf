# hosts/nixos/oci/default.nix
{ inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    ./disko.nix
  ];

  # Bound by-uuid to match nixos-server's style. Switch to by-id/oracleoci.io-<OCID>-partN if OCI rotates UUIDs.
  swapDevices = [
    { device = "/dev/disk/by-uuid/def7fd2d-98f9-4ed1-a524-22ebc920be09"; }
  ];

  fileSystems."/data" = {
    device = "/dev/disk/by-uuid/8d879299-7a60-478e-a629-48221801d1c5";
    fsType = "ext4";
    neededForBoot = false;
    options = [
      "nofail"
      "x-systemd.device-timeout=10s"
      "discard"
    ];
  };
}
