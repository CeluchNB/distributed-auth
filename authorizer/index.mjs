// auth0-http-api-authorizer.js
import jwt from "jsonwebtoken";
import jwksClient from "jwks-rsa";

const auth0Domain = "";
const audience = process.env.AUDIENCE;

const client = jwksClient({
  jwksUri: `https://${auth0Domain}/.well-known/jwks.json`,
});

function getKey(header, callback) {
  client.getSigningKey(header.kid, (err, key) => {
    if (err) return callback(err);
    const signingKey = key.getPublicKey();
    callback(null, signingKey);
  });
}

export const handler = async (event) => {
  const authHeader = event.headers.authorization || event.headers.Authorization;

  if (!authHeader || !authHeader.toLowerCase().startsWith("bearer ")) {
    return { isAuthorized: false };
  }

  const token = authHeader.split(" ")[1];

  try {
    const decoded = await new Promise((resolve, reject) => {
      jwt.verify(
        token,
        getKey,
        {
          audience,
          issuer: `https://${auth0Domain}/`,
          algorithms: ["RS256"],
        },
        (err, decoded) => {
          if (err) reject(err);
          else resolve(decoded);
        }
      );
    });

    // ✅ Token is valid
    return {
      isAuthorized: true,
      context: {
        sub: decoded.sub,
        email: decoded.email || "",
      },
    };
  } catch (err) {
    console.error("Token verification failed:", err.message);
    return { isAuthorized: false };
  }
};
