// auth0-http-api-authorizer.js
import jwt from "jsonwebtoken";
import jwksClient from "jwks-rsa";

const auth0Domain = "dev-woyyxkiic38yweid.us.auth0.com";
const audience = "https://a1cm73htda.execute-api.us-east-1.amazonaws.com/prod";

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

const handler = async (event) => {
  const authHeader = event.headers.authorization || event.headers.Authorization;

  if (!authHeader || !authHeader.toLowerCase().startsWith("bearer ")) {
    return { isAuthorized: false };
  }

  const token = authHeader.split(" ")[1];

  console.log("token", token);

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

    console.log("decoded token", decoded);

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
