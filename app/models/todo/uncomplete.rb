# frozen_string_literal: true

class Todo::Uncomplete < ::Micro::Case
  attribute :id, validates: {numericality: {only_integer: true}}
  attribute :user_id, validates: {numericality: {only_integer: true}}

  def call!
    updated = ::Todo.where(user_id:, id:).update_all(completed_at: nil)

    return Failure(:todo_not_found) if updated.zero?

    Success(:todo_uncompleted)
  end
end
