{
  # Public example: copy to home/secrets.nix and customize
  username = "user";
  hostName = "my-host";
  description = "User";
  userHome = "/home/user";

  # Either provide a hashedPassword (mkpasswd -m sha-512), or leave unset and
  # the system will fall back to initialPassword = "changeme" at first login.
  # hashedPassword = "$6$REPLACE_ME";

  omarchy = {
    full_name = "Unknown";
    email_address = "unknown@example.com";
    theme = "tokyo-night";
  };
}
