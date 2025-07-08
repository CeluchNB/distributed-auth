import { useAuth0 } from "@auth0/auth0-react";

export const Login = () => {
  const { loginWithRedirect } = useAuth0();

  return (
    <>
      <h1>Login</h1>
      <button onClick={() => loginWithRedirect()}>Log In</button>
    </>
  );
};
