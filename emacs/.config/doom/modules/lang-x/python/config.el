(def-package! pipenv
  :after python
  :init
  (add-hook 'python-mode-hook 'pipenv-mode)
  (setq
   pipenv-projectile-after-switch-function #'pipenv-projectile-after-switch-extended)
  :config
  ;; (setq pipenv-executable "/anaconda3/bin/pipenv")
  (map! :map python-mode-map
        :localleader
        :n "a" #'pipenv-activate
        :n "d" #'pipenv-deactivate
        )
)
