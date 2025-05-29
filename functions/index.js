const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const Stripe = require("stripe");

// Define Stripe secret using Firebase Secrets (Cloud Secret Manager)
const stripeSecret = defineSecret("STRIPE_SECRET");

// Initialize Firebase Admin SDK
admin.initializeApp();

// Notification function (unchanged logic, upgraded to v2 onRequest)
exports.sendNotification = onRequest({ region: "us-central1" }, async (req, res) => {
  // Allow only POST
  if (req.method !== "POST") {
    return res.status(405).send("Method Not Allowed");
  }
  const { token, title, body } = req.body;
  if (!token || !title || !body) {
    return res.status(400).send("Missing token, title, or body in request.");
  }
  const message = {
    token: token,
    notification: { title: title, body: body },
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

// Stripe PaymentIntent creation function (updated for Gen 2)
exports.createPaymentIntent = onRequest(
{ region: "us-central1",
    secrets: ["STRIPE_SECRET"] },
 async (req, res) => {
 const stripeKey = stripeSecret.value();
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
      // Ensure amount is a number
      let totalAmount = typeof amount === "string" ? Number(amount) : amount;
      if (isNaN(totalAmount)) {
        return res.status(400).send({ success: false, error: "Invalid amount value." });
      }
      // Convert to smallest currency units if currency typically has decimals
      const zeroDecimalCurrencies = new Set(["JPY", "KRW", "VND"]);
      let stripeAmount = totalAmount;
      if (!zeroDecimalCurrencies.has(currency.toUpperCase())) {
        stripeAmount = Math.round(stripeAmount * 100);
      }
      // Initialize Stripe with secret key and create PaymentIntent
      const stripe = Stripe(stripeSecret.value());
      const paymentIntent = await stripe.paymentIntents.create({
        amount: stripeAmount,
        currency: currency.toLowerCase(),  // Stripe expects lowercase currency codes
        payment_method_types: ["card"],
      });
      // Return client secret to client
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
