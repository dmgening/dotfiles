;; -*- no-byte-compile: t; -*-
;;; tools-x/lsp/packages.el

(package! lsp-mode)
(package! lsp-ui)
(package! company-lsp)

(when (featurep! +javascript)
  (package! lsp-typescript :recipe (:fetcher
                                    github
                                    :repo "emacs-lsp/lsp-javascript"
                                    :files ("lsp-typescript.el")))
  (package! tide :disable t))

(when (featurep! +web)
  (package! lsp-css :recipe (:fetcher
                             github
                             :repo "emacs-lsp/lsp-css")))

(when (featurep! +python)
  (package! lsp-python))

