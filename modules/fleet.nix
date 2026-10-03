{ den, ... }:
{
  den.quirks.http-services = {
    description = "HTTP services available in the intranet / tailnet";
    # this has:
    # - service_name (i.e. loki, ntfy, etc.)
    # - host
    # - https (optional, defaults to false)
    # - port (optional, defaults to 443 if https, 80 otherwise)
    # - url (optional, defaults to "http(s)://host:port")
  };

  # Collect policy: each host sees all hosts' backends
  den.policies.fleet-http-services =
    { host, ... }:
    let
      inherit (den.lib.policy) pipe;
    in
    [
      (pipe.from "http-services" [
        (pipe.collect ({ host, ... }: true))
        (pipe.transform (
          # applies the default values for https, port, and url
          s:
          let
            https = s.https or false;
            port = s.port or (if https then 443 else 80);
            isDefaultPort = (https && port == 443) || (!https && port == 80);
            portOrEmpty = if isDefaultPort then "" else ":${toString port}";
            url = s.url or "http${if https then "s" else ""}://${s.host}${portOrEmpty}";
          in
          {
            inherit url port https;
            inherit (s)
              service_name
              host
              ;
          }
        ))
      ])
    ];

  den.schema.host.includes = [ den.policies.fleet-http-services ];

}
