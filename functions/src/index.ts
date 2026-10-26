import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as crypto from "crypto";

admin.initializeApp();
const db = admin.firestore();

// Haversine distance in metres
function calculateDistanceInMetres(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371000; // Earth radius in metres
  const toRad = (deg: number) => (deg * Math.PI) / 180;

  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// Generate secure 6-digit OTP
function generateSecureOtp(): string {
  const randomBytes = crypto.randomBytes(4);
  const num = randomBytes.readUInt32BE(0) % 900000 + 100000;
  return num.toString();
}

function hashOtp(otp: string, sessionId: string): string {
  return crypto
    .createHash("sha256")
    .update(`${otp}:${sessionId}:AttendXSecretSalt`)
    .digest("hex");
}

/**
 * 1. Create Attendance Session
 */
export const createAttendanceSession = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Authentication is required."
      );
    }

    const {
      courseId,
      courseName,
      sectionId,
      sectionName,
      departmentId,
      facultyLatitude,
      facultyLongitude,
      facultyLocationAccuracy,
      durationMinutes = 30,
      maxDistanceMeters = 20.0,
      otpExpirySeconds = 120,
    } = data;

    if (!courseId || !sectionId || facultyLatitude == null || facultyLongitude == null) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required course, section, or GPS coordinates."
      );
    }

    const facultyId = context.auth.uid;

    // Check for existing active session for this section
    const activeCheck = await db
      .collection("attendance_sessions")
      .where("sectionId", "==", sectionId)
      .where("status", "==", "ACTIVE")
      .limit(1)
      .get();

    if (!activeCheck.empty) {
      throw new functions.https.HttpsError(
        "already-exists",
        "An active attendance session already exists for this section."
      );
    }

    const sessionRef = db.collection("attendance_sessions").doc();
    const otp = generateSecureOtp();
    const now = new Date();
    const otpExpiresAt = new Date(now.getTime() + otpExpirySeconds * 1000);

    const sessionData = {
      facultyId,
      courseId,
      courseName,
      sectionId,
      sectionName,
      departmentId,
      facultyLatitude,
      facultyLongitude,
      facultyLocationAccuracy,
      startTime: admin.firestore.Timestamp.fromDate(now),
      status: "ACTIVE",
      durationMinutes,
      otpExpirySeconds,
      maxDistanceMeters,
      totalEnrolled: 0,
      totalPresent: 0,
      currentOtpHash: hashOtp(otp, sessionRef.id),
      otpExpiresAt: admin.firestore.Timestamp.fromDate(otpExpiresAt),
    };

    await sessionRef.set(sessionData);

    // Audit log
    await db.collection("audit_logs").add({
      type: "SESSION_CREATED",
      severity: "LOW",
      title: `Session initiated for ${courseName} (${sectionName})`,
      userId: facultyId,
      sessionId: sessionRef.id,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      sessionId: sessionRef.id,
      otp,
      expiresAt: otpExpiresAt.toISOString(),
      secondsRemaining: otpExpirySeconds,
    };
  }
);

/**
 * 2. Generate / Refresh OTP for Active Session
 */
export const generateOtp = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Authentication required.");
  }

  const { sessionId } = data;
  if (!sessionId) {
    throw new functions.https.HttpsError("invalid-argument", "Session ID required.");
  }

  const sessionRef = db.collection("attendance_sessions").doc(sessionId);
  const sessionDoc = await sessionRef.get();

  if (!sessionDoc.exists) {
    throw new functions.https.HttpsError("not-found", "Session not found.");
  }

  const session = sessionDoc.data()!;
  if (session.status !== "ACTIVE") {
    throw new functions.https.HttpsError("failed-precondition", "Session is not active.");
  }

  if (session.facultyId !== context.auth.uid) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only the hosting faculty member can refresh the OTP."
    );
  }

  const otp = generateSecureOtp();
  const now = new Date();
  const expirySeconds = session.otpExpirySeconds || 120;
  const otpExpiresAt = new Date(now.getTime() + expirySeconds * 1000);

  await sessionRef.update({
    currentOtpHash: hashOtp(otp, sessionId),
    otpExpiresAt: admin.firestore.Timestamp.fromDate(otpExpiresAt),
  });

  return {
    otp,
    expiresAt: otpExpiresAt.toISOString(),
    secondsRemaining: expirySeconds,
  };
});

/**
 * 3. Submit Attendance with Multi-Factor Verification (Atomic Transaction)
 */
