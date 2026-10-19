{
  apps.email.homeManager =
    { config, pkgs, ... }:
    {
      sops.secrets."aerc/migadu/password" = { };

      # w3m's kitty image protocol shells out to ImageMagick's convert
      home.packages = [ pkgs.imagemagick ];

      programs.aerc = {
        enable = true;
        extraConfig = {
          general.unsafe-accounts-conf = true;
          ui = {
            fuzzy-complete = true;
            mouse-enabled = true;
            show-thread-context = true;
            threading-enabled = true;
            message-list-split = "vertical 100";
          };
          viewer = {
            html-inline-images = true;
          };
          # ponytail: fires for watched folders + check-mail polled ones, not every folder
          hooks.mail-received = "notify-send -a aerc \"[$AERC_ACCOUNT/$AERC_FOLDER] New mail from $AERC_FROM_NAME\" \"$AERC_SUBJECT\"";
          filters = {
            ".headers" = "colorize";
            "message/delivery-status" = "colorize";
            "message/rfc822" = "colorize";
            "text/calendar" = "calendar";
            "text/html" = "! html -o inline_img_protocol=kitty -o display_link_number=true";
            "text/plain" = "colorize";
          };
        };
        # home-manager's binds.conf replaces aerc's shipped one wholesale (no merge),
        # so the defaults live here; arrows added for navigation.
        extraBinds = {
          global = {
            "<C-p>" = ":prev-tab<Enter>";
            "<C-n>" = ":next-tab<Enter>";
            "?" = ":help keys<Enter>";
            "<C-c>" = ":prompt 'Quit?' quit<Enter>";
            "<C-q>" = ":prompt 'Quit?' quit<Enter>";
          };
          messages = {
            "<Enter>" = ":view<Enter>";
            "<Up>" = ":prev<Enter>";
            "<Down>" = ":next<Enter>";
            "<Left>" = ":prev-folder<Enter>";
            "<Right>" = ":next-folder<Enter>";
            "<C-Up>" = ":prev-folder<Enter>";
            "<C-Down>" = ":next-folder<Enter>";
            "<C-Left>" = ":collapse-folder<Enter>";
            "<C-Right>" = ":expand-folder<Enter>";
            "<Home>" = ":select 0<Enter>";
            "<End>" = ":select -1<Enter>";
            "<PgUp>" = ":prev 100%<Enter>";
            "<PgDn>" = ":next 100%<Enter>";
            "<C-u>" = ":prev 50%<Enter>";
            "<C-d>" = ":next 50%<Enter>";
            "<Space>" = ":mark -t<Enter>:next<Enter>";
            "<Esc>" = ":clear<Enter>";
            j = ":next<Enter>";
            k = ":prev<Enter>";
            g = ":select 0<Enter>";
            G = ":select -1<Enter>";
            J = ":next-folder<Enter>";
            K = ":prev-folder<Enter>";
            H = ":collapse-folder<Enter>";
            L = ":expand-folder<Enter>";
            T = ":toggle-threads<Enter>";
            "<tab>" = ":fold -t<Enter>";
            q = ":prompt 'Quit?' quit<Enter>";
            d = ":choose -o y 'Really delete this message' delete-message<Enter>";
            D = ":delete<Enter>";
            a = ":archive flat<Enter>";
            A = ":unmark -a<Enter>:mark -T<Enter>:archive flat<Enter>";
            C = ":compose<Enter>";
            m = ":compose<Enter>";
            rr = ":reply -a<Enter>";
            rq = ":reply -aq<Enter>";
            Rr = ":reply<Enter>";
            Rq = ":reply -q<Enter>";
            c = ":cf<space>";
            "$" = ":term<space>";
            "!" = ":term<space>";
            "|" = ":pipe<space>";
            "/" = ":search<space>";
            "\\" = ":filter<space>";
            n = ":next-result<Enter>";
            N = ":prev-result<Enter>";
            s = ":split<Enter>";
            S = ":vsplit<Enter>";
          };
          "messages:folder=Drafts" = {
            "<Enter>" = ":recall<Enter>";
          };
          view = {
            "/" = ":toggle-key-passthrough<Enter>/";
            "<Left>" = ":prev<Enter>";
            "<Right>" = ":next<Enter>";
            "<C-Left>" = ":prev<Enter>";
            "<C-Right>" = ":next<Enter>";
            "<C-Up>" = ":prev-part<Enter>";
            "<C-Down>" = ":next-part<Enter>";
            "<C-l>" = ":open-link <space>";
            q = ":close<Enter>";
            o = ":open<Enter>";
            O = ":open<Enter>";
            S = ":save<space>";
            "|" = ":pipe<space>";
            D = ":delete<Enter>";
            A = ":archive flat<Enter>";
            f = ":forward<Enter>";
            rr = ":reply -a<Enter>";
            rq = ":reply -aq<Enter>";
            Rr = ":reply<Enter>";
            Rq = ":reply -q<Enter>";
            H = ":toggle-headers<Enter>";
          };
          compose = {
            "$noinherit" = true;
            "$ex" = "<C-x>";
            "$complete" = "<C-o>";
            "<C-Up>" = ":prev-field<Enter>";
            "<C-Down>" = ":next-field<Enter>";
            "<tab>" = ":next-field<Enter>";
            "<backtab>" = ":prev-field<Enter>";
            "<C-p>" = ":prev-tab<Enter>";
            "<C-n>" = ":next-tab<Enter>";
          };
          "compose::editor" = {
            "$noinherit" = true;
            "$ex" = "<C-x>";
            "<C-Up>" = ":prev-field<Enter>";
            "<C-Down>" = ":next-field<Enter>";
            "<C-p>" = ":prev-tab<Enter>";
            "<C-n>" = ":next-tab<Enter>";
          };
          "compose::review" = {
            y = ":send<Enter>";
            n = ":abort<Enter>";
            s = ":sign<Enter>";
            x = ":encrypt<Enter>";
            v = ":preview<Enter>";
            p = ":postpone<Enter>";
            q = ":choose -o d discard abort -o p postpone postpone<Enter>";
            e = ":edit<Enter>";
            a = ":attach<space>";
            d = ":detach<space>";
          };
          terminal = {
            "$noinherit" = true;
            "$ex" = "<C-x>";
            "<C-p>" = ":prev-tab<Enter>";
            "<C-n>" = ":next-tab<Enter>";
          };
        };
      };

      programs.thunderbird = {
        enable = true;
        profiles.default = {
          isDefault = true;
        };
      };

      accounts.email.accounts = {
        "emilia@byte-sized.fyi" = {
          enable = true;
          primary = true;
          realName = "Emilia Jaser";
          address = "emilia@byte-sized.fyi";
          userName = "admin@byte-sized.fyi";
          flavor = "migadu.com";
          aliases = [
            "admin@byte-sized.fyi"
          ];
          passwordCommand = [
            "cat"
            config.sops.secrets."aerc/migadu/password".path
          ];
          aerc = {
            enable = true;
            extraAccounts.check-mail = "5m";
          };
          thunderbird.enable = true;
        };
        "emilia.jaser@hm.edu" = {
          enable = true;
          realName = "Emilia Jaser";
          address = "emilia.jaser@hm.edu";
          flavor = "outlook.office365.com-ews";
          thunderbird.enable = true;
        };
        "ejaser@fs.cs.hm.edu" = {
          enable = true;
          realName = "Emilia Jaser";
          address = "ejaser@fs.cs.hm.edu";
          userName = "ejaser@fs.cs.hm.edu";
          thunderbird.enable = true;
          smtp = {
            host = "mail.fs.cs.hm.edu";
            port = 587;
            tls.useStartTls = true;
          };
          imap = {
            host = "mail.fs.cs.hm.edu";
            port = 993;
          };
          signature = {
            htmlFormat = true;
            showSignature = "append";
            text = ''
              <p>&nbsp;</p>
              <div id="_rc_sig">
              <div class="moz-signature" style="color: #000000;"><span style="font-family: Arial;"><strong><span style="color: #e03e2d;">Emilia Jaser</span></strong></span>
              <div class="moz-signature">
              <div class="pre"><span style="font-family: Arial;"><span style="color: #7e8c8d;">Leitung Home-Sektor</span></span></div>
              <div class="pre">&nbsp;</div>
              <div class="pre"><span style="color: #7e8c8d; font-size: 12pt; font-family: arial, helvetica, sans-serif;"><img src="https://fs.cs.hm.edu/wp-content/uploads/2024/03/fs-logo-256.png" width="98" height="120" align="left" hspace="24" /></span><span style="color: #7e8c8d; font-size: 12pt; font-family: arial, helvetica, sans-serif;"></span>
              <div class="pre">
              <div class="pre"><span style="font-family: Arial;"><span style="color: #e03e2d;">Fachschaft 07 (Informatik &amp; Mathematik)</span></span></div>
              <span style="font-family: Arial;"><span style="color: #7e8c8d;">Hochschule M&uuml;nchen - University of Applied Sciences</span></span></div>
              <div class="pre"><span style="font-family: Arial;"><span style="color: #7e8c8d;">E-Mail: <a class="moz-txt-link-freetext" style="color: #7e8c8d;" href="mailto:ejaser@fs.cs.hm.edu" rel="noopener">ejaser@fs.cs.hm.edu</a></span></span></div>
              <div class="pre"><span style="font-family: Arial;"><span style="color: #7e8c8d;">Webseite: <a style="color: #7e8c8d;" href="https://fs.cs.hm.edu/" rel="noopener">fs.cs.hm.edu</a></span></span></div>
              <div class="pre"><span style="font-family: Arial;"><span style="color: #7e8c8d;">Adresse: <a style="color: #7e8c8d;" href="https://www.google.com/maps/place/Lothstra%C3%9Fe+64,+80335+M%C3%BCnchen/@48.1551295,11.5532432">Lothstr. 64, 80335 M&uuml;nchen</a></span></span></div>
              <div class="pre"><span style="font-family: Arial;"><span style="color: #7e8c8d;">Raum: R0.013</span></span></div>
              </div>
              </div>
              </div>
              </div>
              </div>
            '';
          };
        };
      };

      accounts.calendar.accounts = {
        "emilia@byte-sized.fyi" = {
          remote = {
            type = "caldav";
            url = "https://cdav.migadu.com/calendars/admin@byte-sized.fyi/calendar/";
            userName = "admin@byte-sized.fyi";
          };
          primary = true;
          thunderbird = {
            enable = true;
            settings = id: {
              "calendar.registry.${id}.refreshInterval" = 5;
              "calendar.registry.${id}.imip.identity.key" =
                "id_${builtins.hashString "sha256" "emilia@byte-sized.fyi"}";
            };
          };
        };
        "zpa" = {
          remote = {
            type = "http";
            url = "https://zpa.cs.hm.edu/global/ics_feed/rss/ba6e7a4d-06b5-48a9-b7c6-c49c5fec9138/";
          };
          thunderbird = {
            enable = true;
            readOnly = true;
          };
        };
        "fs07" = {
          remote = {
            type = "http";
            url = "https://nc.fs.cs.hm.edu/remote.php/dav/public-calendars/DHmpqy3nGYDjBQW7/";
          };
          thunderbird = {
            enable = true;
            readOnly = true;
          };
        };
      };
    };
}
