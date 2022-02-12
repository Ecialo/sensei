defmodule SenseiTest.Storage do
  use SenseiTest.MongoCase

  require OK

  alias Sensei.Course
  alias Sensei.Storage.Courses

  describe "course" do
    test "put-get" do
      c = Course.new(name: "Azaza")

      {:ok, course_id} = Courses.put_course(c)
      # IO.inspect(course_id)
      # IO.inspect(course_id |> BSON.ObjectId.encode!() |> BSON.ObjectId.decode!())

      {:ok, stored_course} = Courses.get_course(course_id)
      anoned_stored_course = %{stored_course | id: nil}

      assert anoned_stored_course == c

      updated_stored_course = %{stored_course | name: "Kekeke"}

      {:ok, new_stored_course} =
        OK.for do
          new_course_id <- Courses.put_course(updated_stored_course)
          new_stored_course <- Courses.get_course(new_course_id)
        after
          new_stored_course
        end

      assert new_stored_course.id == course_id
      assert new_stored_course.name == "Kekeke"
    end
  end
end