export const submitAttendance = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Authentication required.");
    }

    const {
      sessionId,
      otp,
      studentLatitude,
      studentLongitude,
      studentLocationAccuracy,
      deviceId,
    } = data;

    if (!sessionId || !otp || studentLatitude == null || studentLongitude == null) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required attendance verification payload."
      );
    }

    const studentId = context.auth.uid;
    const sessionRef = db.collection("attendance_sessions").doc(sessionId);
    const studentUserDoc = await db.collection("users").doc(studentId).get();
    const studentData = studentUserDoc.data() || {};
    const studentName = studentData.displayName || "Student";
    const rollNumber = studentData.rollNumber || "Unknown";

    let distance = 0;

    // Run atomic verification transaction
    await db.runTransaction(async (transaction) => {
      const sessionDoc = await transaction.get(sessionRef);
      if (!sessionDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Attendance session not found.");
      }

      const session = sessionDoc.data()!;
      if (session.status !== "ACTIVE") {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Attendance session has been closed or expired."
        );
      }

      // Check OTP expiry
      const now = new Date();
      const otpExpires = session.otpExpiresAt ? session.otpExpiresAt.toDate() : null;
      if (otpExpires && now > otpExpires) {
        throw new functions.https.HttpsError(
          "deadline-exceeded",
          "The entered OTP has expired. Please ask the instructor for the fresh OTP."
        );
      }

      // Check OTP hash
      const submittedHash = hashOtp(otp.trim(), sessionId);
      if (submittedHash !== session.currentOtpHash) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Invalid OTP code entered."
        );
      }

      // Check duplicate submission
      const recordQuery = db
        .collection("attendance_records")
        .where("sessionId", "==", sessionId)
        .where("studentId", "==", studentId)
        .limit(1);

      const existingRecords = await transaction.get(recordQuery);
      if (!existingRecords.empty) {
        throw new functions.https.HttpsError(
          "already-exists",
          "Attendance has already been recorded for this session."
        );
      }

      // Calculate distance using Haversine
      distance = calculateDistanceInMetres(
        studentLatitude,
        studentLongitude,
        session.facultyLatitude,
        session.facultyLongitude
      );

      const maxDistance = session.maxDistanceMeters || 20.0;
      if (distance > maxDistance) {
        // Record security violation log
        const auditRef = db.collection("audit_logs").doc();
        transaction.set(auditRef, {
          type: "LOCATION_BREACH_REJECT",
          severity: "HIGH",
          title: `Geofence violation rejected for ${rollNumber}`,
          studentId,
          rollNumber,
          sessionId,
          distance: Math.round(distance * 10) / 10,
          threshold: maxDistance,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });

        throw new functions.https.HttpsError(
          "out-of-range",
          `Verification failed: You are ${distance.toFixed(
            1
          )}m away from the classroom (Maximum allowed: ${maxDistance}m).`
        );
      }

      // Create attendance record
      const recordRef = db.collection("attendance_records").doc();
      transaction.set(recordRef, {
        sessionId,
        studentId,
        studentName,
        rollNumber,
        status: "PRESENT",
        studentLatitude,
        studentLongitude,
        studentLocationAccuracy: studentLocationAccuracy || null,
        distanceFromFaculty: Math.round(distance * 10) / 10,
        submittedAt: admin.firestore.FieldValue.serverTimestamp(),
        deviceId: deviceId || null,
        isManuallyMarked: false,
      });

      // Increment session totalPresent
      transaction.update(sessionRef, {
        totalPresent: admin.firestore.FieldValue.increment(1),
      });
    });

    return {
      success: true,
      distanceFromFaculty: Math.round(distance * 10) / 10,
      timestamp: new Date().toISOString(),
    };
  }
);

/**
 * 4. Close Session
 */
export const closeSession = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Authentication required.");
  }

  const { sessionId, reason } = data;
  const sessionRef = db.collection("attendance_sessions").doc(sessionId);
  const sessionDoc = await sessionRef.get();

  if (!sessionDoc.exists) {
    throw new functions.https.HttpsError("not-found", "Session not found.");
  }

  const session = sessionDoc.data()!;
  if (session.facultyId !== context.auth.uid) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only the session host can close this session."
    );
  }

  await sessionRef.update({
    status: "CLOSED",
    endTime: admin.firestore.FieldValue.serverTimestamp(),
    closureReason: reason || "Manual closure by faculty instructor.",
  });

  return { success: true };
});
