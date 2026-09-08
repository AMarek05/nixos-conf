{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
let
  podman = lib.getExe pkgs.podman;
  # Pre-backup: Detect running container, flush chunks, and disable disk writes
  preBackup = pkgs.writeShellScript "mc-restic-prepare" ''
    set -euo pipefail

    if systemctl is-active --quiet podman-gtnh.service; then
      CONTAINER="gtnh"
    elif systemctl is-active --quiet podman-startech.service; then
      CONTAINER="startech"
    else
      echo "No active server; continuing snapshot."
      exit 0
    fi

    echo "Locking world writes on: $CONTAINER"
    ${podman} exec "$CONTAINER" rcon-cli "say [Server] Starting local backup..." || true
    ${podman} exec "$CONTAINER" rcon-cli "save-off" || true
    ${podman} exec "$CONTAINER" rcon-cli "save-all flush" || true
    sleep 3
  '';

  # Post-backup: Re-enable disk writes
  postBackup = pkgs.writeShellScript "mc-restic-cleanup" ''
    set -euo pipefail

    for CONTAINER in gtnh startech; do
      if systemctl is-active --quiet "podman-$CONTAINER.service"; then
        echo "Re-enabling world writes on: $CONTAINER"
        ${podman} exec "$CONTAINER" rcon-cli "save-on" || true
        ${podman} exec "$CONTAINER" rcon-cli "say [Server] Local backup complete!" || true
      fi
    done
  '';

  mcRestoreScript = pkgs.writeShellScriptBin "mc-restore" ''
    set -euo pipefail

    REPO="/mnt/backup/minecraft-restic"
    PASS_FILE="${config.sops.secrets."restic-password".path}"

    # Enforce root execution
    if [ "$EUID" -ne 0 ]; then
      echo "Error: Please run this script with sudo."
      exit 1
    fi

    # Check repository path and secret file exist
    if [ ! -d "$REPO" ]; then
      echo "Error: Restic repository directory not found at $REPO"
      exit 1
    fi

    if [ ! -f "$PASS_FILE" ]; then
      echo "Error: Password file not found at $PASS_FILE"
      exit 1
    fi

    echo "==> Fetching available snapshots..."

    # Use fzf to allow interactive snapshot selection
    SNAPSHOT_LINE=$(${pkgs.restic}/bin/restic -r "$REPO" --password-file "$PASS_FILE" snapshots \
      | ${pkgs.gawk}/bin/awk 'NR>2 {print $0}' \
      | ${pkgs.fzf}/bin/fzf --header="Select a snapshot to restore (ESC to cancel)" --reverse)

    if [ -z "$SNAPSHOT_LINE" ]; then
      echo "No snapshot selected. Aborting."
      exit 0
    fi

    # Extract the Snapshot ID (first column)
    SNAPSHOT_ID=$(echo "$SNAPSHOT_LINE" | ${pkgs.gawk}/bin/awk '{print $1}')
    echo "Selected Snapshot: $SNAPSHOT_ID"

    # Prompt user for which server to restore
    echo ""
    echo "Which server do you want to restore?"
    echo "  1) GTNH only (/var/lib/minecraft/gtnh-data)"
    echo "  2) StarTech only (/var/lib/minecraft/startech-data)"
    echo "  3) Both servers"
    echo "  4) Cancel"
    read -rp "Select an option [1-4]: " CHOICE

    INCLUDE_FLAG=""
    TARGET_DIR=""
    case "$CHOICE" in
      1)
        INCLUDE_FLAG="--include /var/lib/minecraft/gtnh-data"
        TARGET_DIR="/var/lib/minecraft/gtnh-data"
        ;;
      2)
        INCLUDE_FLAG="--include /var/lib/minecraft/startech-data"
        TARGET_DIR="/var/lib/minecraft/startech-data"
        ;;
      3)
        INCLUDE_FLAG=""
        TARGET_DIR="/var/lib/minecraft/gtnh-data /var/lib/minecraft/startech-data"
        ;;
      *)
        echo "Cancelled."
        exit 0
        ;;
    esac

    echo ""
    read -rp "WARNING: This will overwrite files in selected directories. Continue? [y/N]: " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
      echo "Aborted."
      exit 0
    fi

    echo "==> Stopping running Minecraft containers..."
    systemctl stop podman-gtnh.service podman-startech.service || true

    echo "==> Restoring files from snapshot $SNAPSHOT_ID..."
    ${pkgs.restic}/bin/restic -r "$REPO" \
      --password-file "$PASS_FILE" \
      restore "$SNAPSHOT_ID" \
      --target / \
      $INCLUDE_FLAG

    echo "==> Fixing file permissions (1000:1000)..."
    chown -R 1000:1000 $TARGET_DIR

    echo ""
    echo "Restore complete!"

    STATE_FILE="/var/lib/minecraft/active_server"

    read -rp "Do you want to start a server now? [gtnh/startech/no]: " START_SRV
    case "$START_SRV" in
      gtnh|startech)
        echo "$START_SRV" > "$STATE_FILE"
        systemctl start "podman-$START_SRV.service"
        echo "Started podman-$START_SRV.service and updated $STATE_FILE."
        ;;
      *)
        rm -f "$STATE_FILE"
        echo "Servers left stopped and $STATE_FILE cleared."
        ;;
    esac
  '';
in
{
  sops.secrets."restic-password" = {
    sopsFile = "${inputs.self}/secrets/serv.yaml";
    mode = "400";
  };

  services.restic.backups.minecraft-local = {
    # Automatically initialize the repository directory if it doesn't exist
    initialize = true;

    # Local path on the other drive
    repository = "/mnt/backup/minecraft-restic";

    # Path to the single-line password file
    passwordFile = config.sops.secrets."restic-password".path;

    # Directories to snapshot
    paths = [
      "/var/lib/minecraft/gtnh-data"
      "/var/lib/minecraft/startech-data"
    ];

    exclude = [
      "*.log"
      "*.log.gz"
      "crash-reports"
      "backups"
      "cache"
    ];

    backupPrepareCommand = "${preBackup}";
    backupCleanupCommand = "${postBackup}";

    # Scheduled run (daily at 03:00 AM)
    timerConfig = {
      OnCalendar = "*-*-* 03:00:00";
      Persistent = true;
    };

    # Retention rules
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 6"
    ];
  };

  environment.systemPackages = [
    mcRestoreScript
    pkgs.podman
    (pkgs.writeShellScriptBin "mc-restic" ''
      ${lib.getExe pkgs.restic} -r /mnt/backup/minecraft-restic/ --password-file ${
        config.sops.secrets."restic-password".path
      } "$@"
    '')
  ];
}
