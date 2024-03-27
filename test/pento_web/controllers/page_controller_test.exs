defmodule PentoWeb.PageControllerTest do
  use PentoWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 302) =~ "You are being <a href=\"/guess\">redirected</a>"
  end
end
