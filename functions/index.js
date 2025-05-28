const functions = require("firebase-functions");
const admin = require("firebase-admin");
const stripe = require("stripe")(functions.config().stripe.secret); // Load Stripe secret from config (set via "firebase functions:config:set stripe.secret=<YOUR_SECRET_KEY>")

admin.initializeApp();

// Existing notification function (unchanged)
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

// New payment intent creation function
exports.createPaymentIntent = functions.https.onRequest(async (req, res) => {
  // Allow only POST
  if (req.method !== "POST") {
    return res.status(405).send("Method Not Allowed");
  }

  const { amount, currency, paymentMethod } = req.body;
  if (!amount || !currency || !paymentMethod) {
    return res.status(400).send({
      success: false,
      error: "Missing amount, currency, or paymentMethod in request.",
    });
  }

  try {
    if (paymentMethod === "card") {
      // Calculate the charge amount in the smallest currency unit (e.g., cents for USD/EUR, bani for RON)
      let totalAmount = amount;
      if (typeof totalAmount === "string") {
        totalAmount = Number(totalAmount);
      }
      if (isNaN(totalAmount)) {
        return res.status(400).send({ success: false, error: "Invalid amount value." });
      }
      // Convert to minor units if currency has decimals
      const zeroDecimalCurrencies = new Set(["JPY", "KRW", "VND"]);
      let stripeAmount = totalAmount;
      if (!zeroDecimalCurrencies.has(currency.toUpperCase())) {
        stripeAmount = Math.round(stripeAmount * 100);
      }

      // Create a PaymentIntent with the given amount and currency
      const paymentIntent = await stripe.paymentIntents.create({
        amount: stripeAmount,
        currency: currency,
        payment_method_types: ["card"],  // limit to card payments
      });
      // Return the client secret to the client
      return res.status(200).send({ success: true, clientSecret: paymentIntent.client_secret });
    } else if (paymentMethod === "cash") {
      // No PaymentIntent needed for cash payments
      return res.status(200).send({ success: true, message: "Cash payment selected; no payment required." });
    } else {
      // Unsupported payment method
      return res.status(400).send({ success: false, error: "Unsupported payment method." });
    }
  } catch (error) {
    console.error("Error creating payment intent:", error);
    return res.status(500).send({ success: false, error: error.message });
  }
});
