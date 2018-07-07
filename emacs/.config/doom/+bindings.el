;;; ~/Projects/dotfiles/emacs/.config/doom/+bindings.el -*- lexical-binding: t; -*-


(map!
 (:after evil
   (:map evil-window-map
     "<left>" #'evil-window-left
     "<down>" #'evil-window-down
     "<up>" #'evil-window-up
     "<right>" #'evil-window-right))
 :leader
 (:desc "open" :prefix "0"
   :desc "Imenu sidebar"         :nv "i" #'lsp-ui-imenu
   :desc "Terminal"              :n  "T" #'+term/open
   :desc "Terminal in popup"     :n  "t" #'+term/open-popup-in-project
   :desc "Eshell"                :n  "E" #'+eshell/open
   :desc "Eshell in popup"       :n  "e" #'+eshell/open-popup))

