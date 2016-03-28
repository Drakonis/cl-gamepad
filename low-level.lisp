#|
 This file is a part of cl-gamepad
 (c) 2016 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(in-package #:org.shirakumo.fraf.gamepad)

(defvar *here* #.(or *compile-file-pathname* *load-pathname* *default-pathname-defaults*))
(defvar *static* (make-pathname :name NIL :type NIL :defaults (merge-pathnames "static/" *here*)))
(pushnew *static* cffi:*foreign-library-directories*)

(define-foreign-library libstem-gamepad
  (:darwin (:or "libstem_gamepad.dylib" "libstem_gamepad.so"
                #+X86 "mac32-libstem_gamepad.so"
                #+X86-64 "mac64-libstem_gamepad.so"))
  (:unix (:or "libstem_gamepad.so"
              #+X86 "lin32-libstem_gamepad.so"
              #+X86-64 "lin64-libstem_gamepad.so"))
  (:windows (:or "stem_gamepad.dll"
                 #+X86 "win32-libstem_gamepad.dll"
                 #+X86-64 "win64-libstem_gamepad.dll"))
  (t (:default "stem_gamepad")))

(use-foreign-library libstem-gamepad)

(defcstruct (device :class device :conc-name device-)
  (id :uint)
  (description :string)
  (vendor :int)
  (product :int)
  (axes :int)
  (buttons :int)
  (axis-states (:pointer :float))
  (button-states (:pointer :bool))
  (private-data :pointer))

(defun device-axis (device axis)
  (mem-aref (device-axis-states device) :float axis))

(defun device-button (device button)
  (mem-aref (device-button-states device) :bool button))

(defun device-plist (device)
  (flet ((to-vector (p size type)
           (let ((array (make-array size)))
             (dotimes (i size array)
               (setf (aref array i) (mem-aref p type i))))))
    `(:id ,(device-id device)
      :description ,(device-description device)
      :vendor ,(device-vendor device)
      :product ,(device-product device)
      :axis-states ,(to-vector (device-axis-states device) (device-axes device) :float)
      :button-states ,(to-vector (device-button-states device) (device-buttons device) :bool))))

(defmacro with-callback-handling (() &body body)
  `(ignore-errors
    (with-simple-restart (continue "Ignore problem and continue.")
      (handler-bind ((error #'invoke-debugger))
        ,@body))))

(defcallback device-attach-func :void ((device :pointer (:struct device)) (context :pointer))
  (declare (ignore context))
  (with-callback-handling ()
    (device-attached device)))

(defcallback device-remove-func :void ((device :pointer (:struct device)) (context :pointer))
  (declare (ignore context))
  (with-callback-handling ()
    (device-removed device)))

(defcallback button-down-func :void ((device :pointer (:struct device)) (button :uint) (timestamp :double) (context :pointer))
  (declare (ignore context))
  (with-callback-handling ()
    (button-pressed button timestamp device)))

(defcallback button-up-func :void ((device :pointer (:struct device)) (button :uint) (timestamp :double) (context :pointer))
  (declare (ignore context))
  (with-callback-handling ()
    (button-released button timestamp device)))

(defcallback axis-move-func :void ((device :pointer (:struct device)) (axis :uint) (value :float) (last-value :float) (timestamp :double) (context :pointer))
  (declare (ignore context))
  (with-callback-handling ()
    (axis-moved axis last-value value timestamp device)))

(defcfun (gamepad-init "Gamepad_init") :void)

(defcfun (gamepad-shutdown "Gamepad_shutdown") :void)

(defcfun (gamepad-num-devices "Gamepad_numDevices") :uint)

(defcfun (gamepad-device-at-index "Gamepad_deviceAtIndex") (:pointer (:struct device))
  (device-index :uint))

(defcfun (gamepad-detect-devices "Gamepad_detectDevices") :void)

(defcfun (gamepad-process-events "Gamepad_processEvents") :void)

(defcfun (device-attach-func "Gamepad_deviceAttachFunc") :void
  (callback :pointer)
  (context :pointer))

(defcfun (device-remove-func "Gamepad_deviceRemoveFunc") :void
  (callback :pointer)
  (context :pointer))

(defcfun (gamepad-button-down-func "Gamepad_buttonDownFunc") :void
  (callback :pointer)
  (context :pointer))

(defcfun (gamepad-button-up-func "Gamepad_buttonUpFunc") :void
  (callback :pointer)
  (context :pointer))

(defcfun (gamepad-axis-move-func "Gamepad_axisMoveFunc") :void
  (callback :pointer)
  (context :pointer))
