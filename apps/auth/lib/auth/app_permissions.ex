defmodule Auth.AppPermissions do
  @moduledoc """
  iex> ap = %Auth.AppPermissions{vapp_name: "app_ui", c_permission_sets: %{
  default: [:login,:token,:refresh,:logout],
  quote: [:manage, :approve, :convert, :order, :package],
  package: [:select, :manage, :release, :item],
  item: [:select, :manage],
  order: [:manage, :ship, :bill],
  bill: [:charge, :refund],
  customer: [:create, :manage, :contact, :order, :quote],
  contact: [:manage, :communicate],
  support_ticket: [:create, :manage, :escalate, :bill]}}
  iex>  ap|> Auth.Repo.insert
  """

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:nid, :id, autogenerate: true}
  @derive {Phoenix.Param, key: :nid}

  schema "app_permissions" do
    field(:vapp_name, :string)
    field(:c_permission_sets, :map)
  end

  @required_fields [:vapp_name, :c_permission_sets]

  @read_on_cast [:vapp_name, :c_permission_sets]

  @doc """
  Creates a changeset based on the `model` and `params`.
  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(app_permissions, params \\ %{}) do
    app_permissions
    |> cast(params, @read_on_cast)
    |> validate_required(@required_fields)
    |> validate_length(:vapp_name, min: 3, max: 128)
  end

  def app_perm_tests, do: {:ok, app_permissions()}

  def app_permissions do
    %{
      default: ["login", "token", "logout", "refresh", "exchange"],
      auth_test: [:p1, :p2, :p3, :p4],
      administration: [:all, :browse, :update, :delete, :none],
      documents: ["All", "Browse", "Update", "Delete", "None"],
      administration_security: ["All", "Browse", "Update", "Delete", "None"],
      billing: ["All", "Browse", "Update", "Delete", "None"],
      billing_customerCollections: ["All", "Browse", "Update", "Delete", "None"],
      billing_invoicing: ["All", "Browse", "Update", "Delete", "None"],
      billing_management: ["All", "Browse", "Update", "Delete", "None"],
      billing_processPayments: ["All", "Browse", "Update", "Delete", "None"],
      billing_serviceCancellations: ["All", "Browse", "Update", "Delete", "None"],
      communications: ["All", "Browse", "Update", "Delete", "None"],
      customerManagement: ["All", "Browse", "Update", "Delete", "None"],
      customerManagement_search: ["All", "Browse", "Update", "Delete", "None"],
      customerManagement_accountInformation: ["All", "Browse", "Update", "Delete", "None"],
      customerManagement_status: ["All", "Browse", "Update", "Delete", "None"],
      customerManagement_subscriptions: ["All", "Browse", "Update", "Delete", "None"],
      customerManagement_contacts: ["All", "Browse", "Update", "Delete", "None"],
      customerManagement_locations: ["All", "Browse", "Update", "Delete", "None"],
      customerManagement_phoneNumbers: ["All", "Browse", "Update", "Delete", "None"],
      customerManagement_documents: ["All", "Browse", "Update", "Delete", "None"],
      billing_history: ["All", "Browse", "Update", "Delete", "None"],
      customerManagement_hardwareHistory: ["All", "Browse", "Update", "Delete", "None"],
      humanResources: ["All", "Browse", "Update", "Delete", "None"],
      jobs: ["All", "Browse", "Update", "Delete", "None"],
      orders: ["All", "Browse", "Update", "Delete", "None"],
      orders_quotes: ["All", "Browse", "Update", "Delete", "None"],
      orders_quotes_generate: ["All", "Browse", "Update", "Delete", "None"],
      orders_customerOrders: ["All", "Browse", "Update", "Delete", "None"],
      orders_installations: ["All", "Browse", "Update", "Delete", "None"],
      orders_management: ["All", "Browse", "Update", "Delete", "None"],
      support: ["All", "Browse", "Update", "Delete", "None"],
      myProfile: ["All", "Browse", "Update", "Delete", "None"],
      logout: ["All", "Browse", "Update", "Delete", "None"]
    }
  end
end
