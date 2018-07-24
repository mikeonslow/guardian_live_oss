defmodule Auth.Channel do
  @moduledoc """
  Provides integration for channels to use Guardian tokens.
  TODO copy design of @timed annotaion(see: https://github.com/pinterest/elixometer/blob/master/test/elixometer_test.exs)
  from https://github.com/pinterest/elixometer/blob/master/lib/elixometer.ex
  Have @permissions([<permission bit>])annotation avaialble to secure functions

  For example:
  @permissions(:save_app_roles) 
  def handle_in("save_app_roles", roles , socket) do

  """
  defmacro __using__(_opts) do
    quote do
      # require Logger

      def join(@channel_name <> user_id, %{}, authed_socket) do
        claims =
          authed_socket
          |> Guardian.Phoenix.Socket.current_claims()

        # Logger.info "claims  =>  #{inspect claims}"
        claims
        |> Auth.Guardian.decode_permissions_from_claims()
        |> Auth.Guardian.any_permissions?(@channel_permissions)
        |> decide(authed_socket)
      end

      # Deny joining the channel if the user isn't authenticated
      def join(@channel_name, _, _) do
        {:error, %{error: "not authorized, are you logged in?"}}
      end

      ###########################################################
      #
      #  Private functions
      #
      ###########################################################
      def decide(true, authed_socket) do
        # Logger.info "socket.assigns  =>  #{inspect authed_socket.assigns}"
        # Logger.debug "Joined authorized:#{inspect user_id} having claims #{inspect claims}" 
        # {resource.sName}"}, socket}
        {:ok, %{message: "Welcome # "}, authed_socket}
      end

      def decide(false, authed_socket), do: {:error, %{error: :not_all_permissions}}

      defp response(response, socket), do: {:reply, response, socket}

      defp user_id(%{id: "user_socket:" <> user_id}) do
        user_id
      end

      defp user_id(_socket), do: 0
    end
  end
end
