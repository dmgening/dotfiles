;;; ~/Projects/dotfiles/emacs/.config/doom/+theme.el -*- lexical-binding: t; -*-

(defun *doom-themes-custom-set-faces ()
  (doom-themes-set-faces doom-theme
    (lsp-face-highlight-textual :underline (doom-color 'highlight) :foreground (doom-color 'highlight) :weight 'demibold)
    (lsp-face-highlight-read    :underline (doom-color 'highlight) :foreground (doom-color 'highlight) :weight 'demibold)
    (lsp-face-highlight-write   :underline (doom-color 'highlight) :foreground (doom-color 'highlight) :weight 'demibold)))

(setq doom-theme 'doom-nova)
(add-hook 'doom-load-theme-hook #'*doom-themes-custom-set-faces)
