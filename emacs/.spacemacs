;; -*- mode: emacs-lisp -*-
;; This file is loaded by Spacemacs at startup.
;; It must be stored in your home directory.

(defun dotspacemacs/layers ()
  (setq-default
   dotspacemacs-distribution 'spacemacs-base
   dotspacemacs-enable-lazy-installation 'unused
   dotspacemacs-ask-for-lazy-installation t
   dotspacemacs-configuration-layer-path '()
   dotspacemacs-configuration-layers
   '(
     ;; lang
     emacs-lisp
     markdown
     org
     ;; spacemacs-base+
     spacemacs-completion
     spacemacs-layouts
     spacemacs-editing
     spacemacs-editing-visual
     spacemacs-evil
     ;; Completion
     ivy
     auto-completion
     spell-checking
     syntax-checking
     ;; source control
     version-control
     git
     )
   dotspacemacs-additional-packages '()
   dotspacemacs-frozen-packages '()
   dotspacemacs-excluded-packages
   '(
     evil-unimpaired
     )
   dotspacemacs-install-packages 'used-only))

(defun dotspacemacs/init ()
  (setq-default
   ;; Packages and updates
   dotspacemacs-elpa-https t
   dotspacemacs-elpa-timeout 5

   ;; Startup
   dotspacemacs-verbose-loading nil
   dotspacemacs-startup-banner nil
   dotspacemacs-auto-resume-layouts t
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
   dotspacemacs-default-font '("Monaco"
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
   dotspacemacs-default-layout-name "dump"
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
  )

(defun dotspacemacs/user-config ()
  (setq doom-themes-enable-bold t
        doom-themes-enable-italic t))

;; Do not write anything past this comment. This is where Emacs will
;; auto-generate custom variable definitions.
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   (quote
    (one-dark-theme smeargle orgit org-projectile org-category-capture org-present org-plus-contrib org-pomodoro alert log4e gntp org-download mmm-mode markdown-toc s markdown-mode magit-gitflow htmlize gnuplot gitignore-mode gitconfig-mode gitattributes-mode git-timemachine git-messenger git-link gh-md evil-magit magit magit-popup adaptive-wrap git-gutter-fringe+ git-gutter-fringe fringe-helper git-gutter+ git-commit with-editor git-gutter flyspell-correct-ivy flyspell-correct flycheck-pos-tip pos-tip flycheck diff-hl auto-dictionary ws-butler volatile-highlights vi-tilde-fringe uuidgen rainbow-delimiters persp-mode move-text lorem-ipsum linum-relative link-hint indent-guide hungry-delete highlight-parentheses highlight-numbers parent-mode highlight-indentation hide-comnt fuzzy eyebrowse expand-region evil-visual-mark-mode evil-tutor evil-surround evil-search-highlight-persist evil-numbers evil-nerd-commenter evil-mc evil-matchit evil-lisp-state smartparens dash evil-indent-plus evil-iedit-state iedit evil-exchange evil-ediff evil-args evil-anzu anzu eval-sexp-fu highlight company-statistics company column-enforce-mode clean-aindent-mode auto-yasnippet yasnippet auto-highlight-symbol aggressive-indent ac-ispell auto-complete which-key wgrep use-package smex pcre2el macrostep ivy-hydra hydra help-fns+ helm-make helm helm-core popup flx exec-path-from-shell evil-visualstar evil-escape evil goto-chg undo-tree elisp-slime-nav diminish counsel-projectile projectile pkg-info epl counsel swiper ivy bind-map bind-key auto-compile packed async ace-window avy))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
