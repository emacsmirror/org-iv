;;; org-iv.el --- a tool used to view html generated by org-file immediately.

;; This is free and unencumbered software released into the public domain.

;; Author: kuangdash <kuangdash@163.com>
;; Version: 1.0.0
;; URL: https://github.com/kuangdash/org-iv
;; Package-Requires: ((impatient-mode "1.0.0") (org "8.0"))

;;; Commentary:

;; org-iv is a tool used to view html generated by org-file
;; immediately. Powered by impatient-mode.

;;; Code:

(require 'ox)
(require 'impatient-mode)
(require 'org-iv-config)

;;;###autoload
(defun org-iv/immediate-view (config-name)
  "Use impatient-mode to view html-file generated by org-file quickly."
  (interactive
   (let ((config-name
          (ido-completing-read "Which config do you want to apply? "
                               (mapcar 'car org-iv/config-alist)
                               nil t nil nil nil)))
     (list config-name)))
  (setq org-iv--current-config-name config-name)
  (with-temp-buffer
    (insert-file-contents (org-iv--get-config-option :front-html-file))
    (setq org-iv--front-html-string (buffer-string)))
  (with-temp-buffer
    (insert-file-contents (org-iv--get-config-option :back-html-file))
    (setq org-iv--back-html-string (buffer-string)))
  (let ((web-port (org-iv--get-config-option :web-test-port))
        (web-dir (org-iv--get-config-option :web-test-root)))
    (setq httpd-port web-port)
    (httpd-serve-directory web-dir)
    (imp-visit-buffer))
  (imp-set-user-filter `(lambda (org-file)
                          "For use impatient-mode"
                          (let ((html-string (with-current-buffer org-file
                                               (org-export-as 'html nil nil t nil))))
                            (insert org-iv--front-html-string
                                    "\n"
                                    html-string
                                    "\n"
                                    org-iv--back-html-string))))
  (message "org-immediate-view: begin!!"))

(defun org-iv/stop-immediate-view ()
  "stop org-iv/immediate-view"
  (interactive)
  (when (imp-buffer-enabled-p (buffer-name))
    (impatient-mode)
    (when (yes-or-no-p "Stop the running http-server?: ")
      (httpd-stop))))

(defun org-iv/manually-update ()
  "Use org-iv/immediate-view manually"
  (interactive)
  (when (some (lambda (element) (equal element 'imp--on-change)) after-change-functions)
    (remove-hook 'after-change-functions 'imp--on-change t))
  (imp--on-change))

(defun org-iv/restart-view ()
  "Restart org-iv/immediate-view"
  (interactive)
  (when (imp-buffer-enabled-p (buffer-name))
    (impatient-mode)
    (httpd-stop))
  (call-interactively 'org-iv/immediate-view))

(provide 'org-iv)
;;; org-iv.el ends here
