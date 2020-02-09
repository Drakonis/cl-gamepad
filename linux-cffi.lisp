#|
 This file is a part of cl-gamepad
 (c) 2020 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(in-package #:org.shirakumo.fraf.gamepad.impl)

(cffi:define-foreign-library evdev
  (T (:default "libevdev")))

(cffi:defctype fd :int)
(cffi:defctype errno :int64)

(cffi:defbitfield open-flag
  (:read          #o0000000)
  (:write         #o0000002)
  (:create        #o0000100)
  (:ensure-create #o0000200)
  (:dont-claim-tty#o0000400)
  (:truncate      #o0001000)
  (:non-block     #o0004000)
  (:data-sync     #o0010000)
  (:async         #o0020000)
  (:direct        #o0040000)
  (:large-file    #o0100000)
  (:directory     #o0200000)
  (:no-follow     #o0400000)
  (:file-sync     #o4010000))

(cffi:defbitfield read-flag
  (:sync       1)
  (:normal     2)
  (:force-sync 4)
  (:blocking   8))

(cffi:defcenum read-status
  (:success 0)
  (:sync    1)
  (:again -11))

(cffi:defcenum property
  (:pointer        #x0)
  (:direct         #x1)
  (:button-pad     #x2)
  (:sim-mt         #x3)
  (:top-button-pad #x4)
  (:pointing-stick #x5)
  (:accelerometer  #x6))

(cffi:defcenum event-type
  (:synchronization #x00)
  (:key             #x01)
  (:relative-axis   #x02)
  (:absolute-axis   #x03)
  (:miscellaneous   #x04)
  (:switch          #x05)
  (:led             #x11)
  (:sound           #x12)
  (:repeat          #x14)
  (:force-feedback  #x15)
  (:power           #x16)
  (:force-feedback-status #x17))

(cffi:defbitfield (poll-event :short)
  (:in  #x001)
  (:pri #x002)
  (:out #x004))

(cffi:defbitfield (inotify-event :uint32)
  (:create #x00000100)
  (:delete #x00000200))

(cffi:defbitfield inotify-flag
  (:nonblock #o0004000)
  (:cloexec  #o2000000))

(cffi:defcstruct (axis-info :conc-name axis-info-)
  (value :int32)
  (minimum :int32)
  (maximum :int32)
  (fuzz :int32)
  (flat :int32)
  (resolution :int32))

(cffi:defcstruct (event :conc-name event-)
  (sec :uint64)
  (usec :uint64)
  (type :uint16)
  (code :uint16)
  (value :int32))

(cffi:defcstruct (pollfd :conc-name pollfd-)
  (fd fd)
  (events poll-event)
  (revents poll-event))

(cffi:defcstruct (inotify :conc-name inotify-)
  (wd :int)
  (mask inotify-event)
  (cookie :uint32)
  (length :uint32)
  (name :char :count 0))

(cffi:defcfun (u-open "open") fd
  (pathname :string)
  (mode open-flag))

(cffi:defcfun (u-close "close") :int
  (fd fd))

(cffi:defcfun (u-read "read") :int
  (fd fd)
  (buffer :pointer)
  (length :int))

(cffi:defcfun (poll "poll") :int
  (pollfds :pointer)
  (n :int)
  (timeout :int))

(cffi:defcfun (new-inotify "inotify_init1") fd
  (flags inotify-flag))

(cffi:defcfun (add-watch "inotify_add_watch") errno
  (fd fd)
  (path :string)
  (mask inotify-event))

(cffi:defcfun (new-from-fd "libevdev_new_from_fd") errno
  (fd fd)
  (device :pointer))

(cffi:defcfun (free-device "libevdev_free") :void
  (device :pointer))

(cffi:defcfun (get-name "libevdev_get_name") :string
  (device :pointer))

(cffi:defcfun (get-uniq "libevdev_get_uniq") :string
  (device :pointer))

(cffi:defcfun (get-id-bustype "libevdev_get_id_bustype") :int
  (device :pointer))

(cffi:defcfun (get-id-vendor "libevdev_get_id_vendor") :int
  (device :pointer))

(cffi:defcfun (get-id-product "libevdev_get_id_product") :int
  (device :pointer))

(cffi:defcfun (get-id-version "libevdev_get_id_version") :int
  (device :pointer))

(cffi:defcfun (get-driver-version "libevdev_get_driver_version") :int
  (device :pointer))

(cffi:defcfun (has-event-code "libevdev_has_event_code") :boolean
  (device :pointer)
  (type event-type)
  (code :uint))

(cffi:defcfun (has-event-type "libevdev_has_event_type") :boolean
  (device :pointer)
  (type event-type))

(cffi:defcfun (has-property "libevdev_has_property") :boolean
  (device :pointer)
  (property property))

(cffi:defcfun (get-axis-info "libevdev_get_abs_info") :pointer
  (device :pointer)
  (code :uint))

(cffi:defcfun (has-event-pending "libevdev_has_event_pending") errno
  (device :pointer))

(cffi:defcfun (next-event "libevdev_next_event") read-status
  (device :pointer)
  (flag read-flag)
  (event :pointer))