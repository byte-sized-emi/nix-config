{ inputs, ... }:
{
  imports = [ inputs.secret-nix-config.homeManagerModules.email ];
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
      thunderbird.enable = true;
    };
    "emilia.jaser@hm.edu" = {
      enable = true;
      primary = false;
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
        # htmlFormat = true;
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
}
