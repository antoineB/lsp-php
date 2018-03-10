;;; lsp-php.el --- PHP support for lsp-mode -*- lexical-binding: t -*-

;; Copyright (C) 2017-2018 zg, Declspeck

;; Author: Declspeck <declspeck@declblog.com>
;;         zg <13853850881@163.com>
;; Maintainer: Declspeck <declspeck@declblog.com>
;; Version: 1.0
;; Package-Requires: ((emacs "25.1") (lsp-mode "3.4"))
;; URL: https://github.com/emacs-lsp/lsp-php

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Adds PHP support to lsp-mode with php-language-server (felixfbecker/language-server )

;;; Code:

(require 'lsp-mode)

(defgroup lsp-php nil
  "´lsp-php´ integrates php-language-server with ´lsp-mode´."
  :group 'tools
  :group 'convenience)

(defcustom lsp-php-language-server-command
           (list "php" (expand-file-name "~/.config/composer/vendor/bin/php-language-server.php"))
           "Command to run ´php-language-server´."
           :type '(repeat (string))
           :group 'lsp-php)

(defcustom lsp-php-show-file-parse-notifications t
           "Show the \"Parsing file\" and \"Restored from cache\" messages."
           :type 'boolean
           :group 'lsp-php)

(defcustom lsp-php-workspace-root-detectors
           '(lsp-php-root-composer-json
             lsp-php-root-projectile
             lsp-php-root-vcs
             ".dir-locals.el"
             ".project"
             "index.php"
             "robots.txt")
           "How to detect the project root. Selected methods are tried in the order they are specified."
           :type '(repeat (choice
                            (const  :tag "Contains composer.json"      lsp-php-root-composer-json)
                            (const  :tag "Projectile root"             lsp-php-root-projectile)
                            (const  :tag "Version control system root" lsp-php-root-vcs)
                            (string :tag "Contains a named file")))
           :group 'lsp-php)

(defun lsp-php-parent (path)
  "For PATH a/b/ or a/b return a\/. 'nil is passed through."
  (when path
    (file-name-directory
      (directory-file-name
        (expand-file-name path)))))

(defun lsp-php-basename (path)
  "For PATH a/b/ or a/b return b. 'nil is passed through."
  (when path
    (file-name-nondirectory
      (directory-file-name
        (expand-file-name path)))))

(defun lsp-php-root-vcs ()
  "Return the project directory, as determined by VCS, if any."
  (when (vc-backend default-directory) (vc-root-dir)))

(defun lsp-php-is-composer-json-root (dir)
  "Check if DIR contains composer.json and is not a vendor package."
  (let ((expanded-dir (expand-file-name dir)))
    (and (file-exists-p (expand-file-name "composer.json" expanded-dir))
         (let* ((grandparent (lsp-php-parent (lsp-php-parent expanded-dir)))
                (basename-of-grandparent (lsp-php-basename grandparent)))
                (not (equal "vendor" basename-of-grandparent))))))

(defun lsp-php-root-composer-json ()
  "Return the parent directory containing composer.json, but which is not a vendor package."
  (locate-dominating-file default-directory 'lsp-php-is-composer-json-root))

(defun lsp-php-root-projectile ()
  "Return the projectile root, if any."
  (and
   (fboundp 'projectile-project-p)
   (fboundp 'projectile-project-root)
   (projectile-project-p)
   (projectile-project-root)))

(defun lsp-php-get-root ()
  "Find workspace root as specified by ´lsp-php-workspace-root-detectors´. Defaults to ´default-directory´."
  (expand-file-name
    (or (seq-some (lambda (filename-or-function)
                    (if (stringp filename-or-function)
                        (locate-dominating-file default-directory filename-or-function)
                        (funcall filename-or-function)))
                  lsp-php-workspace-root-detectors)
        (progn (message "Couldn't find project root, using the current directory as the root.")
               default-directory))))

(defun lsp-php-get-ignore-regexps ()
  "Return the list of regexps to filter php-language-server output with."
  (unless lsp-php-show-file-parse-notifications
    '("\"message\":\"Parsing file:"
      "\"message\":\"Restored .*from cache")))

(lsp-define-stdio-client lsp-php "php"
                         'lsp-php-get-root
                         lsp-php-language-server-command
                         :ignore-regexps (lsp-php-get-ignore-regexps))

(provide 'lsp-php)

; vim: ff=unix:sw=2:ts=2:tw=0

;;; lsp-php.el ends here
