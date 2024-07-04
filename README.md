## aean's nix config and .dotfiles

### Overview:
This is my running NixOS config. It is a simple-scope, single-desktop config that gets the job done well. If you've found this project somehow and are considering using my config and don't want a barebones template, just want to get off the ground and don't mind a little bit of someone else's opinion in your OS, then this might be for you.

It was made to:
- Be simple
- Be readable
- Be organised
- Manage as many things declaratively as reasonably possible
- Integrate livability workarounds for Nvidia's trash drivers (fix Wayland, sleep, etc) 

It was not made to:
- Be maintained like an actual release
- Be super modular
- Run on more than one PC

### Highlights:

- Plasma 6 (install Qogir theme manually)
- Home Manager
- Plasma Manager
- Flatpaks
- Overlays
- Cron jobs
- Custom services
- Docker
- Plymouth
- Steam (and other gaming packages)
- File symlinking in home.nix

### To get this working:
- download and install NixOS from iso
- boot
- create your own repo from this by clicking "Use this template" on Github
- git clone your repo to ~/.dotfiles
- go through it and delete/comment things you don't need/want
- create secrets.nix in ~/.dotfiles/home in accordance with below template
- run ~/.dotfiles/home/bin/rebuild bash script
- commands "rebuild" and "cleanup" should be in bash $PATH now

secrets.nix template:
```
{
  username = "aean0x";
  hostName = "nix-pc";
  description = "Full Name";

  # Generate with "mkpasswd -m sha-512"
  hashedPassword = "";
}
```