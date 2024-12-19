{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.wallabag;
in
{
  meta.maintainers = with maintainers; [ cyting ];

  options.services.wallabag = {
    enable = mkEnableOption "TODO: description";
    package = mkPackageOption pkgs "wallabag" { };
    user = mkOption {
      types = types.str;
      default = "wallabag";
      description = "User under which Wallabag runs";
    };

    database = {
      type = mkOption {
        type = types.enum [ "pgsql" "mysql" ];
      };
    };
  };

  config =
    let
      defaultServiceConfig = {
        DeviceAllow = "";
        LockPersonality = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProcSubset = "pid";
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunable = true;
        ProtectProc = "invisible";
        ProtectSystem = "strict";
        ProtectIPC = true;
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDGID = true;
        SystemCallArchitecture = "native";
        SystemCallFilter = [ "@system-service" "~@resources" "~@privileged" ];
        UMask = "0007";
        Type = "onehost";
        User = cfg.user;
        Group = config.users.users.${cfg.user}.group;
        StateDirectory = "wallabag";
        WorkingDirectory = cfg.package;
      };
    in
    mkIf cfg.enable {

    };
}
