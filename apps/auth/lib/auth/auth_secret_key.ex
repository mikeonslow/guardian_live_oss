defmodule Auth.SecretKey do
  def fetch do
    JOSE.JWS.generate_key(%{"alg" => "HS512"})
    |> JOSE.JWK.to_map()
    |> elem(1)
    |> Map.take(["k", "kty"])
  end
end
