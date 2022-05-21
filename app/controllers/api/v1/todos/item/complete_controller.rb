# frozen_string_literal: true

module API::V1::Todos
  class Item::CompleteController < BaseController
    def update
      ::Todo::Item::Complete
        .call(id: params[:id], user_id: current_user.id)
        .on_success { render(json: {}, status: :ok) }
        .on_failure(:todo_not_found) { render(json: {}, status: :not_found) }
        .on_unknown { raise NotImplementedError }
    end
  end
end
