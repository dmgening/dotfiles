;;; ~/Projects/dotfiles/emacs/.config/doom/+posframe.el -*- lexical-binding: t; -*-

(after! flycheck-posframe
  (defun *posframe|flycheck-posframe-show-posframe (errors)
    "Display ERRORS, using posframe.el library."
    (flycheck-posframe-hide-posframe)
    (when (and errors (eq evil-state 'normal))
      (posframe-show
       flycheck-posframe-buffer
       :string (flycheck-posframe-format-errors errors)
       :background-color (face-background 'flycheck-posframe-background-face nil t)
       :override-parameters '((internal-border-width . 10))
       :timeout 5
       :position (point))
      (dolist (hook flycheck-posframe-hide-posframe-hooks)
        (add-hook hook #'flycheck-posframe-hide-posframe nil t))))

  (advice-add 'flycheck-posframe-show-posframe :override #'*posframe|flycheck-posframe-show-posframe))
