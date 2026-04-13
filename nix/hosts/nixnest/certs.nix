{
  environment.etc = {
    # generated using:
    # openssl ecparam -name prime256v1 -genkey -noout -out private-key.pem
    #
    # openssl ec -in private-key.pem -pubout -out public-key.pem
    #
    # openssl req -new -x509 -key private-key.pem -out cert.pem -days 3650 -subj "/CN=byte-sized.fyi" -addext "subjectAltName=DNS:byte-sized.fyi,DNS:*.byte-sized.fyi"
    #
    "certs/self_signed.pem".text = ''
      -----BEGIN CERTIFICATE-----
      MIIBtTCCAVugAwIBAgIUYbFuiI5AbSLA120TH7YHD7SLPdYwCgYIKoZIzj0EAwIw
      GTEXMBUGA1UEAwwOYnl0ZS1zaXplZC5meWkwHhcNMjYwNDEzMjExMTU0WhcNMzYw
      NDEwMjExMTU0WjAZMRcwFQYDVQQDDA5ieXRlLXNpemVkLmZ5aTBZMBMGByqGSM49
      AgEGCCqGSM49AwEHA0IABBJBKZV1lazVWYGIpiVE+Ax0czxfM86/zG1QBukuQNH5
      OS6+Oeb/7GIIkeZP2BZzF2gDlVaYsr0cVXslMnDU0RmjgYAwfjAdBgNVHQ4EFgQU
      uaEsTfzoJ/IpECZu/tQl+Pqs8wcwHwYDVR0jBBgwFoAUuaEsTfzoJ/IpECZu/tQl
      +Pqs8wcwDwYDVR0TAQH/BAUwAwEB/zArBgNVHREEJDAigg5ieXRlLXNpemVkLmZ5
      aYIQKi5ieXRlLXNpemVkLmZ5aTAKBggqhkjOPQQDAgNIADBFAiEA7sBaerEWrhHl
      64SlWJALl9QBTqUglb1oHBec6CdjUO0CIC1IZ9R08cCE/UGaH0Juj3UhMLVe3yLp
      +ngcHuRYtS+f
      -----END CERTIFICATE-----
    '';
    "certs/wildcard_origin_cert.pem".text = ''
      -----BEGIN CERTIFICATE-----
      MIIDJzCCAs6gAwIBAgIUL915GBgZS0pFH1K9Aprw4qJMn6UwCgYIKoZIzj0EAwIw
      gY8xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpDYWxpZm9ybmlhMRYwFAYDVQQHEw1T
      YW4gRnJhbmNpc2NvMRkwFwYDVQQKExBDbG91ZEZsYXJlLCBJbmMuMTgwNgYDVQQL
      Ey9DbG91ZEZsYXJlIE9yaWdpbiBTU0wgRUNDIENlcnRpZmljYXRlIEF1dGhvcml0
      eTAeFw0yNjA0MTMwOTE1MDBaFw00MTA0MDkwOTE1MDBaMGIxGTAXBgNVBAoTEENs
      b3VkRmxhcmUsIEluYy4xHTAbBgNVBAsTFENsb3VkRmxhcmUgT3JpZ2luIENBMSYw
      JAYDVQQDEx1DbG91ZEZsYXJlIE9yaWdpbiBDZXJ0aWZpY2F0ZTBZMBMGByqGSM49
      AgEGCCqGSM49AwEHA0IABBv7n1bLBGtNCG7Q+n8fFbbdvhu2tdwoMqLyj7ikk9ZZ
      TtLOsVsJks6S2SzzmQUo48Eazd3oM14COaEFTTcAfiSjggEyMIIBLjAOBgNVHQ8B
      Af8EBAMCBaAwHQYDVR0lBBYwFAYIKwYBBQUHAwIGCCsGAQUFBwMBMAwGA1UdEwEB
      /wQCMAAwHQYDVR0OBBYEFBYv84wFifDoNlqi1wditDn2cyxPMB8GA1UdIwQYMBaA
      FIUwXTsqcNTt1ZJnB/3rObQaDjinMEQGCCsGAQUFBwEBBDgwNjA0BggrBgEFBQcw
      AYYoaHR0cDovL29jc3AuY2xvdWRmbGFyZS5jb20vb3JpZ2luX2VjY19jYTArBgNV
      HREEJDAighAqLmJ5dGUtc2l6ZWQuZnlpgg5ieXRlLXNpemVkLmZ5aTA8BgNVHR8E
      NTAzMDGgL6AthitodHRwOi8vY3JsLmNsb3VkZmxhcmUuY29tL29yaWdpbl9lY2Nf
      Y2EuY3JsMAoGCCqGSM49BAMCA0cAMEQCIBUENOuSNv2DkU4GM9Gh6KcvkOmXhj0A
      jPeRXDy0iFBUAiAF55Bnmw+p8+VZUl0dJol9qernVpcR7g5vQ2zHNO/d/A==
      -----END CERTIFICATE-----
    '';
    "certs/links_byte_sized_fyi_origin_cert.pem".text = ''
      -----BEGIN CERTIFICATE-----
      MIIDLTCCAtKgAwIBAgIUc8zGQifPlR1ZclYkd5MzOkERaMEwCgYIKoZIzj0EAwIw
      gY8xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpDYWxpZm9ybmlhMRYwFAYDVQQHEw1T
      YW4gRnJhbmNpc2NvMRkwFwYDVQQKExBDbG91ZEZsYXJlLCBJbmMuMTgwNgYDVQQL
      Ey9DbG91ZEZsYXJlIE9yaWdpbiBTU0wgRUNDIENlcnRpZmljYXRlIEF1dGhvcml0
      eTAeFw0yNjAyMjAxNDUxMDBaFw00MTAyMTYxNDUxMDBaMGIxGTAXBgNVBAoTEENs
      b3VkRmxhcmUsIEluYy4xHTAbBgNVBAsTFENsb3VkRmxhcmUgT3JpZ2luIENBMSYw
      JAYDVQQDEx1DbG91ZEZsYXJlIE9yaWdpbiBDZXJ0aWZpY2F0ZTBZMBMGByqGSM49
      AgEGCCqGSM49AwEHA0IABPgvNqn781jlLzyroCLNvxL7d15Ed1W5KE36nCJcp/8R
      k6LpJtYSnI8Do2s0DSkunnf1WoEHuqQsbhR6cpApoA2jggE2MIIBMjAOBgNVHQ8B
      Af8EBAMCBaAwHQYDVR0lBBYwFAYIKwYBBQUHAwIGCCsGAQUFBwMBMAwGA1UdEwEB
      /wQCMAAwHQYDVR0OBBYEFEn2xV4Zi1nojY8QQ1nypjecvKGdMB8GA1UdIwQYMBaA
      FIUwXTsqcNTt1ZJnB/3rObQaDjinMEQGCCsGAQUFBwEBBDgwNjA0BggrBgEFBQcw
      AYYoaHR0cDovL29jc3AuY2xvdWRmbGFyZS5jb20vb3JpZ2luX2VjY19jYTAvBgNV
      HREEKDAmgg5ieXRlLXNpemVkLmZ5aYIUbGlua3MuYnl0ZS1zaXplZC5meWkwPAYD
      VR0fBDUwMzAxoC+gLYYraHR0cDovL2NybC5jbG91ZGZsYXJlLmNvbS9vcmlnaW5f
      ZWNjX2NhLmNybDAKBggqhkjOPQQDAgNJADBGAiEAlnleoj/Yqkw7HH+Ybq1mJ0IN
      sJXxlW14szH+xolycQwCIQCOKYZrwPd+ECxCd22Oo8dsi0oFmfrOzySU/gTvGBG2
      9Q==
      -----END CERTIFICATE-----
    '';
  };
}
