;;------------------------------------------------------------------------------
;; This file should go in ~/.config/guix/system.scm
;;
;; Run `guix system reconfigure ~/.config/guix/system.scm' after updating it.
;;------------------------------------------------------------------------------

;; Indicate which modules to import to access the variables
;; used in this configuration.
(use-modules (gnu)
             (gnu system privilege)
             (gnu packages nfs)
             (gnu packages cups)
             (gnu services base)
             (gnu services pm)
             (gnu services networking)
             (gnu services ssh)
             (gnu services cups)
             (gnu services sound)
             (gnu services xorg)
             (gnu services desktop)
             (gnu packages linux)
             (nongnu packages linux))

(operating-system
 (kernel linux)
 (firmware (list linux-firmware))
 (locale "en_US.utf8")
 (timezone "XXX")
 (keyboard-layout (keyboard-layout "XXX"))
 (host-name "XXX")

 ;; The list of user accounts ('root' is implicit).
 (users (cons* (user-account
                (name "username")
                (comment "username")
                (group "users")
                (home-directory "/home/username")
                (supplementary-groups '("wheel" "netdev" "audio" "video")))
               %base-user-accounts))

 ;; Packages installed system-wide.  Users can also install packages
 ;; under their own account: use 'guix search KEYWORD' to search
 ;; for packages and 'guix install PACKAGE' to install a package.
 (packages (append (list (specification->package "neovim")
                         (specification->package "bash-completion")
                         (specification->package "git")
                         (specification->package "curl")
                         (specification->package "gcc-toolchain")
                         (specification->package "make")
                         (specification->package "gdb")
                         (specification->package "xxd")
                         (specification->package "htop"))
                   %base-packages))

 ;; Below is the list of system services.  To search for available
 ;; services, run 'guix system search KEYWORD' in a terminal.
 (services
  (cons*
   ;; Network Time Protocol, for time and date
   (service ntp-service-type)

   ;; Power management
   (service upower-service-type)

   ;; Login
   (service login-service-type)

   ;; Port of systemd's logind. TODO: Needed?
   (service elogind-service-type)

   ;; Allow desktop users to also mount NTFS and NFS file systems without root.
   ;; NOTE: Extracted from "gnu/services/desktop.scm" @ 8a7bd211d2.
   (simple-service 'mount-setuid-helpers privileged-program-service-type
                   (map file-like->setuid-program
                        (list (file-append nfs-utils "/sbin/mount.nfs")
                              (file-append ntfs-3g "/sbin/mount.ntfs-3g"))))

   ;; OpenSSH server
   (service openssh-service-type)

   ;; Printing
   (service cups-service-type
	        (cups-configuration
	         (web-interface? #t)
	         (extensions (list cups-filters hplip-minimal))))

   ;; Connman for WiFi. We could use '(iwd) in `shepherd-requirement', but there
   ;; is currently no service that provides it.
   (service wpa-supplicant-service-type)
   (service connman-service-type
            (connman-configuration
             (shepherd-requirement '(wpa-supplicant))))

   ;; Audio
   (service alsa-service-type
            (alsa-configuration
             (pulseaudio? #t)))

   ;; Configuration for Xorg
   (set-xorg-configuration
    (xorg-configuration
     (keyboard-layout keyboard-layout)))

   ;; Base services. Note how we are using `cons*'
   %base-services))

 (bootloader (bootloader-configuration
              (bootloader grub-efi-bootloader)
              (targets (list "/boot/efi"))
              (keyboard-layout keyboard-layout)))

 (swap-devices (list (swap-space
                      (target (uuid
                               "XXX")))))

 (mapped-devices (list (mapped-device
                        (source (uuid
                                 "XXX"))
                        (target "guix")
                        (type luks-device-mapping))))

 ;; The list of file systems that get "mounted".  The unique
 ;; file system identifiers there ("UUIDs") can be obtained
 ;; by running 'blkid' in a terminal.
 (file-systems (cons* (file-system
                       (mount-point "/")
                       (device "/dev/mapper/guix")
                       (type "ext4")
                       (dependencies mapped-devices))
                      (file-system
                       (mount-point "/boot/efi")
                       (device (uuid "XXX"
                                     'fat32))
                       (type "vfat")) %base-file-systems)))
