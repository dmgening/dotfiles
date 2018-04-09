;; -*- mode: emacs-lisp -*-
;; This file is loaded by Spacemacs at startup.
;; It must be stored in your home directory.

(defun dotspacemacs/layers ()
  (setq-default
   dotspacemacs-distribution 'spacemacs
   dotspacemacs-enable-lazy-installation 'unused
   dotspacemacs-ask-for-lazy-installation t
   dotspacemacs-configuration-layer-path '("~/.emacs.private.d")
   dotspacemacs-configuration-layers
   '(;; lang
     html
     javascript
     react
     lua
     python
     emacs-lisp
     yaml
     markdown
     org
     ;; UI
     (shell :variables
            shell-default-shell 'multi-term
            shell-default-height 50
            shell-default-term-shell "/bin/zsh"
            shell-default-full-span nil)
     (helm :variables helm-enable-auto-resize t)
     theming
     auto-completion
     spell-checking
     syntax-checking
     version-control
     git
     ;; private layers
     dmgening)
   dotspacemacs-additional-packages '()
   dotspacemacs-frozen-packages '()
   dotspacemacs-excluded-packages '(evil-unimpaired spaceline)
   dotspacemacs-install-packages 'used-only))

(defun dotspacemacs/init ()
  (setq-default
   ;; Packages and updates
   dotspacemacs-elpa-https t
   dotspacemacs-elpa-timeout 5

   ;; Startup
   dotspacemacs-verbose-loading nil
   dotspacemacs-startup-banner nil
   ;; dotspacemacs-auto-resume-layouts t
   dotspacemacs-loading-progress-bar nil
   dotspacemacs-startup-buffer-responsive t
   dotspacemacs-startup-lists '((recents . 3)
                                (projects . 3)
                                (agenda . 3))

   ;; Controls
   dotspacemacs-editing-style 'hybrid
   dotspacemacs-leader-key "SPC"
   dotspacemacs-emacs-command-key "SPC"
   dotspacemacs-ex-command-key ":"
   dotspacemacs-major-mode-leader-key ","

   dotspacemacs-emacs-leader-key "M-m"
   dotspacemacs-major-mode-emacs-leader-key "C-M-m"

   ;; Looks
   dotspacemacs-themes '(doom-one)
   dotspacemacs-mode-line-theme 'vanilla
   dotspacemacs-default-font '("Menlo"
                               :size 12
                               :weight normal
                               :width normal
                               :powerline-scale 1.1)
   dotspacemacs-colorize-cursor-according-to-state t
   dotspacemacs-line-numbers
   '(:relative nil
               :disabled-for-modes dired-mode
               doc-view-mode
               markdown-mode
               org-mode
               pdf-view-mode
               text-mode
               :size-limit-kb 1000)
   dotspacemacs-which-key-delay 0.4
   dotspacemacs-which-key-position 'bottom

   ;; miscellaneous
   dotspacemacs-scratch-mode 'text-mode
   dotspacemacs-default-layout-name "misc"
   dotspacemacs-retain-visual-state-on-shift t
   dotspacemacs-ex-substitute-global t
   dotspacemacs-display-default-layout t
   dotspacemacs-large-file-size 1
   dotspacemacs-auto-save-file-location 'cache
   dotspacemacs-max-rollback-slots 5
   dotspacemacs-enable-paste-transient-state t
   dotspacemacs-whitespace-cleanup 'trailing
   dotspacemacs-search-tools '("ag" "pt" "ack" "grep")
   ))

(defun dotspacemacs/user-init ()
  (setq exec-path-from-shell-arguments '("-l")))

(defun dotspacemacs/user-config ()
  (setq doom-themes-enable-bold t
        doom-themes-enable-italic t
        split-width-threshold nil
        js2-mode-show-parse-errors nil
        js2-mode-show-strict-warnings nil))
