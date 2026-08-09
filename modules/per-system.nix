{ lib, inputs, ... }:
let
  description = ''
    Provides `perSystem'` (the flake's `inputs` and `self` with system pre-selected)
    as a top-level module argument.

    This allows modules to access per-system flake outputs without needing
    `pkgs.stdenv.hostPlatform.system`.

    ## Usage

    **Global (Recommended):**
    Apply to all hosts, users, and homes.

        den.default.includes = [ den.aspects.per-system ];

    **Specific:**
    Apply only to a specific host, user, or home aspect.

        den.aspects.my-laptop.includes = [ den.aspects.per-system ];
        den.aspects.alice.includes = [ den.aspects.per-system ];

    **Note:** This aspect is contextual. When included in a `host` aspect, it
    configures `perSystem` for the host's OS. When included in a `user` or `home`
    aspect, it configures `perSystem` for the corresponding Home Manager configuration.
  '';

  mkAspect = class: system: {
    ${class}._module.args.perSystem = lib.mapAttrs (
      name: input: (input.packages.${system} or input.legacyPackages.${system} or { })
    ) inputs;
  };

  osAspect =
    { host }:
    {
      name = "per-system/os";
    }
    # Guard a synthetic host identity (classless `user@host` home) the same way
    # homeAspect already guards `home ? class`.
    // lib.optionalAttrs (host ? class) (mkAspect host.class host.system);

  userAspect =
    {
      user,
      host,
    }:
    {
      name = "per-system/user";
      includes = map (c: mkAspect c host.system) user.classes;
    };

  homeAspect =
    { home }:
    {
      name = "per-systtem/home";
    }
    // lib.optionalAttrs (home ? class) (mkAspect home.class home.system);
in
{
  den.aspects.per-system = {
    name = "per-system";
    inherit description;
    includes = [
      osAspect
      userAspect
      homeAspect
    ];
  };
}
