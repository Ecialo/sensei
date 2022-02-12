defmodule Sensei.Storage.Courses do
  require Logger
  @courses_col "courses"

  def get_course(course_id, db) when is_binary(course_id) do
    course_id = BSON.ObjectId.decode!(course_id)

    Mongo.find_one(
      db,
      @courses_col,
      %{"_id" => course_id}
    )
    |> StructSimplifier.decode()
  end

  def get_all_courses_such(filters, db) do
    case Mongo.find(db, @courses_col, filters) do
      {:error, _} = err ->
        err

      cursor ->
        {:ok, Enum.map(cursor, &StructSimplifier.decode/1)}
    end
  end

  def put_course(course, db) do
    s_course = StructSimplifier.encode(course)

    case s_course["_id"] do
      nil -> Mongo.insert_one(db, @courses_col, s_course)
      id -> Mongo.replace_one(db, @courses_col, %{"_id" => id}, s_course)
    end
    |> case do
      {:ok, %Mongo.InsertOneResult{inserted_id: id}} when not is_nil(id) ->
        {:ok, BSON.ObjectId.encode!(id)}

      {:ok, %Mongo.UpdateResult{acknowledged: true, matched_count: 1, modified_count: 1}} ->
        {:ok, course.id}

      err ->
        {:error, err}
    end
  end

  def refine_courses(user, db, opts \\ []) do
    Logger.info("Refine courses #{user.role}")

    if user.role in [:sensei, :admin] do
      Mongo.update_many(
        db,
        @courses_col,
        %{"sensei.3" => user.username},
        %{
          "$set": %{"sensei.4" => user.id}
        },
        opts
      )
    else
      {:ok, nil}
    end
  end

  def clean_course_confirmations(course_id, db) do
  end

  def pause_course() do
  end

  def unpause_course() do
  end

  def collection do
    @courses_col
  end
end
