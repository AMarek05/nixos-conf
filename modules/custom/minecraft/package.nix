# modules/custom/minecraft/package.nix
#
# `mc-manage` — switches between the Minecraft servers declared in
# `nixosModules.minecraft.servers` and reports their state. The server list is
# interpolated at build time, so the tool follows the declared servers.
{
  lib,
  servers,
  backend,
  activeServerFile,
  writeShellApplication,
  systemd,
  coreutils,
  ...
}:
let
  names = lib.attrNames servers;

  descriptionArray = lib.concatMapStringsSep "\n" (
    name: "  [${lib.escapeShellArg name}]=${lib.escapeShellArg servers.${name}.description}"
  ) names;

  unitArray = lib.concatMapStringsSep "\n" (
    name: "  [${lib.escapeShellArg name}]=${lib.escapeShellArg "${backend}-${name}"}"
  ) names;

  # Associative arrays have no defined iteration order, so the listing would
  # come out shuffled without this.
  nameArray = lib.concatMapStringsSep "\n" (name: "  ${lib.escapeShellArg name}") names;
in
writeShellApplication {
  name = "mc-manage";
  runtimeInputs = [
    systemd
    coreutils
  ];
  meta.description = "Switch between the declared Minecraft servers.";

  text = ''
    declare -A DESCRIPTIONS=(
    ${descriptionArray}
    )

    declare -A UNITS=(
    ${unitArray}
    )

    SERVERS=(
    ${nameArray}
    )

    STATE_FILE=${lib.escapeShellArg activeServerFile}

    usage() {
      cat <<EOF
    Usage: mc-manage <command>

    Commands:
      status           List the declared servers, the active one marked with *
      switch <server>  Switch to <server>, showing the logs of both servers
      help             Show this message
    EOF
    }

    active_server() {
      if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
      fi
    }

    cmd_status() {
      local active name mark
      active=$(active_server)

      for name in "''${SERVERS[@]}"; do
        if [ "$name" = "$active" ]; then
          mark="*"
        else
          mark=" "
        fi
        printf '%s %-12s %s\n' "$mark" "$name" "''${DESCRIPTIONS[$name]}"
      done
    }

    cmd_switch() {
      local target="$1"
      local name unit old_unit="" follower="" since

      if [ -z "$target" ]; then
        echo "mc-manage: switch needs a server name" >&2
        usage >&2
        exit 1
      fi

      if [ -z "''${UNITS[$target]+x}" ]; then
        echo "mc-manage: unknown server '$target'" >&2
        echo "Known servers: ''${SERVERS[*]}" >&2
        exit 1
      fi

      if [ "$(id -u)" -ne 0 ]; then
        echo "mc-manage: switching needs root, run: sudo mc-manage switch $target" >&2
        exit 1
      fi

      since=$(date +%s)

      for name in "''${SERVERS[@]}"; do
        unit="''${UNITS[$name]}"
        if systemctl is-active --quiet "$unit"; then
          old_unit="$unit"
          break
        fi
      done

      # Follow the running server while it shuts down, so the switch shows
      # what the old server says on its way out.
      if [ -n "$old_unit" ] && [ "$old_unit" != "''${UNITS[$target]}" ]; then
        journalctl --unit "$old_unit" --follow --no-pager &
        follower=$!
      fi

      # Starting the target stops the running one, they conflict.
      systemctl start "''${UNITS[$target]}"

      if [ -n "$follower" ]; then
        kill "$follower" 2>/dev/null || true
        wait "$follower" 2>/dev/null || true
      fi

      printf '%s\n' "$target" >"$STATE_FILE"
      echo "Switched to $target (''${DESCRIPTIONS[$target]})"

      # Then follow the new server as it comes up. Ctrl-C to stop watching.
      journalctl --unit "''${UNITS[$target]}" --since "@$since" --follow --no-pager
    }

    case "''${1-}" in
      status)
        cmd_status
        ;;
      switch)
        shift
        cmd_switch "''${1-}"
        ;;
      help | --help | -h)
        usage
        ;;
      "")
        usage
        ;;
      *)
        # Bare server name is shorthand for `switch`.
        cmd_switch "''${1-}"
        ;;
    esac
  '';
}
