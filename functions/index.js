const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const Stripe = require("stripe");

const stripeSecret = defineSecret("STRIPE_SECRET");

admin.initializeApp();

exports.sendNotification = onRequest({ region: "us-central1" }, async (req, res) => {
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

exports.createPaymentIntent = onRequest(
{ region: "us-central1",
    secrets: ["STRIPE_SECRET"] },
 async (req, res) => {
 const stripeKey = stripeSecret.value();

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
      let totalAmount = typeof amount === "string" ? Number(amount) : amount;
      if (isNaN(totalAmount)) {
        return res.status(400).send({ success: false, error: "Invalid amount value." });
      }
      const zeroDecimalCurrencies = new Set(["RON"]);
      let stripeAmount = totalAmount;
      if (!zeroDecimalCurrencies.has(currency.toUpperCase())) {
        stripeAmount = Math.round(stripeAmount * 100);
      }
      const stripe = Stripe(stripeSecret.value());
      const paymentIntent = await stripe.paymentIntents.create({
        amount: stripeAmount,
        currency: currency.toLowerCase(),
        payment_method_types: ["card"],
      });
      return res.status(200).send({ success: true, clientSecret: paymentIntent.client_secret });
    } else if (paymentMethod === "cash") {
      return res.status(200).send({ success: true, message: "Cash payment selected; no payment required." });
    } else {
      return res.status(400).send({ success: false, error: "Unsupported payment method." });
    }
  } catch (error) {
    console.error("Error creating payment intent:", error);
    return res.status(500).send({ success: false, error: error.message });
  }
});
