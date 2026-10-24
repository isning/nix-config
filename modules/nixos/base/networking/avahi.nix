{
  # Network discovery on a local network, mDNS
  # With this enabled, you can access your machine at <hostname>.local
  # it's more convenient than using the IP address.
  # https://avahi.org/
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    # Sunshine still defaults these legacy options to true; use settings below instead.
    publish.enable = null;
    publish.userServices = null;
    settings.publish = {
      disable-publishing = false;
      publish-domain = true;
      disable-user-service-publishing = false;
      publish-addresses = true;
    };
  };
}
