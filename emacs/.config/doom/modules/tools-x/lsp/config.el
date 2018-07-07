;;; tools-x/lsp/config.el -*- lexical-binding: t; -*-

(def-package! lsp-mode
  :commands (lsp-mode lsp-define-stdio-client)
  :config (setq lsp-enable-completion-at-point t))

(def-package! lsp-ui
  :hook (lsp-mode . lsp-ui-mode)
  :config
  (set! :lookup 'lsp-ui-mode
    :definition #'lsp-ui-peek-find-definitions
    :references #'lsp-ui-peek-find-references)
  (setq lsp-ui-doc-enable nil
        lsp-ui-sideline-enable nil))

(def-package! company-lsp
  :after lsp-mode
  :config
  (set! :company-backend 'lsp-mode '(company-lsp :with))
  (setq company-sort-by-backend-importance '(company-sort-by-backend-importance)
        company-lsp-enable-recompletion t
        company-lsp-async t
        company-lsp-enable-snippet t))

(def-package! lsp-typescript
  :when (featurep! +javascript)
  :hook ((js-mode js2-mode rjsx-mode typescript-mode) . lsp-typescript-enable))

(def-package! lsp-python
  :when (featurep! +python)
  :hook (python-mode . lsp-python-enable)
  :config (lsp-define-stdio-client lsp-python "python" #'projectile-project-root '("pyls")))

(def-package! lsp-css
  :when (featurep! +web)
  :hook (css-mode . lsp-css-enable)
  :hook (less-mode . lsp-less-enable)
  :hook ((scss-mode sass-mode) . lsp-scss-enable))

