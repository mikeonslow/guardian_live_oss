defmodule Auth.Guardian do
  use Guardian, otp_app: :auth

  use Guardian.Permissions.Bitwise

  def build_claims(claims, _resource, opts) do
    claims =
      claims
      |> encode_permissions_into_claims!(Keyword.get(opts, :permissions))

    {:ok, claims}
  end

  def subject_for_token(%{id: id}, _claims), do: {:ok, "User:#{id}"}
  def subject_for_token(_, _), do: {:error, "Unknown resource type"}

  def resource_from_claims(%{"sub" => "User:" <> user_id}) do
    # TODO calling DB here - need to move to cache
    resource = Auth.get_user(user_id)
    {:ok, resource}
  end

  def resource_from_claims(_claims) do
    {:error, :reason_for_error}
  end
end
