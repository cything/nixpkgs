{ config, lib, pkgs, ... }:
let
  cfg = config.services.wallabag;
  isPostgresUnixSocket = lib.hasPrefix "/" cfg.database.host;

  # https://doc.wallabag.org/en/admin/parameters
  parametersFile = pkgs.writeText "parameters.yml" (lib.generators.toYAML {} {
    database_driver = "pdo_pgsql";

    # these will be ignored if database_socket is set
    database_host = cfg.database.host;
    database_port = cfg.database.port;

    database_name = cfg.database.name;
    database_user = cfg.database.user;
    database_password = cfg.database.password;
    database_table_prefix = cfg.database.tablePrefix;
    database_charset = "utf8";
    domain_name = cfg.domain;
    server_name = cfg.serverName;
    mailer_dns = cfg.mailerDsn;
    from_email = cfg.fromEmail;
    redis_scheme = cfg.redis.scheme;
    # host and port are ignored when scheme is unix
    redis_host = cfg.redis.host;
    redis_port = cfg.redis.port;
    # path is ignored when scheme is tcp or http
    redis_path = cfg.redis.path;

    # we use Redis instead of RabbitMQ
    rabbitmq_host = null;
  } // lib.optionalAttrs isPostgresUnixSocket {
    database_socket = cfg.database.host;
  }
  );
in
{
  meta.maintainers = with lib.maintainers; [ cyting ];

  options.services.wallabag = with lib; {
    enable = mkEnableOption "wallabag";
    package = mkPackageOption pkgs "wallabag" { };

    user = mkOption {
      types = types.str;
      default = "wallabag";
      description = "User under which Wallabag runs";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/wallabag";
      description = "Data folder for Wallabag";
      example = "/mnt/wallabag";
    };

    domain = mkOption {
      type = types.str;
      default = "http://localhost";
      description = "Domain where your wallabag instance will be hosted";
      example = "https://wallabag.example.com";
    };

    serverName = mkOption {
      type = types.str;
      default = "Your wallabag instance";
      description = "Name for your wallabag instance";
    };

    mailerDsn = mkOption {
      type = types.str;
      default = "smtp://127.0.0.1";
      description = "DSN address of your mail server. See https://symfony.com/doc/current/mailer.html";
      example = "smtp://user:pass@smtp.example.com:port";
    };

    fromEmail = mkOption {
      type = stypes.str;
      default = "no-reply@wallabag.org";
      description = "From address used for sending transactional emails";
    };

    database = {
      createLocally = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether a PostgreSQL database should be automatically created and confiugred. If
          set to `false`, you need to provision a database yourself.
        '';
      };
      name = mkOption {
        type = types.str;
        default = "wallabag";
        description = "Database name for PostgreSQL";
      };
      user = mkOption {
        type = types.str;
        default = "wallabg";
        description = "Database username for PostgreSQL";
      };
      host = mkOption {
        type = types.str;
        default = "/run/postgresql";
        description = "Hostname or address where your PostgreSQL database is hosted. If an absolute path is given, it will be interpreted as a unix socket path";
      };
      port = mkOption {
        type = types.port;
        default = 5432;
        description = "Port for the database host";
      };
      password = mkOption {
        type = types.nullOr types.port;
        default = null;
        description = "Password to connect to the database. Leave blank to
                      authenticate over UNIX socket";
      };
      tablePrefix = mkOption {
        type = types.str;
        default = "wallabag_";
        description = "Table prefix to use when creating tables";
      };
    };

    redis = {
      createLocally = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to create a local redis automatically";
      };
      scheme = mkOption {
        type = types.enum [ "unix" "tcp" "http" ];
        default = "unix";
        description = "Protocol to use to communicate with Redis";
      };
      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "IP or hostname of the Redis server (ignored for unix scheme)";
      };
      port = mkOption {
        type = types.port;
        default = 5672;
        description = "TCP/IP port of the Redis server (ignored for unix scheme)";
      };
      path = mkOption {
        type =types.str;
        default = "/run/redis-wallabag/redis.sock";
        description = "Path of the UNIX socket used to connect to the Redis server when using UNIX scheme";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    users.users."${cfg.user}" = {
      description = "Wallabag service user";
      isSystemUser = true;
      home = cfg.dataDir;
    };

    services.postgresql = lib.mkIf cfg.database.createLocally {
      enable = true;
      ensureUsers = [
        {
          name = "wallabag";
          ensureDBOwnership = true;
        }
      ];
      ensureDatabases = [ "wallabag" ];
    };

    systemd.services.wallabag = {
      description = "Wallabag service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ]
              ++ lib.optionals cfg.database.createLocally [ "postgresql.service" ];
      script = ''
        cp -r ${cfg.package}/app ${cfg.dataDir}
        # override the default parameters.yml
        cp ${parametersFile} ${cfg.dataDir}/config/parameters.yml;
        # necessary to apply changes
        ${cfg.package}/bin/console cache:clear --env=prod
      '';

      serviceConfig = {
        Type = "notify";
        User = cfg.user;
        DynamicUser = true;
        RuntimeDirectory = "wallabag";
        RuntimeDirectoryMode = "0750";
        WatchdogSec = 60;
        WatchdogSignal = "SIGKILL";
        Restart = "always";
        RestartSec = 5;

        CapabilityBoundingSet = [ "" ];
        DeviceAllow = [ "" ];
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        PrivateDevices = true;
        PrivateUsers = true;
        ProcSubnet = "pid";
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        REstrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDGID = true;
        SystemCallArchitecture = "native";
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
        ];
        UMask = "0077";

        Environment = {
          SYMFONY_ENV = "prod";
        };
      };
    };

    environment.systemPackages = [ cfg.package ];
  };
}
