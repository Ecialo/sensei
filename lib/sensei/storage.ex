defmodule Sensei.Storage do
  use Supervisor

  require Logger
  require OK

  alias Mongo.Session

  alias Sensei.{
    User,
    Course
  }

  alias Sensei.Storage.{
    Users,
    Courses
  }

  alias __MODULE__, as: Storage

  @sensei_db :sensei_db
  @tx_supported? Application.get_env(:sensei, Sensei.Storage, [])[:tx_supported?]

  defguard is_mongo_error(err)
           when is_exception(err, Mongo.Error) or is_exception(err, Mongo.WriteError)

  def start_link(init_arg) do
    Supervisor.start_link(Storage, init_arg, name: Storage)
  end

  def init(init_arg) do
    children = [
      {Mongo, [name: @sensei_db] ++ init_arg}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def get_user(nadia_user) do
    user_id = nadia_user.id

    u =
      Users.get_user_by_id(user_id, @sensei_db) ||
        get_and_refine_user(nadia_user) ||
        {:error, :no_such_user}

    case u do
      {:error, _} = err -> err
      user -> {:ok, user}
    end
  end

  defp get_and_refine_user(nadia_user) do
    Logger.debug("Refine user")
    username = nadia_user.username

    do_get_and_refine_users = fn opts ->
      OK.for do
        user <- Users.get_user_by_username(username, @sensei_db, opts)
        refined_user = User.refine_user(user, nadia_user)
        _delete_result <- Users.delete_user(user, @sensei_db, opts)
        _id <- Users.put_user(refined_user, @sensei_db, opts)
        _ <- Courses.refine_courses(refined_user, @sensei_db, opts)
      after
        refined_user
      end
    end

    if @tx_supported? do
      Session.with_transaction(@sensei_db, do_get_and_refine_users)
    else
      do_get_and_refine_users.([])
    end
    |> case do
      {:ok, o} -> o
      {:error, _} -> nil
    end
  end

  def get_course(course_id) do
    case Courses.get_course(course_id, @sensei_db) do
      nil -> {:error, :no_such_course}
      c -> {:ok, c}
    end
  end

  @spec get_all_courses :: {:error, any} | {:ok, list}
  def get_all_courses() do
    Courses.get_all_courses_such(%{}, @sensei_db)
  end

  def get_all_active_courses_for(day_of_week) do
    filters = %{
      "schedule.day" => day_of_week,
      "active?" => true
    }

    Courses.get_all_courses_such(filters, @sensei_db)
  end

  def clear_course_confirmations(course) do
    id = course.id

    case get_course(id) do
      {:ok, course} ->
        Course.clear_confirmed(course)
        |> put()

      err ->
        Logger.error(inspect(err))
        :ok
    end
  end

  def put(%User{} = user) do
    Users.put_user(user, @sensei_db)
  end

  def put(%Course{} = course) do
    Courses.put_course(course, @sensei_db)
  end

  def delete(%User{} = user) do
    Users.delete_user(user, @sensei_db)
  end

  def flush do
    Mongo.drop_collection(@sensei_db, Courses.collection())
    Mongo.drop_collection(@sensei_db, Users.collection())
  end

  def topology_pid do
    @sensei_db
  end
end
