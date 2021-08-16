namespace SecurityPrivacy {
    public const string DBUS_FPRINT_NAME = "net.reactivated.Fprint";
    public const string DBUS_FPRINT_PATH = "/net/reactivated/Fprint/Manager";
    
    public enum EnrollStatus {
        ENROLL_COMPLETED,
        ENROLL_FAILED,
        //  enroll-completed: The enrollment successfully completed, Device.EnrollStop should now be called.
        //  enroll-failed: The enrollment failed, Device.EnrollStop should now be called.
        //  enroll-stage-passed: One stage of the enrollment passed, the enrollment is still ongoing.
        //  enroll-retry-scan: The user should retry scanning their finger, the enrollment is still ongoing.
        //  enroll-swipe-too-short: The user's swipe was too short. The user should retry scanning their finger, the enrollment is still ongoing.
        //  enroll-finger-not-centered: The user's finger was not centered on the reader. The user should retry scanning their finger, the enrollment is still ongoing.
        //  enroll-remove-and-retry: The user should remove their finger from the reader and retry scanning their finger, the enrollment is still ongoing.
        //  enroll-data-full: No further prints can be enrolled on this device, Device.EnrollStop should now be called. Delete other prints from the device first to continue (e.g. from other users). Note that old prints or prints from other operating systems may be deleted automatically to resolve this error without any notification.
        //  enroll-duplicate: The print has already been enrolled, Device.EnrollStop should now be called. The user should enroll a different finger, or delete the print that has been enrolled already. This print may be enrolled for a different user. Note that an old duplicate (e.g. from a previous install) will be automatically garbage collected and should not cause any issues.
        //  enroll-disconnected: The device was disconnected during the enrollment, no other actions should be taken, and you shouldn't use the device any more.
        //  enroll-unknown-error: An unknown error occurred (usually a driver problem), Device.EnrollStop should now be called.
    }

    [DBus (name = "net.reactivated.Fprint.Manager")]
    interface Fprint : Object {
        public abstract ObjectPath[] GetDevices () throws GLib.Error;
        public abstract ObjectPath GetDefaultDevice () throws GLib.Error;
    }

    // https://fprint.freedesktop.org/fprintd-dev/Device.html
    [DBus (name = "net.reactivated.Fprint.Device")]
    interface FprintDevice : Object {
        public abstract string[] ListEnrolledFingers (string username) throws GLib.Error;
        public abstract void DeleteEnrolledFingers (string username) throws GLib.Error;
        public abstract void DeleteEnrolledFingers2 () throws GLib.Error;
        public abstract void DeleteEnrolledFinger (string finger_name) throws GLib.Error;
        public abstract void Claim (string username) throws GLib.Error;
        public abstract void Release () throws GLib.Error;
        public abstract void VerifyStart (string finger_name) throws GLib.Error;
        public abstract void VerifyStop () throws GLib.Error;
        public abstract void EnrollStart (string finger_name) throws GLib.Error;
        public abstract void EnrollStop () throws GLib.Error;
        
        public signal void VerifyFingerSelected (string finger_name);
        public signal void VerifyStatus (string result, bool done);
        public signal void EnrollStatus (string result, bool done);

        [DBus (name = "name")]
        public abstract string name { public owned get; }
        [DBus (name = "num-enroll-stages")]
        public abstract int num_enroll_stages { public owned get; }
        [DBus (name = "scan-type")]
        public abstract string scan_type { public owned get; }
        [DBus (name = "finger-present")]
        public abstract bool finger_present { public owned get; }
        [DBus (name = "finger-needed")]
        public abstract bool finger_needed { public owned get; }

    }
}
