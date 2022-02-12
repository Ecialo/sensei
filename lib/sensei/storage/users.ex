defmodule Sensei.Storage.Users do
  @moduledoc """
  Two main cases of appear of user:
    1. User launch /start
    2. Admin add some sensei, who doesnt launch /start (active? == false)

  In case 2. we use fake id and replace with real id (refine user), when sensei launch bot
  """
  require OK
  require Logger

  alias Mongo.Session

  alias Sensei.{
    Storage,
    User
  }

  @user_col "users"

  def collection do
    @user_col
  end

  def get_user_by_id(nil, _db), do: nil

  def get_user_by_id(id, db) do
    Mongo.find_one(
      db,
      @user_col,
      %{"_id" => id}
    )
    |> StructSimplifier.decode()
  end

  def get_user_by_username(username, db, opts \\ []) do
    Logger.info("Getting user by username")

    Mongo.find_one(
      db,
      @user_col,
      %{"username" => username},
      opts
    )
    # |> IO.inspect()
    |> case do
      nil -> {:error, :no_such_user}
      user -> {:ok, StructSimplifier.decode(user)}
    end
  end

  def put_user(user, db, opts \\ []) do
    # %{"code" => 11000}
    s_user = StructSimplifier.encode(user)

    case user.id do
      nil ->
        put_user_with_random_id(s_user, db, opts)

      id ->
        Logger.info("Put user with userid #{id}")

        case Mongo.replace_one(db, @user_col, %{"_id" => id}, s_user, opts ++ [upsert: true]) do
          {:ok, %Mongo.UpdateResult{acknowledged: true, matched_count: 1, modified_count: 1}} ->
            {:ok, user.id}

          {:ok, %Mongo.UpdateResult{acknowledged: true, matched_count: 1, upserted_ids: [^id]}} ->
            {:ok, user.id}

          err ->
            {:error, err}
        end
    end
  end

  def put_user_with_random_id(s_user, db, opts \\ []) do
    {id, opts} = Keyword.pop(opts, :fixed_id)
    id = id || Enum.random(1..100_000_000)

    user_with_id = %{s_user | "_id" => id}

    Logger.debug("Put user with random id #{id}")

    case Mongo.insert_one(db, @user_col, user_with_id) do
      {:ok, %Mongo.InsertOneResult{inserted_id: id}} ->
        {:ok, id}

      # 11000 -- dublicate key error
      {:error, %Mongo.WriteError{write_errors: [%{"code" => 11000}]}} ->
        put_user_with_random_id(s_user, db, opts)

      {:error, _} = err ->
        err
    end
  end

  def delete_user(user, db, opts \\ []) do
    Logger.info("Deleting user by id #{user.id}")

    case Mongo.delete_one(db, @user_col, %{"_id" => user.id}, opts) do
      {:ok, %Mongo.DeleteResult{acknowledged: false}} -> {:error, :delete_no_ack}
      other -> other
    end
  end
end
