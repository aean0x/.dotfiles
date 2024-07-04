## aean's NixOS Configuration and Dotfiles

### Overview
Welcome to my NixOS configuration repository! This setup is tailored for a single-desktop environment, focusing on simplicity, readability, and organization. If you're looking for a straightforward way to get started with NixOS, and you don't mind a few personal preferences baked in, this config might be for you.

### Objectives
#### Made to:
- Be simple
- Be readable
- Be organized
- Manage as many things declaratively as reasonably possible
- Integrate livability workarounds for Nvidia's drivers (fix Wayland, sleep, etc)

#### Not made to:
- Be maintained like an actual release
- Be super modular
- Run on more than one PC

### Highlights
- **Plasma 6** (Note: Install Qogir theme manually)
- **Home Manager** integration
- **Plasma Manager** for Plasma-specific configurations
- **Flatpaks** for additional software
- **Overlays** for custom package sets
- **Cron jobs** for automated tasks
- **Custom services** defined with systemd
- **Docker** for containerized applications
- **Plymouth** for a pretty boot screen
- **Steam** and other gaming packages
- **File symlinking** in `home.nix` for declarative dotfile management

### Getting Started
Follow these steps to get this configuration up and running on your NixOS system:

1. **Install NixOS**: Download and install NixOS from the official ISO.
2. **Boot into NixOS**: Start your system with NixOS.
3. **Clone the Repository**:
    ```sh
    git clone <your-repo-url> ~/.dotfiles
    ```
4. **Customize**: Go through the repository and delete or comment out things you don't need or want.
5. **Create `secrets.nix`**: In `~/.dotfiles/home`, create `secrets.nix` based on the template below.
6. **Rebuild**: Run the rebuild script to apply configurations.
    ```sh
    ~/.dotfiles/home/bin/rebuild
    ```
7. **Access Commands**: The commands `rebuild` and `cleanup` should now be in your bash `$PATH`.

#### `secrets.nix` Template
Create `~/.dotfiles/home/secrets.nix`:
```nix
{
  username = "aean0x";
  hostName = "nix-pc";
  description = "Full Name";

  # Generate with "mkpasswd -m sha-512"
  hashedPassword = "";
}
```