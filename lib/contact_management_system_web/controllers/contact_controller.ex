defmodule ContactManagementSystemWeb.ContactController do
  use ContactManagementSystemWeb, :controller

  alias ContactManagementSystem.Contacts
  alias ContactManagementSystem.Contacts.Contact
  alias ContactManagementSystemWeb.{Mailer, Email}

  action_fallback ContactManagementSystemWeb.FallbackController

  def index(conn, _params) do
    contacts = Contacts.list_contacts()
    render(conn, "index.json", contacts: contacts)
  end

  def create(conn, %{"contact" => contact_params}) do
    contact_params =
      Map.merge(contact_params, %{"user_id" => conn.private.guardian_default_resource.id})

    with {:ok, %Contact{} = contact} <- Contacts.create_contact(contact_params) do
      user_list = ContactManagementSystem.Accounts.list_users

      user_list
      |> Enum.map(fn user ->
        email = Email.new_contact_added(user.email, contact)

        email |> Mailer.deliver_later
      end)

      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.contact_path(conn, :show, contact))
      |> render("show.json", contact: contact)
    end
  end

  def show(conn, %{"id" => id}) do
    contact = Contacts.get_contact!(id)
    render(conn, "show.json", contact: contact)
  end

  def update(conn, %{"id" => id, "contact" => contact_params}) do
    contact = Contacts.get_contact!(id)

    with {:ok, %Contact{} = contact} <- Contacts.update_contact(contact, contact_params) do
      render(conn, "show.json", contact: contact)
    end
  end

  def delete(conn, %{"id" => id}) do
    contact = Contacts.get_contact!(id)

    with {:ok, %Contact{}} <- Contacts.delete_contact(contact) do
      send_resp(conn, :no_content, "")
    end
  end
end
