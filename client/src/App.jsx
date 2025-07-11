import "./App.css";
import { Auth0Provider } from "@auth0/auth0-react";
import { BrowserRouter, Routes, Route } from "react-router";
import { Login } from "./Login";
import { Logout } from "./Logout";
import { Home } from "./Home";
import { QueryClient, QueryClientProvider } from "react-query";

function App() {
  return (
    <Auth0Provider
      domain=""
      clientId=""
      authorizationParams={{
        redirect_uri: "http://localhost:5173/home",
        audience: "",
      }}
    >
      <QueryClientProvider client={new QueryClient()}>
        <BrowserRouter>
          <Routes>
            <Route index path="login" element={<Login />} />
            <Route path="logout" element={<Logout />} />
            <Route path="home" element={<Home />} />
          </Routes>
        </BrowserRouter>
      </QueryClientProvider>
    </Auth0Provider>
  );
}

export default App;
