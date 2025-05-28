const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendNotification = functions.https.onRequest(async (req, res) => {
  // Allow only POST
  if (req.method !== "POST") {
    return res.status(405).send("Method Not Allowed");
  }

  // Get the device token, title, and body from the request
  const { token, title, body } = req.body;

  if (!token || !title || !body) {
    return res.status(400).send("Missing token, title, or body in request.");
  }

  // Construct the message
  const message = {
    token: token,
    notification: {
      title: title,
      body: body,
    },
    android: { priority: "high" },
    apns: { payload: { aps: { sound: "default" } } },
  };

  try {
    const response = await admin.messaging().send(message);
    console.log("Notification sent:", response);
    return res.status(200).send({ success: true, messageId: response });
  } catch (error) {
    console.error("Error sending notification:", error);
    return res.status(500).send({ success: false, error: error.message });
  }
});
