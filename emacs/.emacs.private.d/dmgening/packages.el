;;; packages.el --- dmgening layer packages file for Spacemacs.
;;
;; Copyright (c) 2012-2017 Sylvain Benner & Contributors
;;
;; Author: Dmitry Gening <dgening@earthshaker.lan>
;; URL: https://github.com/syl20bnr/spacemacs
;;
;; This file is not part of GNU Emacs.
;;
;;; License: GPLv3

;;; Commentary:

;; See the Spacemacs documentation and FAQs for instructions on how to implement
;; a new layer:
;;
;;   SPC h SPC layers RET
;;
;;
;; Briefly, each package to be installed or configured by this layer should be
;; added to `dmgening-packages'. Then, for each package PACKAGE:
;;
;; - If PACKAGE is not referenced by any other Spacemacs layer, define a
;;   function `dmgening/init-PACKAGE' to load and initialize the package.

;; - Otherwise, PACKAGE is already referenced by another Spacemacs layer, so
;;   define the functions `dmgening/pre-init-PACKAGE' and/or
;;   `dmgening/post-init-PACKAGE' to customize the package as it is loaded.

;;; Code:


(defconst dmgening-packages
  '(all-the-icons
    vue-mode
    shrink-path
    (org-textile :location local)
    (doom-modeline :location local)))

(defun dmgening/init-org-textile()
  (spacemacs|use-package-add-hook org
    :post-config
    (require 'ox-textile)
    ))

(defun dmgening/init-all-the-icons ()
  (use-package all-the-icons
    :config (setq neo-theme 'icons)
    :defer t))

(defun dmgening/init-vue-mode ()
  (use-package vue-mode
    :config
    ;; 0, 1, or 2, representing (respectively) none, low, and high coloring
    (setq mmm-submode-decoration-level 0)))

(defun dmgening/init-doom-modeline ()
  (use-package doom-modeline
    :demand t
    :init
    (setq +doom-modeline-buffer-file-name-style 'relative-to-project
          +doom-modeline-height 26
          +doom-modeline-bar-width 3
          powerline-image-apple-rgb t)
    :config
    (+doom-modeline|init)))

;;; packages.el ends here
