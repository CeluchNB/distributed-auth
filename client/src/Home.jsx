import { useAuth0 } from "@auth0/auth0-react";

const URL = "";

export const Home = () => {
  const { user, isAuthenticated, isLoading, getAccessTokenSilently, logout } =
    useAuth0();

  console.log("data", isLoading, isAuthenticated, user);

  const fetchOne = async () => {
    const token = await getAccessTokenSilently();
    const response = await fetch(`${URL}/service1`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    const result = await response.json();
    return result;
  };

  const fetchTwo = async () => {
    const token = await getAccessTokenSilently();

    const response = await fetch(`${URL}/service2`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    const result = await response.json();
    return result;
  };

  return (
    <div className="home">
      <h1>Welcome to the Home Page</h1>
      <p>This is a protected route that requires authentication.</p>
      <div style={{ display: "flex", flexDirection: "column", gap: "10px" }}>
        <button onClick={() => fetchOne()}>Get Data #1</button>
        <button onClick={() => fetchTwo()}>Get Data #2</button>
        <button
          onClick={async () => {
            await logout({ returnTo: "http://localhost:5173/login" });
            window.location.href = "/login";
          }}
        >
          Log Out
        </button>
      </div>
    </div>
  );
};
